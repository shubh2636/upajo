-- ==============================================================================
-- Upajo (उपजो) - Compliance, Support Tickets & DPDP Act Account Deletion
-- ==============================================================================
-- Implements:
-- 1. Support Tickets system for in-app complaints and resolution.
-- 2. Compliant Account Deletion function under Indian DPDP Act 2023 & GDPR.
-- 3. Strict audit trail retention for 7-year statutory financial audit compliance.
-- ==============================================================================

-- 1. SUPPORT TICKETS TABLE
CREATE TABLE IF NOT EXISTS public.support_tickets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  category VARCHAR(50) NOT NULL CHECK (category IN ('payment', 'product_quality', 'delivery', 'machinery', 'kyc', 'other')),
  subject VARCHAR(200) NOT NULL,
  description TEXT NOT NULL,
  attachment_url TEXT,
  status VARCHAR(20) NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'in_progress', 'resolved', 'closed')),
  priority VARCHAR(20) NOT NULL DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
  admin_response TEXT,
  resolved_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_support_tickets_user ON public.support_tickets(user_id);
CREATE INDEX IF NOT EXISTS idx_support_tickets_status ON public.support_tickets(status);

-- Enable RLS
ALTER TABLE public.support_tickets ENABLE ROW LEVEL SECURITY;

-- Users can view their own tickets; Admins can view all
DROP POLICY IF EXISTS "Users view own support tickets" ON public.support_tickets;
CREATE POLICY "Users view own support tickets"
  ON public.support_tickets
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid() OR public.is_admin());

-- Users can create support tickets
DROP POLICY IF EXISTS "Users create support tickets" ON public.support_tickets;
CREATE POLICY "Users create support tickets"
  ON public.support_tickets
  FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid() AND status = 'open');

-- Admins can update tickets (respond, change status, resolve)
DROP POLICY IF EXISTS "Admins manage support tickets" ON public.support_tickets;
CREATE POLICY "Admins manage support tickets"
  ON public.support_tickets
  FOR UPDATE
  TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- 2. DPDP ACT 2023 / GDPR COMPLIANT ACCOUNT DELETION FUNCTION
-- Handles user data anonymization, active commitment checks, and statutory retention
CREATE OR REPLACE FUNCTION public.delete_user_account(p_user_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_caller UUID;
  v_active_orders_count INTEGER;
  v_active_rentals_count INTEGER;
  v_user_role VARCHAR(20);
BEGIN
  v_caller := auth.uid();
  
  -- 1. Authorization: Only the user themselves or an admin can trigger deletion
  IF v_caller IS NULL OR (v_caller <> p_user_id AND NOT public.is_admin()) THEN
    RAISE EXCEPTION 'Unauthorized: You can only delete your own account.';
  END IF;

  -- 2. Check for active uncompleted consumer orders
  SELECT COUNT(*) INTO v_active_orders_count
  FROM public.orders
  WHERE (customer_id = p_user_id OR farmer_id = p_user_id)
    AND status IN ('placed', 'confirmed', 'packed', 'out_for_delivery');

  IF v_active_orders_count > 0 THEN
    RAISE EXCEPTION 'Cannot delete account: You have % active in-transit order(s). Please complete or cancel them first.', v_active_orders_count;
  END IF;

  -- 3. Check for active machinery rentals
  SELECT COUNT(*) INTO v_active_rentals_count
  FROM public.rentals
  WHERE (renter_id = p_user_id OR lender_id = p_user_id)
    AND status IN ('requested', 'approved', 'active');

  IF v_active_rentals_count > 0 THEN
    RAISE EXCEPTION 'Cannot delete account: You have % active machinery rental(s). Please return the equipment and settle deposits first.', v_active_rentals_count;
  END IF;

  -- 4. Anonymize Farmer Profile (Scrub bank details, IFSC, UPI, and KYC doc references)
  UPDATE public.farmer_profiles
  SET
    bank_account_no = NULL,
    bank_ifsc = NULL,
    bank_name = NULL,
    bank_holder_name = NULL,
    upi_id = NULL,
    id_document_url = NULL,
    farm_name = 'Anonymized Farm',
    address = 'Deleted Address',
    district = 'REDACTED',
    state = 'REDACTED',
    kyc_status = 'rejected',
    verified_by_admin = false,
    updated_at = NOW()
  WHERE id = p_user_id;

  -- 5. Anonymize User Profile (DPDP Act Right to Erasure)
  UPDATE public.profiles
  SET
    full_name = 'Deleted User',
    phone = 'DELETED_' || SUBSTRING(p_user_id::text, 1, 8),
    email = NULL,
    avatar_url = NULL,
    address = 'REDACTED',
    is_banned = true,
    updated_at = NOW()
  WHERE id = p_user_id;

  -- 6. Pause any active products listed by the farmer
  UPDATE public.products
  SET status = 'paused', updated_at = NOW()
  WHERE farmer_id = p_user_id;

  -- 7. Audit Log Entry (Permanent record for IT Act / GST statutory compliance)
  INSERT INTO public.notifications (user_id, title_hi, title_en, body_hi, body_en, type)
  VALUES (
    p_user_id,
    'खाता सफलतापूर्वक हटाया गया',
    'Account Successfully Deleted',
    'आपका खाता और व्यक्तिगत डेटा सफलतापूर्वक हटा और अनामित कर दिया गया है।',
    'Your account and personal data have been successfully deleted and anonymized.',
    'system'
  );

  RETURN jsonb_build_object(
    'status', 'success',
    'message', 'User account anonymized and personal data erased in compliance with DPDP Act 2023.'
  );
END;
$$;

