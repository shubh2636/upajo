-- ==============================================================================
-- Upajo (उपजो) - Instant Auto-Confirm for Mobile + Password Auth
-- ==============================================================================
-- Run this ONCE in Supabase SQL Editor (https://supabase.com/dashboard/project/sskbabrsrbgjemsofiam/sql/new)
-- This automatically marks any new user (Mobile / Email Proxy) as confirmed immediately upon registration.
-- Eliminates ALL needs for SMS OTP, Twilio, DLT, or email verification links!
-- ==============================================================================

CREATE OR REPLACE FUNCTION public.auto_confirm_new_users()
RETURNS TRIGGER AS $$
BEGIN
  NEW.email_confirmed_at = COALESCE(NEW.email_confirmed_at, NOW());
  NEW.phone_confirmed_at = COALESCE(NEW.phone_confirmed_at, NOW());
  NEW.confirmed_at = COALESCE(NEW.confirmed_at, NOW());
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recreate trigger on auth.users table
DROP TRIGGER IF EXISTS tr_auto_confirm_users ON auth.users;
CREATE TRIGGER tr_auto_confirm_users
  BEFORE INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.auto_confirm_new_users();

-- Auto-confirm any existing unconfirmed test accounts
UPDATE auth.users
SET email_confirmed_at = NOW(),
    phone_confirmed_at = NOW(),
    confirmed_at = NOW()
WHERE confirmed_at IS NULL;
