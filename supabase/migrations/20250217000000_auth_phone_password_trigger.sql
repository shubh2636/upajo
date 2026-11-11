-- ==============================================================================
-- Upajo (उपजो) - Migration: Auth Trigger for Phone+Password & Strict Role Guard
-- ==============================================================================
-- Migration Version: 20250217000000
-- Description:
--   1. Automatically creates profile row upon auth.users insertion.
--   2. Strict security: forces role to 'farmer' or 'consumer' only (NEVER 'admin').
--   3. Auto-confirms new users so no email/SMS verification link is required.
-- ==============================================================================

-- 1. Auto-Confirm Trigger: Instantly marks new users as confirmed
CREATE OR REPLACE FUNCTION public.auto_confirm_new_users()
RETURNS TRIGGER AS $$
BEGIN
  NEW.email_confirmed_at = COALESCE(NEW.email_confirmed_at, NOW());
  NEW.phone_confirmed_at = COALESCE(NEW.phone_confirmed_at, NOW());
  NEW.confirmed_at = COALESCE(NEW.confirmed_at, NOW());
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;

DROP TRIGGER IF EXISTS trg_auto_confirm_users ON auth.users;
CREATE TRIGGER trg_auto_confirm_users
  BEFORE INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.auto_confirm_new_users();

-- 2. Profile Creation Trigger: Creates profiles safely from raw_user_meta_data
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  v_role public.user_role;
  v_phone text;
  v_full_name text;
BEGIN
  -- Strict Privilege Guard: User metadata can only assign 'farmer' or 'consumer'
  -- Attempts to self-assign 'admin' are strictly demoted to 'consumer'
  IF LOWER(COALESCE(NEW.raw_user_meta_data->>'role', '')) = 'farmer' THEN
    v_role := 'farmer'::public.user_role;
  ELSE
    v_role := 'consumer'::public.user_role;
  END IF;

  -- Extract clean 10-digit phone number
  v_phone := COALESCE(
    NEW.raw_user_meta_data->>'phone',
    NEW.phone,
    SUBSTRING(NEW.email FROM '^[0-9]{10}')
  );
  v_phone := REGEXP_REPLACE(COALESCE(v_phone, ''), '[^0-9]', '', 'g');
  IF LENGTH(v_phone) > 10 THEN
    v_phone := RIGHT(v_phone, 10);
  END IF;
  IF v_phone = '' THEN
    -- Fallback unique phone if user signed up with custom email only
    v_phone := '9' || LPAD(FLOOR(RANDOM() * 1000000000)::text, 9, '0');
  END IF;

  v_full_name := COALESCE(NULLIF(TRIM(NEW.raw_user_meta_data->>'full_name'), ''), 'Kisan Upajo');

  -- Upsert profile row safely
  INSERT INTO public.profiles (
    id,
    phone,
    full_name,
    role,
    preferred_language,
    kyc_status,
    verified_by_admin,
    created_at,
    updated_at
  ) VALUES (
    NEW.id,
    v_phone,
    v_full_name,
    v_role,
    'hi',
    CASE WHEN v_role = 'farmer' THEN 'pending'::public.kyc_status ELSE 'verified'::public.kyc_status END,
    CASE WHEN v_role = 'farmer' THEN FALSE ELSE TRUE END,
    NOW(),
    NOW()
  )
  ON CONFLICT (id) DO UPDATE SET
    phone = EXCLUDED.phone,
    full_name = EXCLUDED.full_name,
    role = EXCLUDED.role,
    updated_at = NOW();

  -- If farmer, ensure farmer_profiles row exists
  IF v_role = 'farmer' THEN
    INSERT INTO public.farmer_profiles (
      farmer_id,
      farm_name,
      total_acres,
      created_at,
      updated_at
    ) VALUES (
      NEW.id,
      v_full_name || ' Farm',
      0.00,
      NOW(),
      NOW()
    )
    ON CONFLICT (farmer_id) DO NOTHING;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- 3. Confirm any existing unconfirmed test accounts
UPDATE auth.users
SET email_confirmed_at = COALESCE(email_confirmed_at, NOW()),
    phone_confirmed_at = COALESCE(phone_confirmed_at, NOW()),
    confirmed_at = COALESCE(confirmed_at, NOW())
WHERE confirmed_at IS NULL;

