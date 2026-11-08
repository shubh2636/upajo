-- ==============================================================================
-- Upajo (उपजो) - Crop Recommendation & Farmer Feedback Loop Schema
-- ==============================================================================
-- Supports continuous self-learning ML pipeline, ground-truth yield collection,
-- and strict RLS protection against self-verifying feedback.
-- ==============================================================================

-- 1. RECOMMENDATIONS TABLE
CREATE TABLE IF NOT EXISTS public.recommendations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  farmer_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  district VARCHAR(100) NOT NULL,
  soil_params JSONB NOT NULL DEFAULT '{}'::jsonb,
  weather_context JSONB NOT NULL DEFAULT '{}'::jsonb,
  model_version VARCHAR(50) NOT NULL DEFAULT 'v1.0.0-xgb',
  recommended_crops JSONB NOT NULL DEFAULT '[]'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. FARMER FEEDBACK TABLE
CREATE TABLE IF NOT EXISTS public.farmer_feedback (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  recommendation_id UUID REFERENCES public.recommendations(id) ON DELETE CASCADE,
  farmer_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  crop_chosen VARCHAR(100) NOT NULL,
  actual_sowing_date DATE,
  actual_yield_q_acre NUMERIC(6, 2) CHECK (actual_yield_q_acre >= 0),
  actual_price_realized NUMERIC(10, 2) CHECK (actual_price_realized >= 0),
  net_profit_acre NUMERIC(10, 2),
  rating_1_to_5 INTEGER CHECK (rating_1_to_5 BETWEEN 1 AND 5),
  notes TEXT,
  verified_by_kisan_mitra BOOLEAN NOT NULL DEFAULT false,
  is_synthetic BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for performance & retraining queries
CREATE INDEX IF NOT EXISTS idx_recommendations_farmer ON public.recommendations(farmer_id);
CREATE INDEX IF NOT EXISTS idx_recommendations_district ON public.recommendations(district);
CREATE INDEX IF NOT EXISTS idx_feedback_recommendation ON public.farmer_feedback(recommendation_id);
CREATE INDEX IF NOT EXISTS idx_feedback_verified ON public.farmer_feedback(verified_by_kisan_mitra) WHERE verified_by_kisan_mitra = true;
CREATE INDEX IF NOT EXISTS idx_feedback_synthetic ON public.farmer_feedback(is_synthetic) WHERE is_synthetic = false;

-- Enable Row Level Security (RLS)
ALTER TABLE public.recommendations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.farmer_feedback ENABLE ROW LEVEL SECURITY;

-- ------------------------------------------------------------------------------
-- RLS POLICIES FOR RECOMMENDATIONS
-- ------------------------------------------------------------------------------
DROP POLICY IF EXISTS "Farmers view own recommendations" ON public.recommendations;
CREATE POLICY "Farmers view own recommendations"
  ON public.recommendations
  FOR SELECT
  TO authenticated
  USING (farmer_id = auth.uid() OR public.is_admin());

DROP POLICY IF EXISTS "Insert recommendations" ON public.recommendations;
CREATE POLICY "Insert recommendations"
  ON public.recommendations
  FOR INSERT
  TO authenticated
  WITH CHECK (farmer_id = auth.uid() OR public.is_admin());

DROP POLICY IF EXISTS "Admins manage recommendations" ON public.recommendations;
CREATE POLICY "Admins manage recommendations"
  ON public.recommendations
  FOR ALL
  TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- ------------------------------------------------------------------------------
-- RLS POLICIES FOR FARMER FEEDBACK
-- ------------------------------------------------------------------------------
DROP POLICY IF EXISTS "Farmers view own feedback" ON public.farmer_feedback;
CREATE POLICY "Farmers view own feedback"
  ON public.farmer_feedback
  FOR SELECT
  TO authenticated
  USING (farmer_id = auth.uid() OR public.is_admin());

-- Farmers can submit feedback, but CANNOT self-verify or tamper with verified_by_kisan_mitra
DROP POLICY IF EXISTS "Farmers submit feedback" ON public.farmer_feedback;
CREATE POLICY "Farmers submit feedback"
  ON public.farmer_feedback
  FOR INSERT
  TO authenticated
  WITH CHECK (
    (farmer_id = auth.uid() AND verified_by_kisan_mitra = false)
    OR public.is_admin()
  );

DROP POLICY IF EXISTS "Farmers update own unverified notes" ON public.farmer_feedback;
CREATE POLICY "Farmers update own unverified notes"
  ON public.farmer_feedback
  FOR UPDATE
  TO authenticated
  USING (farmer_id = auth.uid() OR public.is_admin())
  WITH CHECK (
    (farmer_id = auth.uid() AND verified_by_kisan_mitra = false)
    OR public.is_admin()
  );

DROP POLICY IF EXISTS "Admins delete feedback" ON public.farmer_feedback;
CREATE POLICY "Admins delete feedback"
  ON public.farmer_feedback
  FOR DELETE
  TO authenticated
  USING (public.is_admin());

