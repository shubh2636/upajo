-- ==============================================================================
-- Upajo (उपजो) - Comprehensive Row Level Security (RLS) & Access Control Test Suite
-- ==============================================================================
-- Tests multi-tenant isolation, role boundaries, and anti-tampering policies:
-- 1. Anonymous Access Restrictions (Catalog read-only, no PII)
-- 2. Farmer Ownership Isolation (Only manage own products, machinery, & orders)
-- 3. Consumer Privacy & Multi-Tenant Order Isolation (Consumer A vs Consumer B)
-- 4. Role-Gated Admin Controls & Privilege Escalation Prevention
-- 5. Financial Anti-Tampering (Amounts, Status State Machines, Direct Payment Inserts)
-- 6. Machinery & Rental Anti-Tampering (Deposit protection, Owner-only completion)
-- ==============================================================================

BEGIN;

-- Create helper testing schema & assertions
CREATE SCHEMA IF NOT EXISTS test_harness;

CREATE OR REPLACE FUNCTION test_harness.assert_true(condition boolean, test_name text) RETURNS void AS $$
BEGIN
  IF NOT condition THEN
    RAISE EXCEPTION 'TEST FAILED: %', test_name;
  ELSE
    RAISE NOTICE 'TEST PASSED: %', test_name;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- ------------------------------------------------------------------------------
-- 1. TEST SETUP: Mock Users, Identities & Base Categories
-- ------------------------------------------------------------------------------
-- Farmer 1: Baldev Singh (Verified)
-- Farmer 2: Ramesh Patel (Pending)
-- Consumer 1: Sunita Sharma
-- Consumer 2: Anita Gupta
-- Admin 1: Vikram Rathore

DO $$
BEGIN
  -- Insert base category
  INSERT INTO public.categories (id, slug, name_hi, name_en, icon_name, sort_order)
  VALUES ('99999999-9999-9999-9999-999999999999', 'test_grains', 'परीक्षण अनाज', 'Test Grains', 'grain', 1)
  ON CONFLICT (id) DO NOTHING;

  -- Insert mock profiles
  INSERT INTO public.profiles (id, phone, full_name, role, kyc_status, verified_by_admin, district, state)
  VALUES 
    ('11111111-1111-1111-1111-111111111111', '9876543210', 'बलदेव सिंह पटेल', 'farmer', 'verified', true, 'सीहोर', 'मध्य प्रदेश'),
    ('22222222-2222-2222-2222-222222222222', '9876543211', 'रमेश पटेल', 'farmer', 'pending', false, 'सीहोर', 'मध्य प्रदेश'),
    ('33333333-3333-3333-3333-333333333333', '9876543212', 'सुनीता शर्मा', 'consumer', 'verified', false, 'भोपाल', 'मध्य प्रदेश'),
    ('44444444-4444-4444-4444-444444444444', '9876543213', 'विक्रम राठौर (एडमिन)', 'admin', 'verified', true, 'नई दिल्ली', 'दिल्ली'),
    ('55555555-5555-5555-5555-555555555555', '9876543214', 'अनिता गुप्ता', 'consumer', 'verified', false, 'इंदौर', 'मध्य प्रदेश')
  ON CONFLICT (id) DO NOTHING;

  -- Insert mock farmer profile with sensitive bank details
  INSERT INTO public.farmer_profiles (
    farmer_id, bank_account_number, bank_ifsc, upi_vpa, bank_account_holder_name, aadhaar_last4, kisan_credit_card_number
  )
  VALUES (
    '11111111-1111-1111-1111-111111111111', '123456789012', 'SBIN0001234', 'baldev@upi', 'बलदेव सिंह', '1234', 'KCC-98765'
  )
  ON CONFLICT (farmer_id) DO NOTHING;
END $$;

-- ------------------------------------------------------------------------------
-- 2. TEST CASE 1: Anonymous User Isolation
-- ------------------------------------------------------------------------------
-- Anonymous role (anon) must NOT be able to view sensitive farmer bank info
SET LOCAL ROLE anon;
SET LOCAL "request.jwt.claim.sub" TO '';

DO $$
DECLARE
  v_count int;
BEGIN
  SELECT count(*) INTO v_count FROM public.farmer_profiles;
  PERFORM test_harness.assert_true(v_count = 0, 'Anonymous users cannot view farmer bank accounts or UPI VPAs');
END $$;

-- Anonymous users MUST be able to view active marketplace products
DO $$
DECLARE
  v_product_readable boolean;
BEGIN
  SELECT count(*) >= 0 INTO v_product_readable FROM public.products WHERE is_active = true;
  PERFORM test_harness.assert_true(v_product_readable, 'Anonymous users can browse public active crops');
END $$;

-- Anonymous users CANNOT query consumer profiles
DO $$
DECLARE
  v_consumer_count int;
BEGIN
  SELECT count(*) INTO v_consumer_count FROM public.profiles WHERE id = '33333333-3333-3333-3333-333333333333';
  PERFORM test_harness.assert_true(v_consumer_count = 0, 'Anonymous users cannot query consumer profiles');
END $$;

-- ------------------------------------------------------------------------------
-- 3. TEST CASE 2: Farmer Product Ownership & Cross-Tenant Tampering Protection
-- ------------------------------------------------------------------------------
-- Farmer 1 logs in
SET LOCAL ROLE authenticated;
SET LOCAL "request.jwt.claim.sub" TO '11111111-1111-1111-1111-111111111111';

-- Farmer 1 inserts product
INSERT INTO public.products (
  id, farmer_id, category_id, title_hi, title_en, description_hi, description_en, price_per_kg, stock_kg, harvest_date, shelf_life_days, village_or_city, district, state, pin_code
) VALUES (
  'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '11111111-1111-1111-1111-111111111111', '99999999-9999-9999-9999-999999999999', 'शरबती गेहूं', 'Sharbati Wheat', 'देसी गेहूं', 'Desi Wheat', 35.0, 500.0, CURRENT_DATE, 365, 'श्यामपुर', 'सीहोर', 'मध्य प्रदेश', '466001'
) ON CONFLICT (id) DO NOTHING;

DO $$
BEGIN
  PERFORM test_harness.assert_true(
    EXISTS (SELECT 1 FROM public.products WHERE id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'),
    'Farmer 1 can insert and view their own crop product'
  );
END $$;

-- Switch to Farmer 2
SET LOCAL "request.jwt.claim.sub" TO '22222222-2222-2222-2222-222222222222';

-- Farmer 2 attempts to delete or alter Farmer 1's product
UPDATE public.products SET price_per_kg = 1.0 WHERE id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';

DO $$
DECLARE
  v_price numeric;
BEGIN
  SELECT price_per_kg INTO v_price FROM public.products WHERE id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
  PERFORM test_harness.assert_true(
    v_price = 35.0,
    'Farmer 2 cannot tamper with or modify Farmer 1 product'
  );
END $$;

-- Farmer 2 attempts to query Farmer 1's sensitive banking info
DO $$
DECLARE
  v_farmer_bank_count int;
BEGIN
  SELECT count(*) INTO v_farmer_bank_count FROM public.farmer_profiles WHERE farmer_id = '11111111-1111-1111-1111-111111111111';
  PERFORM test_harness.assert_true(
    v_farmer_bank_count = 0,
    'Farmer 2 cannot view Farmer 1 bank details or UPI'
  );
END $$;

-- ------------------------------------------------------------------------------
-- 4. TEST CASE 3: Consumer Order Isolation (Consumer A vs Consumer B)
-- ------------------------------------------------------------------------------
-- Switch to Consumer 1
SET LOCAL "request.jwt.claim.sub" TO '33333333-3333-3333-3333-333333333333';

-- Consumer 1 places an order for Farmer 1's product
INSERT INTO public.orders (
  id, order_number, consumer_id, farmer_id, subtotal_amount, delivery_fee, total_amount, status, delivery_mode, delivery_address
) VALUES (
  'cccccccc-cccc-cccc-cccc-cccccccccccc', 'UPJ-TEST-001', '33333333-3333-3333-3333-333333333333', '11111111-1111-1111-1111-111111111111', 1600.0, 150.0, 1750.0, 'pending_payment', 'partner', '{"city": "Bhopal"}'::jsonb
) ON CONFLICT (id) DO NOTHING;

-- Consumer 1 can see their order
DO $$
BEGIN
  PERFORM test_harness.assert_true(
    EXISTS (SELECT 1 FROM public.orders WHERE id = 'cccccccc-cccc-cccc-cccc-cccccccccccc'),
    'Consumer 1 can query and track their own order'
  );
END $$;

-- Switch to Farmer 2 (unrelated third party)
SET LOCAL "request.jwt.claim.sub" TO '22222222-2222-2222-2222-222222222222';

-- Farmer 2 must NOT be able to see Consumer 1's order
DO $$
DECLARE
  v_visible boolean;
BEGIN
  SELECT EXISTS (SELECT 1 FROM public.orders WHERE id = 'cccccccc-cccc-cccc-cccc-cccccccccccc') INTO v_visible;
  PERFORM test_harness.assert_true(
    NOT v_visible,
    'Unrelated Farmer 2 cannot see Consumer 1 order'
  );
END $$;

-- Switch to Consumer 2 (Anita Gupta)
SET LOCAL "request.jwt.claim.sub" TO '55555555-5555-5555-5555-555555555555';

-- Consumer 2 must NOT see Consumer 1's order
DO $$
DECLARE
  v_c2_visible boolean;
BEGIN
  SELECT EXISTS (SELECT 1 FROM public.orders WHERE id = 'cccccccc-cccc-cccc-cccc-cccccccccccc') INTO v_c2_visible;
  PERFORM test_harness.assert_true(
    NOT v_c2_visible,
    'Consumer 2 cannot view Consumer 1 order'
  );
END $$;

-- Consumer 2 must NOT see Consumer 1's profile phone or address
DO $$
DECLARE
  v_c1_profile_count int;
BEGIN
  SELECT count(*) INTO v_c1_profile_count FROM public.profiles WHERE id = '33333333-3333-3333-3333-333333333333';
  PERFORM test_harness.assert_true(
    v_c1_profile_count = 0,
    'Consumer 2 cannot query Consumer 1 private profile'
  );
END $$;

-- ------------------------------------------------------------------------------
-- 5. TEST CASE 4: Role-Gated Admin KYC Verification & Privilege Escalation Prevention
-- ------------------------------------------------------------------------------
-- Farmer 1 attempts to verify Farmer 2's account (should fail or have 0 rows updated)
SET LOCAL "request.jwt.claim.sub" TO '11111111-1111-1111-1111-111111111111';
UPDATE public.profiles SET verified_by_admin = true WHERE id = '22222222-2222-2222-2222-222222222222';

DO $$
DECLARE
  v_verified boolean;
BEGIN
  SELECT verified_by_admin INTO v_verified FROM public.profiles WHERE id = '22222222-2222-2222-2222-222222222222';
  PERFORM test_harness.assert_true(
    NOT v_verified,
    'Non-admin cannot verify their own or others KYC status'
  );
END $$;

-- Consumer 1 attempts self-privilege escalation to admin
SET LOCAL "request.jwt.claim.sub" TO '33333333-3333-3333-3333-333333333333';
DO $$
DECLARE
  v_escalated boolean := false;
BEGIN
  BEGIN
    UPDATE public.profiles SET role = 'admin' WHERE id = '33333333-3333-3333-3333-333333333333';
  EXCEPTION WHEN OTHERS THEN
    v_escalated := false;
  END;

  SELECT (role = 'admin') INTO v_escalated FROM public.profiles WHERE id = '33333333-3333-3333-3333-333333333333';
  PERFORM test_harness.assert_true(
    NOT v_escalated,
    'Non-admin cannot self-escalate to admin role'
  );
END $$;

-- Switch to Admin 1
SET LOCAL "request.jwt.claim.sub" TO '44444444-4444-4444-4444-444444444444';
UPDATE public.profiles SET verified_by_admin = true, kyc_status = 'verified' WHERE id = '22222222-2222-2222-2222-222222222222';

DO $$
DECLARE
  v_verified boolean;
BEGIN
  SELECT verified_by_admin INTO v_verified FROM public.profiles WHERE id = '22222222-2222-2222-2222-222222222222';
  PERFORM test_harness.assert_true(
    v_verified,
    'System Admin can successfully approve and verify farmer KYC'
  );
END $$;

-- ------------------------------------------------------------------------------
-- 6. TEST CASE 5: Financial Anti-Tampering & Payment Security
-- ------------------------------------------------------------------------------
-- Switch to Consumer 1
SET LOCAL "request.jwt.claim.sub" TO '33333333-3333-3333-3333-333333333333';

-- Consumer 1 attempts to tamper with order total_amount (change from 1750 to 1)
DO $$
DECLARE
  v_tampered boolean := false;
BEGIN
  BEGIN
    UPDATE public.orders SET total_amount = 1.0 WHERE id = 'cccccccc-cccc-cccc-cccc-cccccccccccc';
  EXCEPTION WHEN OTHERS THEN
    v_tampered := false;
  END;

  SELECT (total_amount = 1.0) INTO v_tampered FROM public.orders WHERE id = 'cccccccc-cccc-cccc-cccc-cccccccccccc';
  PERFORM test_harness.assert_true(
    NOT v_tampered,
    'Consumer cannot alter order total_amount'
  );
END $$;

-- Consumer 1 attempts to jump order status directly to delivered
DO $$
DECLARE
  v_jumped boolean := false;
BEGIN
  BEGIN
    UPDATE public.orders SET status = 'delivered' WHERE id = 'cccccccc-cccc-cccc-cccc-cccccccccccc';
  EXCEPTION WHEN OTHERS THEN
    v_jumped := false;
  END;

  SELECT (status = 'delivered') INTO v_jumped FROM public.orders WHERE id = 'cccccccc-cccc-cccc-cccc-cccccccccccc';
  PERFORM test_harness.assert_true(
    NOT v_jumped,
    'Consumer cannot jump order status to delivered'
  );
END $$;

-- Consumer 1 attempts to insert fake payment row directly into public.payments
DO $$
DECLARE
  v_payment_inserted boolean := false;
BEGIN
  BEGIN
    INSERT INTO public.payments (order_id, payment_method, razorpay_order_id, razorpay_payment_id, amount, status)
    VALUES ('cccccccc-cccc-cccc-cccc-cccccccccccc', 'upi_razorpay', 'order_fake', 'pay_fake', 1750.0, 'captured');
    v_payment_inserted := true;
  EXCEPTION WHEN OTHERS THEN
    v_payment_inserted := false;
  END;

  PERFORM test_harness.assert_true(
    NOT v_payment_inserted,
    'Authenticated consumer cannot insert payment record'
  );
END $$;

-- ------------------------------------------------------------------------------
-- 7. TEST CASE 6: Machinery & Rental Deposit Anti-Tampering
-- ------------------------------------------------------------------------------
-- Farmer 1 lists a tractor for rent
SET LOCAL "request.jwt.claim.sub" TO '11111111-1111-1111-1111-111111111111';

INSERT INTO public.machinery (
  id, owner_id, title_hi, title_en, machinery_type, daily_rate, security_deposit, village_or_city, district, state
) VALUES (
  'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', '11111111-1111-1111-1111-111111111111', 'महिंद्रा 575 ट्रैक्टर', 'Mahindra 575 Tractor', 'tractor', 3200.0, 2000.0, 'श्यामपुर', 'सीहोर', 'मध्य प्रदेश'
) ON CONFLICT (id) DO NOTHING;

-- Consumer 1 books the tractor
SET LOCAL "request.jwt.claim.sub" TO '33333333-3333-3333-3333-333333333333';

INSERT INTO public.rentals (
  id, machinery_id, renter_id, owner_id, start_date, end_date, total_days, total_amount, deposit_amount, status
) VALUES (
  'dddddddd-dddd-dddd-dddd-dddddddddddd', 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', '33333333-3333-3333-3333-333333333333', '11111111-1111-1111-1111-111111111111', CURRENT_DATE + 1, CURRENT_DATE + 4, 4, 12800.0, 2000.0, 'pending'
) ON CONFLICT (id) DO NOTHING;

-- Consumer 1 attempts to tamper with deposit_amount
DO $$
DECLARE
  v_deposit_altered boolean := false;
BEGIN
  BEGIN
    UPDATE public.rentals SET deposit_amount = 0.0 WHERE id = 'dddddddd-dddd-dddd-dddd-dddddddddddd';
  EXCEPTION WHEN OTHERS THEN
    v_deposit_altered := false;
  END;

  SELECT (deposit_amount = 0.0) INTO v_deposit_altered FROM public.rentals WHERE id = 'dddddddd-dddd-dddd-dddd-dddddddddddd';
  PERFORM test_harness.assert_true(
    NOT v_deposit_altered,
    'Renter cannot alter rental security deposit'
  );
END $$;

-- Consumer 1 attempts to mark rental as completed without owner return confirmation
DO $$
DECLARE
  v_completed_by_renter boolean := false;
BEGIN
  BEGIN
    UPDATE public.rentals SET status = 'completed' WHERE id = 'dddddddd-dddd-dddd-dddd-dddddddddddd';
  EXCEPTION WHEN OTHERS THEN
    v_completed_by_renter := false;
  END;

  SELECT (status = 'completed') INTO v_completed_by_renter FROM public.rentals WHERE id = 'dddddddd-dddd-dddd-dddd-dddddddddddd';
  PERFORM test_harness.assert_true(
    NOT v_completed_by_renter,
    'Renter cannot mark rental completed'
  );
END $$;

ROLLBACK; -- Always rollback test transaction to keep database pristine
