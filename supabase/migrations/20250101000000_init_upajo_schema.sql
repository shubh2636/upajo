-- ==============================================================================
-- UPAJO (उपजो) - Comprehensive Database Schema & Row Level Security (RLS)
-- Covers ALL Features: Marketplace, Crop Advisor, Disease Detection,
-- Krishi Sahayak Voice AI, Machinery Rental, Store, and Logistics.
-- ==============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ------------------------------------------------------------------------------
-- 1. ENUMS
-- ------------------------------------------------------------------------------
DO $$ BEGIN
  CREATE TYPE user_role AS ENUM ('farmer', 'consumer', 'admin');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
  CREATE TYPE kyc_status AS ENUM ('pending', 'submitted', 'verified', 'rejected');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
  CREATE TYPE delivery_mode AS ENUM ('self_delivery', 'pickup', 'partner');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
  CREATE TYPE order_status AS ENUM (
    'pending_payment',
    'confirmed',
    'harvesting_packed',
    'out_for_delivery',
    'ready_for_pickup',
    'delivered',
    'cancelled'
  );
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
  CREATE TYPE payment_method AS ENUM ('upi_razorpay', 'cod');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
  CREATE TYPE payment_status AS ENUM ('pending', 'captured', 'failed', 'refunded');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
  CREATE TYPE delivery_status AS ENUM ('assigned', 'picked_up', 'in_transit', 'delivered', 'failed');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
  CREATE TYPE crop_season AS ENUM ('kharif', 'rabi', 'zaid', 'perennial');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
  CREATE TYPE rental_status AS ENUM ('pending', 'approved', 'active', 'completed', 'cancelled');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
  CREATE TYPE store_item_type AS ENUM ('seed', 'fertilizer', 'pesticide', 'bio_nutrient', 'farm_tool');
EXCEPTION WHEN duplicate_object THEN null; END $$;

-- ------------------------------------------------------------------------------
-- 2. USERS / PROFILES (Linked to Supabase Auth)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  role user_role NOT NULL DEFAULT 'consumer',
  phone VARCHAR(15) UNIQUE NOT NULL,
  full_name VARCHAR(100) NOT NULL,
  avatar_url TEXT,
  preferred_language VARCHAR(5) NOT NULL DEFAULT 'hi',
  state VARCHAR(100),
  district VARCHAR(100),
  village_or_city VARCHAR(100),
  pin_code VARCHAR(10),
  address_line TEXT,
  location_lat NUMERIC(10, 7),
  location_lng NUMERIC(10, 7),
  kyc_status kyc_status NOT NULL DEFAULT 'pending',
  verified_by_admin BOOLEAN NOT NULL DEFAULT FALSE,
  fcm_token TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ------------------------------------------------------------------------------
-- 3. FARMER EXTENSION PROFILES
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.farmer_profiles (
  farmer_id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
  farm_name VARCHAR(150),
  total_acres NUMERIC(6, 2) DEFAULT 0.00,
  soil_type VARCHAR(50),
  primary_crops TEXT[] DEFAULT '{}',
  upi_vpa VARCHAR(100),
  bank_account_number VARCHAR(30),
  bank_ifsc VARCHAR(15),
  bank_account_holder_name VARCHAR(100),
  aadhaar_last4 VARCHAR(4),
  kisan_credit_card_number VARCHAR(50),
  bio_hi TEXT,
  bio_en TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ------------------------------------------------------------------------------
-- 4. PRODUCT CATEGORIES
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  slug VARCHAR(50) UNIQUE NOT NULL,
  name_hi VARCHAR(100) NOT NULL,
  name_en VARCHAR(100) NOT NULL,
  icon_name VARCHAR(50) NOT NULL,
  sort_order INT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ------------------------------------------------------------------------------
-- 5. PRODUCTS
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  farmer_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
  category_id UUID NOT NULL REFERENCES public.categories(id) ON DELETE RESTRICT,
  title_hi VARCHAR(150) NOT NULL,
  title_en VARCHAR(150) NOT NULL,
  description_hi TEXT NOT NULL,
  description_en TEXT NOT NULL,
  images TEXT[] NOT NULL DEFAULT '{}',
  price_per_kg NUMERIC(10, 2) NOT NULL CHECK (price_per_kg > 0),
  stock_kg NUMERIC(10, 2) NOT NULL CHECK (stock_kg >= 0),
  harvest_date DATE NOT NULL,
  shelf_life_days INT NOT NULL CHECK (shelf_life_days > 0),
  delivery_modes delivery_mode[] NOT NULL DEFAULT '{pickup, self_delivery}',
  is_organic BOOLEAN NOT NULL DEFAULT FALSE,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  village_or_city VARCHAR(100) NOT NULL,
  district VARCHAR(100) NOT NULL,
  state VARCHAR(100) NOT NULL,
  pin_code VARCHAR(10) NOT NULL,
  location_lat NUMERIC(10, 7),
  location_lng NUMERIC(10, 7),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ------------------------------------------------------------------------------
-- 6. PACK OPTIONS (10kg, 20kg, 50kg Bags)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.pack_options (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id UUID NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
  pack_size_kg INT NOT NULL CHECK (pack_size_kg > 0),
  price NUMERIC(10, 2) NOT NULL CHECK (price > 0),
  is_available BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (product_id, pack_size_kg)
);

-- ------------------------------------------------------------------------------
-- 7. ORDERS
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_number VARCHAR(20) UNIQUE NOT NULL,
  consumer_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
  farmer_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
  delivery_mode delivery_mode NOT NULL,
  delivery_address JSONB NOT NULL,
  subtotal_amount NUMERIC(10, 2) NOT NULL CHECK (subtotal_amount >= 0),
  delivery_fee NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
  total_amount NUMERIC(10, 2) NOT NULL CHECK (total_amount >= 0),
  status order_status NOT NULL DEFAULT 'pending_payment',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ------------------------------------------------------------------------------
-- 8. ORDER ITEMS
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.order_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
  product_id UUID NOT NULL REFERENCES public.products(id) ON DELETE RESTRICT,
  pack_size_kg INT NOT NULL CHECK (pack_size_kg > 0),
  quantity INT NOT NULL CHECK (quantity > 0),
  price_per_pack NUMERIC(10, 2) NOT NULL CHECK (price_per_pack > 0),
  total_price NUMERIC(10, 2) NOT NULL CHECK (total_price > 0),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ------------------------------------------------------------------------------
-- 9. PAYMENTS
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
  payment_method payment_method NOT NULL,
  razorpay_order_id VARCHAR(100),
  razorpay_payment_id VARCHAR(100),
  razorpay_signature VARCHAR(255),
  amount NUMERIC(10, 2) NOT NULL,
  status payment_status NOT NULL DEFAULT 'pending',
  raw_payload JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ------------------------------------------------------------------------------
-- 10. RATINGS & REVIEWS
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.ratings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID UNIQUE NOT NULL REFERENCES public.orders(id) ON DELETE RESTRICT,
  product_id UUID NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
  consumer_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
  farmer_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
  rating INT NOT NULL CHECK (rating >= 1 AND rating <= 5),
  comment TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ------------------------------------------------------------------------------
-- 11. DELIVERY & LIVE LOGISTICS
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.delivery (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID UNIQUE NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
  delivery_partner VARCHAR(100) DEFAULT 'self',
  tracking_number VARCHAR(100),
  driver_name VARCHAR(100),
  driver_phone VARCHAR(15),
  status delivery_status NOT NULL DEFAULT 'assigned',
  live_lat NUMERIC(10, 7),
  live_lng NUMERIC(10, 7),
  estimated_delivery_at TIMESTAMPTZ,
  actual_delivery_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ------------------------------------------------------------------------------
-- 12. CROPS (Master Database)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.crops (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name_hi VARCHAR(100) NOT NULL,
  name_en VARCHAR(100) NOT NULL,
  scientific_name VARCHAR(150),
  season crop_season NOT NULL,
  soil_types TEXT[] NOT NULL DEFAULT '{}',
  water_requirement VARCHAR(50) NOT NULL,
  duration_days INT NOT NULL,
  avg_yield_per_acre NUMERIC(8, 2) NOT NULL,
  ideal_temperature_min NUMERIC(5, 2),
  ideal_temperature_max NUMERIC(5, 2),
  image_url TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ------------------------------------------------------------------------------
-- 13. CROP PLANS (Farmer Advisory)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.crop_plans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  farmer_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  crop_id UUID NOT NULL REFERENCES public.crops(id) ON DELETE RESTRICT,
  land_area_acres NUMERIC(6, 2) NOT NULL,
  soil_type VARCHAR(50) NOT NULL,
  water_source VARCHAR(50) NOT NULL,
  sowing_date DATE NOT NULL,
  expected_harvest_date DATE NOT NULL,
  expected_yield_quintal NUMERIC(8, 2),
  status VARCHAR(30) NOT NULL DEFAULT 'active',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ------------------------------------------------------------------------------
-- 14. TASKS (Crop Calendar Schedule)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.tasks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  crop_plan_id UUID NOT NULL REFERENCES public.crop_plans(id) ON DELETE CASCADE,
  farmer_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  title_hi VARCHAR(200) NOT NULL,
  title_en VARCHAR(200) NOT NULL,
  description_hi TEXT NOT NULL,
  description_en TEXT NOT NULL,
  stage VARCHAR(50) NOT NULL,
  due_date DATE NOT NULL,
  is_completed BOOLEAN NOT NULL DEFAULT FALSE,
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ------------------------------------------------------------------------------
-- 15. DISEASE SCANS
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.disease_scans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  farmer_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  image_url TEXT NOT NULL,
  crop_name VARCHAR(100),
  disease_name_hi VARCHAR(150) NOT NULL,
  disease_name_en VARCHAR(150) NOT NULL,
  confidence_score NUMERIC(5, 4) NOT NULL,
  severity VARCHAR(30) NOT NULL DEFAULT 'medium',
  treatment_hi TEXT NOT NULL,
  treatment_en TEXT NOT NULL,
  is_synced_with_server BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ------------------------------------------------------------------------------
-- 16. CHAT SESSIONS & MESSAGES (Krishi Sahayak Voice AI)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.chat_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  farmer_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  title VARCHAR(200) NOT NULL DEFAULT 'कृषि सहायक बातचीत',
  active_crop_context VARCHAR(100),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.chat_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID NOT NULL REFERENCES public.chat_sessions(id) ON DELETE CASCADE,
  farmer_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  role VARCHAR(20) NOT NULL CHECK (role IN ('user', 'assistant', 'system')),
  content TEXT NOT NULL,
  audio_url TEXT,
  language VARCHAR(5) NOT NULL DEFAULT 'hi',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ------------------------------------------------------------------------------
-- 17. MACHINERY (Rent / Lend)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.machinery (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  title_hi VARCHAR(150) NOT NULL,
  title_en VARCHAR(150) NOT NULL,
  machinery_type VARCHAR(50) NOT NULL,
  model_year INT,
  hp INT,
  hourly_rate NUMERIC(10, 2),
  daily_rate NUMERIC(10, 2),
  security_deposit NUMERIC(10, 2) DEFAULT 0.00,
  images TEXT[] NOT NULL DEFAULT '{}',
  village_or_city VARCHAR(100) NOT NULL,
  district VARCHAR(100) NOT NULL,
  state VARCHAR(100) NOT NULL,
  is_available BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.rentals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  machinery_id UUID NOT NULL REFERENCES public.machinery(id) ON DELETE RESTRICT,
  renter_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
  owner_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  total_days INT NOT NULL,
  total_amount NUMERIC(10, 2) NOT NULL,
  deposit_amount NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
  status rental_status NOT NULL DEFAULT 'pending',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ------------------------------------------------------------------------------
-- 18. SEED & FERTILIZER STORE ITEMS
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.store_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title_hi VARCHAR(150) NOT NULL,
  title_en VARCHAR(150) NOT NULL,
  item_type store_item_type NOT NULL,
  brand VARCHAR(100) NOT NULL,
  price NUMERIC(10, 2) NOT NULL CHECK (price > 0),
  pack_size VARCHAR(50) NOT NULL,
  stock_quantity INT NOT NULL CHECK (stock_quantity >= 0),
  image_url TEXT,
  description_hi TEXT NOT NULL,
  description_en TEXT NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ------------------------------------------------------------------------------
-- 19. NOTIFICATIONS
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  title_hi VARCHAR(200) NOT NULL,
  title_en VARCHAR(200) NOT NULL,
  body_hi TEXT NOT NULL,
  body_en TEXT NOT NULL,
  type VARCHAR(50) NOT NULL,
  payload JSONB DEFAULT '{}',
  is_read BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ------------------------------------------------------------------------------
-- 20. INDEXES FOR HIGH-THROUGHPUT PERFORMANCE
-- ------------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_profiles_role ON public.profiles(role);
CREATE INDEX IF NOT EXISTS idx_profiles_phone ON public.profiles(phone);
CREATE INDEX IF NOT EXISTS idx_profiles_location ON public.profiles(district, state);
CREATE INDEX IF NOT EXISTS idx_products_farmer ON public.products(farmer_id);
CREATE INDEX IF NOT EXISTS idx_products_category ON public.products(category_id);
CREATE INDEX IF NOT EXISTS idx_products_active ON public.products(is_active);
CREATE INDEX IF NOT EXISTS idx_products_district ON public.products(district, state);
CREATE INDEX IF NOT EXISTS idx_pack_options_product ON public.pack_options(product_id);
CREATE INDEX IF NOT EXISTS idx_orders_consumer ON public.orders(consumer_id);
CREATE INDEX IF NOT EXISTS idx_orders_farmer ON public.orders(farmer_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON public.orders(status);
CREATE INDEX IF NOT EXISTS idx_order_items_order ON public.order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_payments_order ON public.payments(order_id);
CREATE INDEX IF NOT EXISTS idx_delivery_order ON public.delivery(order_id);
CREATE INDEX IF NOT EXISTS idx_crop_plans_farmer ON public.crop_plans(farmer_id);
CREATE INDEX IF NOT EXISTS idx_tasks_farmer_due ON public.tasks(farmer_id, due_date, is_completed);
CREATE INDEX IF NOT EXISTS idx_disease_scans_farmer ON public.disease_scans(farmer_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_session ON public.chat_messages(session_id);
CREATE INDEX IF NOT EXISTS idx_machinery_district ON public.machinery(district, state, is_available);
CREATE INDEX IF NOT EXISTS idx_rentals_renter ON public.rentals(renter_id);
CREATE INDEX IF NOT EXISTS idx_rentals_owner ON public.rentals(owner_id);
CREATE INDEX IF NOT EXISTS idx_store_items_type ON public.store_items(item_type, is_active);
CREATE INDEX IF NOT EXISTS idx_notifications_user ON public.notifications(user_id, is_read);

-- ------------------------------------------------------------------------------
-- 21. AUTOMATIC UPDATED_AT TRIGGER & SECURITY GUARDS
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SET search_path = public, pg_temp;

DROP TRIGGER IF EXISTS trg_profiles_updated ON public.profiles;
CREATE TRIGGER trg_profiles_updated BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

DROP TRIGGER IF EXISTS trg_products_updated ON public.products;
CREATE TRIGGER trg_products_updated BEFORE UPDATE ON public.products FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

DROP TRIGGER IF EXISTS trg_orders_updated ON public.orders;
CREATE TRIGGER trg_orders_updated BEFORE UPDATE ON public.orders FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

DROP TRIGGER IF EXISTS trg_delivery_updated ON public.delivery;
CREATE TRIGGER trg_delivery_updated BEFORE UPDATE ON public.delivery FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

DROP TRIGGER IF EXISTS trg_crop_plans_updated ON public.crop_plans;
CREATE TRIGGER trg_crop_plans_updated BEFORE UPDATE ON public.crop_plans FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

DROP TRIGGER IF EXISTS trg_machinery_updated ON public.machinery;
CREATE TRIGGER trg_machinery_updated BEFORE UPDATE ON public.machinery FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- ------------------------------------------------------------------------------
-- 22. SECURITY DEFINER HELPER FUNCTIONS (Protected search_path)
-- ------------------------------------------------------------------------------
-- Helper Function: Check Admin with fixed search_path
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role = 'admin'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;

-- Anti-Privilege Escalation Trigger on Profiles
CREATE OR REPLACE FUNCTION public.protect_profile_privileges()
RETURNS TRIGGER AS $$
BEGIN
  -- Prevent privilege escalation on role, verified_by_admin, and kyc_status unless performed by admin
  IF (NEW.role IS DISTINCT FROM OLD.role OR
      NEW.kyc_status IS DISTINCT FROM OLD.kyc_status OR
      NEW.verified_by_admin IS DISTINCT FROM OLD.verified_by_admin) THEN
    IF NOT public.is_admin() THEN
      RAISE EXCEPTION 'Privilege escalation rejected: only admins can alter role, kyc_status, or verification flags.';
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;

DROP TRIGGER IF EXISTS trg_protect_profile_privileges ON public.profiles;
CREATE TRIGGER trg_protect_profile_privileges
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.protect_profile_privileges();

-- Anti-Tampering & State Machine Trigger on Orders
CREATE OR REPLACE FUNCTION public.protect_order_integrity_and_transitions()
RETURNS TRIGGER AS $$
DECLARE
  v_is_adm boolean;
BEGIN
  v_is_adm := public.is_admin();

  -- Non-admins cannot alter immutable financial, client, or order identifiers
  IF NOT v_is_adm THEN
    IF NEW.consumer_id IS DISTINCT FROM OLD.consumer_id THEN
      RAISE EXCEPTION 'Cannot tamper with order consumer_id';
    END IF;
    IF NEW.farmer_id IS DISTINCT FROM OLD.farmer_id THEN
      RAISE EXCEPTION 'Cannot tamper with order farmer_id';
    END IF;
    IF NEW.subtotal_amount IS DISTINCT FROM OLD.subtotal_amount THEN
      RAISE EXCEPTION 'Cannot tamper with order subtotal_amount';
    END IF;
    IF NEW.delivery_fee IS DISTINCT FROM OLD.delivery_fee THEN
      RAISE EXCEPTION 'Cannot tamper with order delivery_fee';
    END IF;
    IF NEW.total_amount IS DISTINCT FROM OLD.total_amount THEN
      RAISE EXCEPTION 'Cannot tamper with order total_amount';
    END IF;
    IF NEW.order_number IS DISTINCT FROM OLD.order_number THEN
      RAISE EXCEPTION 'Cannot tamper with order order_number';
    END IF;
  END IF;

  -- Validate state machine transitions
  IF NEW.status IS DISTINCT FROM OLD.status THEN
    IF OLD.status = 'delivered' THEN
      RAISE EXCEPTION 'Invalid status transition: delivered order is in terminal state';
    END IF;
    IF OLD.status = 'cancelled' THEN
      RAISE EXCEPTION 'Invalid status transition: cancelled order is in terminal state';
    END IF;

    IF OLD.status = 'pending_payment' THEN
      IF NEW.status NOT IN ('confirmed', 'cancelled') THEN
        RAISE EXCEPTION 'Invalid status transition from pending_payment to %', NEW.status;
      END IF;
      -- Consumer cannot mark paid directly without verified server payment
      IF NEW.status = 'confirmed' AND auth.uid() = OLD.consumer_id AND NOT v_is_adm THEN
        RAISE EXCEPTION 'Consumers cannot directly mark orders confirmed without server payment verification';
      END IF;
    ELSIF OLD.status = 'confirmed' THEN
      IF NEW.status NOT IN ('harvesting_packed', 'cancelled') THEN
        RAISE EXCEPTION 'Invalid status transition from confirmed to %', NEW.status;
      END IF;
      IF NEW.status = 'harvesting_packed' AND auth.uid() != OLD.farmer_id AND NOT v_is_adm THEN
        RAISE EXCEPTION 'Only the assigned farmer can mark order as harvesting_packed';
      END IF;
    ELSIF OLD.status = 'harvesting_packed' THEN
      IF NEW.status NOT IN ('out_for_delivery', 'ready_for_pickup', 'cancelled') THEN
        RAISE EXCEPTION 'Invalid status transition from harvesting_packed to %', NEW.status;
      END IF;
      IF auth.uid() != OLD.farmer_id AND NOT v_is_adm THEN
        RAISE EXCEPTION 'Only the assigned farmer can dispatch order';
      END IF;
    ELSIF OLD.status IN ('out_for_delivery', 'ready_for_pickup') THEN
      IF NEW.status NOT IN ('delivered', 'cancelled') THEN
        RAISE EXCEPTION 'Invalid status transition from % to %', OLD.status, NEW.status;
      END IF;
      IF NEW.status = 'delivered' AND auth.uid() = OLD.consumer_id AND NOT v_is_adm THEN
        RAISE EXCEPTION 'Consumers cannot mark orders as delivered directly';
      END IF;
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;

DROP TRIGGER IF EXISTS trg_orders_protect_integrity ON public.orders;
CREATE TRIGGER trg_orders_protect_integrity
  BEFORE UPDATE ON public.orders
  FOR EACH ROW EXECUTE FUNCTION public.protect_order_integrity_and_transitions();

-- Anti-Tampering & State Machine Trigger on Rentals
CREATE OR REPLACE FUNCTION public.protect_rental_integrity_and_transitions()
RETURNS TRIGGER AS $$
DECLARE
  v_is_adm boolean;
BEGIN
  v_is_adm := public.is_admin();

  IF NOT v_is_adm THEN
    IF NEW.machinery_id IS DISTINCT FROM OLD.machinery_id THEN
      RAISE EXCEPTION 'Cannot tamper with rental machinery_id';
    END IF;
    IF NEW.renter_id IS DISTINCT FROM OLD.renter_id THEN
      RAISE EXCEPTION 'Cannot tamper with rental renter_id';
    END IF;
    IF NEW.owner_id IS DISTINCT FROM OLD.owner_id THEN
      RAISE EXCEPTION 'Cannot tamper with rental owner_id';
    END IF;
    IF NEW.total_amount IS DISTINCT FROM OLD.total_amount THEN
      RAISE EXCEPTION 'Cannot tamper with rental total_amount';
    END IF;
    IF NEW.deposit_amount IS DISTINCT FROM OLD.deposit_amount THEN
      RAISE EXCEPTION 'Cannot tamper with rental deposit_amount';
    END IF;
    IF NEW.start_date IS DISTINCT FROM OLD.start_date THEN
      RAISE EXCEPTION 'Cannot tamper with rental start_date';
    END IF;
    IF NEW.end_date IS DISTINCT FROM OLD.end_date THEN
      RAISE EXCEPTION 'Cannot tamper with rental end_date';
    END IF;
  END IF;

  IF NEW.status IS DISTINCT FROM OLD.status THEN
    IF OLD.status = 'completed' THEN
      RAISE EXCEPTION 'Invalid status transition: completed rental is in terminal state';
    END IF;
    IF OLD.status = 'cancelled' THEN
      RAISE EXCEPTION 'Invalid status transition: cancelled rental is in terminal state';
    END IF;

    IF OLD.status = 'pending' THEN
      IF NEW.status NOT IN ('approved', 'cancelled') THEN
        RAISE EXCEPTION 'Invalid status transition from pending to %', NEW.status;
      END IF;
      IF NEW.status = 'approved' AND auth.uid() != OLD.owner_id AND NOT v_is_adm THEN
        RAISE EXCEPTION 'Only machinery owner can approve rental';
      END IF;
    ELSIF OLD.status = 'approved' THEN
      IF NEW.status NOT IN ('active', 'cancelled') THEN
        RAISE EXCEPTION 'Invalid status transition from approved to %', NEW.status;
      END IF;
      IF NEW.status = 'active' AND auth.uid() != OLD.owner_id AND NOT v_is_adm THEN
        RAISE EXCEPTION 'Only machinery owner can mark rental as active upon handover';
      END IF;
    ELSIF OLD.status = 'active' THEN
      IF NEW.status NOT IN ('completed') THEN
        RAISE EXCEPTION 'Invalid status transition: active rental can only transition to completed';
      END IF;
      IF NEW.status = 'completed' AND auth.uid() != OLD.owner_id AND NOT v_is_adm THEN
        RAISE EXCEPTION 'Only machinery owner can mark rental completed upon return inspection';
      END IF;
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;

DROP TRIGGER IF EXISTS trg_rentals_protect_integrity ON public.rentals;
CREATE TRIGGER trg_rentals_protect_integrity
  BEFORE UPDATE ON public.rentals
  FOR EACH ROW EXECUTE FUNCTION public.protect_rental_integrity_and_transitions();

-- Order Item Insertion Guard (Only allow inserts while order is pending_payment)
CREATE OR REPLACE FUNCTION public.check_order_item_insertion()
RETURNS TRIGGER AS $$
DECLARE
  v_status order_status;
BEGIN
  SELECT status INTO v_status FROM public.orders WHERE id = NEW.order_id;
  IF v_status IS NULL THEN
    RAISE EXCEPTION 'Target order does not exist';
  END IF;
  IF v_status != 'pending_payment' THEN
    RAISE EXCEPTION 'Cannot add items to order with status %; only pending_payment permitted', v_status;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;

DROP TRIGGER IF EXISTS trg_order_items_insertion ON public.order_items;
CREATE TRIGGER trg_order_items_insertion
  BEFORE INSERT ON public.order_items
  FOR EACH ROW EXECUTE FUNCTION public.check_order_item_insertion();

-- Atomic Stock Deduction with Row-Level Lock (FOR UPDATE)
CREATE OR REPLACE FUNCTION public.deduct_order_stock(p_order_id UUID)
RETURNS VOID AS $$
DECLARE
  v_item RECORD;
  v_product RECORD;
  v_needed_kg NUMERIC;
BEGIN
  -- Iterate through order items in product_id sorted order to avoid deadlocks
  FOR v_item IN
    SELECT product_id, pack_size_kg, quantity
    FROM public.order_items
    WHERE order_id = p_order_id
    ORDER BY product_id
  LOOP
    v_needed_kg := (v_item.pack_size_kg * v_item.quantity)::NUMERIC;

    -- Lock the product row FOR UPDATE to serialize concurrent orders
    SELECT id, stock_kg INTO v_product
    FROM public.products
    WHERE id = v_item.product_id
    FOR UPDATE;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'Product % not found during stock deduction', v_item.product_id;
    END IF;

    IF v_product.stock_kg < v_needed_kg THEN
      RAISE EXCEPTION 'Insufficient stock for product %: requested % kg, available % kg',
        v_item.product_id, v_needed_kg, v_product.stock_kg;
    END IF;

    UPDATE public.products
    SET stock_kg = stock_kg - v_needed_kg,
        updated_at = NOW()
    WHERE id = v_item.product_id;
  END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;

-- Restore Stock on Order Cancellation
CREATE OR REPLACE FUNCTION public.restore_order_stock(p_order_id UUID)
RETURNS VOID AS $$
DECLARE
  v_item RECORD;
  v_needed_kg NUMERIC;
BEGIN
  FOR v_item IN
    SELECT product_id, pack_size_kg, quantity
    FROM public.order_items
    WHERE order_id = p_order_id
    ORDER BY product_id
  LOOP
    v_needed_kg := (v_item.pack_size_kg * v_item.quantity)::NUMERIC;
    UPDATE public.products
    SET stock_kg = stock_kg + v_needed_kg,
        updated_at = NOW()
    WHERE id = v_item.product_id;
  END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;

-- ------------------------------------------------------------------------------
-- 23. SENSITIVE DATA VIEWS & DB CONSTRAINTS
-- ------------------------------------------------------------------------------
-- Unique index for idempotent payment deduplication (prevents replay attacks)
CREATE UNIQUE INDEX IF NOT EXISTS idx_payments_razorpay_payment_id
  ON public.payments(razorpay_payment_id)
  WHERE razorpay_payment_id IS NOT NULL;

-- Public farmer directory view (Sanitizes bank_account, IFSC, Aadhaar, KCC, and UPI VPAs)
CREATE OR REPLACE VIEW public.public_farmer_profiles WITH (security_invoker = false) AS
  SELECT
    farmer_id,
    farm_name,
    total_acres,
    soil_type,
    primary_crops,
    bio_hi,
    bio_en,
    created_at
  FROM public.farmer_profiles;

-- Add database integrity constraints
DO $$ BEGIN
  ALTER TABLE public.orders ADD CONSTRAINT chk_orders_total_sum CHECK (total_amount = subtotal_amount + delivery_fee);
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
  ALTER TABLE public.order_items ADD CONSTRAINT chk_order_items_total CHECK (total_price = quantity * price_per_pack);
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
  ALTER TABLE public.rentals ADD CONSTRAINT chk_rentals_dates CHECK (end_date >= start_date);
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
  ALTER TABLE public.ratings ADD CONSTRAINT chk_ratings_not_self CHECK (consumer_id != farmer_id);
EXCEPTION WHEN duplicate_object THEN null; END $$;

-- ------------------------------------------------------------------------------
-- 24. ROW LEVEL SECURITY (RLS) POLICIES (Least Privilege)
-- ------------------------------------------------------------------------------
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.farmer_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pack_options ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ratings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.delivery ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.crops ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.crop_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.disease_scans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.machinery ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rentals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.store_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- PROFILES
-- Sensitive user PII (phone, address, coordinates) readable ONLY by owner, admin,
-- or active counterparties (farmers with listings, or direct order/rental counterparty)
DROP POLICY IF EXISTS "Profiles viewable by authenticated users" ON public.profiles;
DROP POLICY IF EXISTS "Profiles select policy" ON public.profiles;
CREATE POLICY "Profiles select policy"
  ON public.profiles FOR SELECT TO authenticated
  USING (
    auth.uid() = id
    OR public.is_admin()
    OR role = 'farmer'
    OR EXISTS (
      SELECT 1 FROM public.orders o
      WHERE (o.consumer_id = auth.uid() AND o.farmer_id = profiles.id)
         OR (o.farmer_id = auth.uid() AND o.consumer_id = profiles.id)
    )
    OR EXISTS (
      SELECT 1 FROM public.rentals r
      WHERE (r.renter_id = auth.uid() AND r.owner_id = profiles.id)
         OR (r.owner_id = auth.uid() AND r.renter_id = profiles.id)
    )
  );

DROP POLICY IF EXISTS "Users can insert own profile" ON public.profiles;
CREATE POLICY "Users can insert own profile"
  ON public.profiles FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
DROP POLICY IF EXISTS "Admins can update any profile" ON public.profiles;
DROP POLICY IF EXISTS "Users and admins update profiles" ON public.profiles;
CREATE POLICY "Users and admins update profiles"
  ON public.profiles FOR UPDATE TO authenticated
  USING (auth.uid() = id OR public.is_admin())
  WITH CHECK (auth.uid() = id OR public.is_admin());

-- FARMER PROFILES (CRITICAL: Contains Bank Details, IFSC, Aadhaar last4, KCC, UPI)
-- Only owner farmer and admins can SELECT/UPDATE directly from farmer_profiles
DROP POLICY IF EXISTS "Farmer profiles public view" ON public.farmer_profiles;
DROP POLICY IF EXISTS "Farmer profiles owner and admin select" ON public.farmer_profiles;
CREATE POLICY "Farmer profiles owner and admin select"
  ON public.farmer_profiles FOR SELECT TO authenticated
  USING (auth.uid() = farmer_id OR public.is_admin());

DROP POLICY IF EXISTS "Farmers can insert own farmer profile" ON public.farmer_profiles;
CREATE POLICY "Farmers can insert own farmer profile"
  ON public.farmer_profiles FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = farmer_id);

DROP POLICY IF EXISTS "Farmers can update own farmer profile" ON public.farmer_profiles;
CREATE POLICY "Farmers can update own farmer profile"
  ON public.farmer_profiles FOR UPDATE TO authenticated
  USING (auth.uid() = farmer_id OR public.is_admin())
  WITH CHECK (auth.uid() = farmer_id OR public.is_admin());

DROP POLICY IF EXISTS "Farmers can delete own farmer profile" ON public.farmer_profiles;
CREATE POLICY "Farmers can delete own farmer profile"
  ON public.farmer_profiles FOR DELETE TO authenticated
  USING (auth.uid() = farmer_id OR public.is_admin());

-- CATEGORIES
DROP POLICY IF EXISTS "Categories viewable by everyone" ON public.categories;
CREATE POLICY "Categories viewable by everyone"
  ON public.categories FOR SELECT TO public
  USING (true);

DROP POLICY IF EXISTS "Admins manage categories" ON public.categories;
CREATE POLICY "Admins manage categories"
  ON public.categories FOR ALL TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- PRODUCTS
DROP POLICY IF EXISTS "Products viewable by anyone" ON public.products;
CREATE POLICY "Products viewable by anyone"
  ON public.products FOR SELECT TO public
  USING (is_active = true OR auth.uid() = farmer_id OR public.is_admin());

DROP POLICY IF EXISTS "Farmers insert products" ON public.products;
CREATE POLICY "Farmers insert products"
  ON public.products FOR INSERT TO authenticated
  WITH CHECK (
    auth.uid() = farmer_id AND
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'farmer')
  );

DROP POLICY IF EXISTS "Farmers update own products" ON public.products;
CREATE POLICY "Farmers update own products"
  ON public.products FOR UPDATE TO authenticated
  USING (auth.uid() = farmer_id OR public.is_admin())
  WITH CHECK (auth.uid() = farmer_id OR public.is_admin());

DROP POLICY IF EXISTS "Farmers delete own products" ON public.products;
CREATE POLICY "Farmers delete own products"
  ON public.products FOR DELETE TO authenticated
  USING (auth.uid() = farmer_id OR public.is_admin());

-- PACK OPTIONS
DROP POLICY IF EXISTS "Pack options viewable by anyone" ON public.pack_options;
CREATE POLICY "Pack options viewable by anyone"
  ON public.pack_options FOR SELECT TO public
  USING (true);

DROP POLICY IF EXISTS "Farmers manage pack options" ON public.pack_options;
CREATE POLICY "Farmers manage pack options"
  ON public.pack_options FOR ALL TO authenticated
  USING (
    EXISTS (SELECT 1 FROM public.products p WHERE p.id = pack_options.product_id AND p.farmer_id = auth.uid())
    OR public.is_admin()
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM public.products p WHERE p.id = pack_options.product_id AND p.farmer_id = auth.uid())
    OR public.is_admin()
  );

-- ORDERS
DROP POLICY IF EXISTS "Orders viewable by parties and admin" ON public.orders;
CREATE POLICY "Orders viewable by parties and admin"
  ON public.orders FOR SELECT TO authenticated
  USING (
    auth.uid() = consumer_id OR auth.uid() = farmer_id OR public.is_admin()
  );

DROP POLICY IF EXISTS "Consumers can create orders" ON public.orders;
CREATE POLICY "Consumers can create orders"
  ON public.orders FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = consumer_id);

DROP POLICY IF EXISTS "Order status update by parties" ON public.orders;
CREATE POLICY "Order status update by parties"
  ON public.orders FOR UPDATE TO authenticated
  USING (
    auth.uid() = consumer_id OR auth.uid() = farmer_id OR public.is_admin()
  )
  WITH CHECK (
    auth.uid() = consumer_id OR auth.uid() = farmer_id OR public.is_admin()
  );

DROP POLICY IF EXISTS "Admins can delete orders" ON public.orders;
CREATE POLICY "Admins can delete orders"
  ON public.orders FOR DELETE TO authenticated
  USING (public.is_admin());

-- ORDER ITEMS
DROP POLICY IF EXISTS "Order items viewable by participants" ON public.order_items;
CREATE POLICY "Order items viewable by participants"
  ON public.order_items FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.orders o
      WHERE o.id = order_items.order_id
      AND (o.consumer_id = auth.uid() OR o.farmer_id = auth.uid() OR public.is_admin())
    )
  );

DROP POLICY IF EXISTS "Consumers can insert order items" ON public.order_items;
CREATE POLICY "Consumers can insert order items"
  ON public.order_items FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.orders o
      WHERE o.id = order_items.order_id
      AND o.consumer_id = auth.uid()
      AND o.status = 'pending_payment'
    )
  );

DROP POLICY IF EXISTS "Admins manage order items" ON public.order_items;
CREATE POLICY "Admins manage order items"
  ON public.order_items FOR ALL TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- PAYMENTS (Client restricted: only service_role / admin can insert or update)
DROP POLICY IF EXISTS "Payments viewable by parties and admin" ON public.payments;
CREATE POLICY "Payments viewable by parties and admin"
  ON public.payments FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.orders o
      WHERE o.id = payments.order_id
      AND (o.consumer_id = auth.uid() OR o.farmer_id = auth.uid() OR public.is_admin())
    )
  );

DROP POLICY IF EXISTS "Payments insert restricted to admin or service role" ON public.payments;
CREATE POLICY "Payments insert restricted to admin or service role"
  ON public.payments FOR INSERT TO authenticated
  WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "Payments update restricted to admin or service role" ON public.payments;
CREATE POLICY "Payments update restricted to admin or service role"
  ON public.payments FOR UPDATE TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- RATINGS
DROP POLICY IF EXISTS "Ratings viewable by everyone" ON public.ratings;
CREATE POLICY "Ratings viewable by everyone"
  ON public.ratings FOR SELECT TO public
  USING (true);

DROP POLICY IF EXISTS "Consumers can write ratings" ON public.ratings;
CREATE POLICY "Consumers can write ratings"
  ON public.ratings FOR INSERT TO authenticated
  WITH CHECK (
    auth.uid() = consumer_id AND
    consumer_id != farmer_id AND
    EXISTS (
      SELECT 1 FROM public.orders o
      WHERE o.id = ratings.order_id AND o.consumer_id = auth.uid() AND o.status = 'delivered'
    )
  );

DROP POLICY IF EXISTS "Consumers can update own ratings" ON public.ratings;
CREATE POLICY "Consumers can update own ratings"
  ON public.ratings FOR UPDATE TO authenticated
  USING (auth.uid() = consumer_id OR public.is_admin())
  WITH CHECK (auth.uid() = consumer_id OR public.is_admin());

DROP POLICY IF EXISTS "Consumers can delete own ratings" ON public.ratings;
CREATE POLICY "Consumers can delete own ratings"
  ON public.ratings FOR DELETE TO authenticated
  USING (auth.uid() = consumer_id OR public.is_admin());

-- DELIVERY
DROP POLICY IF EXISTS "Delivery viewable by order participants" ON public.delivery;
CREATE POLICY "Delivery viewable by order participants"
  ON public.delivery FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.orders o
      WHERE o.id = delivery.order_id
      AND (o.consumer_id = auth.uid() OR o.farmer_id = auth.uid() OR public.is_admin())
    )
  );

DROP POLICY IF EXISTS "Delivery insert by order farmer or admin" ON public.delivery;
CREATE POLICY "Delivery insert by order farmer or admin"
  ON public.delivery FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.orders o
      WHERE o.id = delivery.order_id AND (o.farmer_id = auth.uid() OR public.is_admin())
    )
  );

DROP POLICY IF EXISTS "Delivery status update by farmer or admin" ON public.delivery;
CREATE POLICY "Delivery status update by farmer or admin"
  ON public.delivery FOR UPDATE TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.orders o
      WHERE o.id = delivery.order_id AND (o.farmer_id = auth.uid() OR public.is_admin())
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.orders o
      WHERE o.id = delivery.order_id AND (o.farmer_id = auth.uid() OR public.is_admin())
    )
  );

-- CROPS (Master Knowledge)
DROP POLICY IF EXISTS "Crops viewable by everyone" ON public.crops;
CREATE POLICY "Crops viewable by everyone"
  ON public.crops FOR SELECT TO public
  USING (true);

DROP POLICY IF EXISTS "Admins manage master crops" ON public.crops;
CREATE POLICY "Admins manage master crops"
  ON public.crops FOR ALL TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- CROP PLANS
DROP POLICY IF EXISTS "Farmers view own crop plans" ON public.crop_plans;
DROP POLICY IF EXISTS "Farmers select own crop plans" ON public.crop_plans;
CREATE POLICY "Farmers select own crop plans"
  ON public.crop_plans FOR SELECT TO authenticated
  USING (auth.uid() = farmer_id OR public.is_admin());

DROP POLICY IF EXISTS "Farmers insert own crop plans" ON public.crop_plans;
CREATE POLICY "Farmers insert own crop plans"
  ON public.crop_plans FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = farmer_id);

DROP POLICY IF EXISTS "Farmers update own crop plans" ON public.crop_plans;
CREATE POLICY "Farmers update own crop plans"
  ON public.crop_plans FOR UPDATE TO authenticated
  USING (auth.uid() = farmer_id OR public.is_admin())
  WITH CHECK (auth.uid() = farmer_id OR public.is_admin());

DROP POLICY IF EXISTS "Farmers delete own crop plans" ON public.crop_plans;
CREATE POLICY "Farmers delete own crop plans"
  ON public.crop_plans FOR DELETE TO authenticated
  USING (auth.uid() = farmer_id OR public.is_admin());

-- TASKS
DROP POLICY IF EXISTS "Farmers view own tasks" ON public.tasks;
DROP POLICY IF EXISTS "Farmers select own tasks" ON public.tasks;
CREATE POLICY "Farmers select own tasks"
  ON public.tasks FOR SELECT TO authenticated
  USING (auth.uid() = farmer_id OR public.is_admin());

DROP POLICY IF EXISTS "Farmers insert own tasks" ON public.tasks;
CREATE POLICY "Farmers insert own tasks"
  ON public.tasks FOR INSERT TO authenticated
  WITH CHECK (
    auth.uid() = farmer_id AND
    EXISTS (
      SELECT 1 FROM public.crop_plans cp
      WHERE cp.id = tasks.crop_plan_id AND cp.farmer_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "Farmers update own tasks" ON public.tasks;
CREATE POLICY "Farmers update own tasks"
  ON public.tasks FOR UPDATE TO authenticated
  USING (auth.uid() = farmer_id OR public.is_admin())
  WITH CHECK (auth.uid() = farmer_id OR public.is_admin());

DROP POLICY IF EXISTS "Farmers delete own tasks" ON public.tasks;
CREATE POLICY "Farmers delete own tasks"
  ON public.tasks FOR DELETE TO authenticated
  USING (auth.uid() = farmer_id OR public.is_admin());

-- DISEASE SCANS
DROP POLICY IF EXISTS "Farmers view own disease scans" ON public.disease_scans;
DROP POLICY IF EXISTS "Farmers select own disease scans" ON public.disease_scans;
CREATE POLICY "Farmers select own disease scans"
  ON public.disease_scans FOR SELECT TO authenticated
  USING (auth.uid() = farmer_id OR public.is_admin());

DROP POLICY IF EXISTS "Farmers insert own disease scans" ON public.disease_scans;
CREATE POLICY "Farmers insert own disease scans"
  ON public.disease_scans FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = farmer_id);

DROP POLICY IF EXISTS "Farmers update own disease scans" ON public.disease_scans;
CREATE POLICY "Farmers update own disease scans"
  ON public.disease_scans FOR UPDATE TO authenticated
  USING (auth.uid() = farmer_id OR public.is_admin())
  WITH CHECK (auth.uid() = farmer_id OR public.is_admin());

DROP POLICY IF EXISTS "Farmers delete own disease scans" ON public.disease_scans;
CREATE POLICY "Farmers delete own disease scans"
  ON public.disease_scans FOR DELETE TO authenticated
  USING (auth.uid() = farmer_id OR public.is_admin());

-- CHAT SESSIONS
DROP POLICY IF EXISTS "Farmers view own chat sessions" ON public.chat_sessions;
DROP POLICY IF EXISTS "Farmers select own chat sessions" ON public.chat_sessions;
CREATE POLICY "Farmers select own chat sessions"
  ON public.chat_sessions FOR SELECT TO authenticated
  USING (auth.uid() = farmer_id OR public.is_admin());

DROP POLICY IF EXISTS "Farmers insert own chat sessions" ON public.chat_sessions;
CREATE POLICY "Farmers insert own chat sessions"
  ON public.chat_sessions FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = farmer_id);

DROP POLICY IF EXISTS "Farmers update own chat sessions" ON public.chat_sessions;
CREATE POLICY "Farmers update own chat sessions"
  ON public.chat_sessions FOR UPDATE TO authenticated
  USING (auth.uid() = farmer_id OR public.is_admin())
  WITH CHECK (auth.uid() = farmer_id OR public.is_admin());

DROP POLICY IF EXISTS "Farmers delete own chat sessions" ON public.chat_sessions;
CREATE POLICY "Farmers delete own chat sessions"
  ON public.chat_sessions FOR DELETE TO authenticated
  USING (auth.uid() = farmer_id OR public.is_admin());

-- CHAT MESSAGES
DROP POLICY IF EXISTS "Farmers view own chat messages" ON public.chat_messages;
DROP POLICY IF EXISTS "Farmers select own chat messages" ON public.chat_messages;
CREATE POLICY "Farmers select own chat messages"
  ON public.chat_messages FOR SELECT TO authenticated
  USING (auth.uid() = farmer_id OR public.is_admin());

DROP POLICY IF EXISTS "Farmers insert own chat messages" ON public.chat_messages;
CREATE POLICY "Farmers insert own chat messages"
  ON public.chat_messages FOR INSERT TO authenticated
  WITH CHECK (
    auth.uid() = farmer_id AND
    EXISTS (
      SELECT 1 FROM public.chat_sessions s
      WHERE s.id = chat_messages.session_id AND s.farmer_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "Farmers update own chat messages" ON public.chat_messages;
CREATE POLICY "Farmers update own chat messages"
  ON public.chat_messages FOR UPDATE TO authenticated
  USING (auth.uid() = farmer_id OR public.is_admin())
  WITH CHECK (auth.uid() = farmer_id OR public.is_admin());

DROP POLICY IF EXISTS "Farmers delete own chat messages" ON public.chat_messages;
CREATE POLICY "Farmers delete own chat messages"
  ON public.chat_messages FOR DELETE TO authenticated
  USING (auth.uid() = farmer_id OR public.is_admin());

-- MACHINERY
DROP POLICY IF EXISTS "Machinery viewable by everyone" ON public.machinery;
CREATE POLICY "Machinery viewable by everyone"
  ON public.machinery FOR SELECT TO public
  USING (is_available = true OR auth.uid() = owner_id OR public.is_admin());

DROP POLICY IF EXISTS "Farmers manage own machinery" ON public.machinery;
DROP POLICY IF EXISTS "Farmers insert own machinery" ON public.machinery;
CREATE POLICY "Farmers insert own machinery"
  ON public.machinery FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = owner_id);

DROP POLICY IF EXISTS "Farmers update own machinery" ON public.machinery;
CREATE POLICY "Farmers update own machinery"
  ON public.machinery FOR UPDATE TO authenticated
  USING (auth.uid() = owner_id OR public.is_admin())
  WITH CHECK (auth.uid() = owner_id OR public.is_admin());

DROP POLICY IF EXISTS "Farmers delete own machinery" ON public.machinery;
CREATE POLICY "Farmers delete own machinery"
  ON public.machinery FOR DELETE TO authenticated
  USING (auth.uid() = owner_id OR public.is_admin());

-- RENTALS
DROP POLICY IF EXISTS "Rentals viewable by renter and owner" ON public.rentals;
CREATE POLICY "Rentals viewable by renter and owner"
  ON public.rentals FOR SELECT TO authenticated
  USING (
    auth.uid() = renter_id OR auth.uid() = owner_id OR public.is_admin()
  );

DROP POLICY IF EXISTS "Users can create rental requests" ON public.rentals;
CREATE POLICY "Users can create rental requests"
  ON public.rentals FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = renter_id AND renter_id != owner_id);

DROP POLICY IF EXISTS "Parties can update rental status" ON public.rentals;
CREATE POLICY "Parties can update rental status"
  ON public.rentals FOR UPDATE TO authenticated
  USING (
    auth.uid() = renter_id OR auth.uid() = owner_id OR public.is_admin()
  )
  WITH CHECK (
    auth.uid() = renter_id OR auth.uid() = owner_id OR public.is_admin()
  );

DROP POLICY IF EXISTS "Admins manage rentals" ON public.rentals;
CREATE POLICY "Admins manage rentals"
  ON public.rentals FOR DELETE TO authenticated
  USING (public.is_admin());

-- STORE ITEMS
DROP POLICY IF EXISTS "Store items viewable by everyone" ON public.store_items;
CREATE POLICY "Store items viewable by everyone"
  ON public.store_items FOR SELECT TO public
  USING (is_active = true OR public.is_admin());

DROP POLICY IF EXISTS "Admins manage store items" ON public.store_items;
CREATE POLICY "Admins manage store items"
  ON public.store_items FOR ALL TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- NOTIFICATIONS
DROP POLICY IF EXISTS "Users view own notifications" ON public.notifications;
DROP POLICY IF EXISTS "Users select own notifications" ON public.notifications;
CREATE POLICY "Users select own notifications"
  ON public.notifications FOR SELECT TO authenticated
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users update own notifications" ON public.notifications;
CREATE POLICY "Users update own notifications"
  ON public.notifications FOR UPDATE TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Notifications insert restricted to admin or system" ON public.notifications;
CREATE POLICY "Notifications insert restricted to admin or system"
  ON public.notifications FOR INSERT TO authenticated
  WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "Users delete own notifications" ON public.notifications;
CREATE POLICY "Users delete own notifications"
  ON public.notifications FOR DELETE TO authenticated
  USING (auth.uid() = user_id OR public.is_admin());

-- ------------------------------------------------------------------------------
-- 25. STORAGE BUCKET POLICIES (Tenant Folder Isolation)
-- ------------------------------------------------------------------------------
INSERT INTO storage.buckets (id, name, public) VALUES
  ('product-images', 'product-images', true),
  ('disease-scans', 'disease-scans', false),
  ('machinery-images', 'machinery-images', true),
  ('kyc-docs', 'kyc-docs', false)
ON CONFLICT (id) DO NOTHING;

DROP POLICY IF EXISTS "Public view product images" ON storage.objects;
DROP POLICY IF EXISTS "Farmers upload images" ON storage.objects;
DROP POLICY IF EXISTS "Public read for public buckets" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated read for private buckets" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users isolated upload" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users isolated update" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users isolated delete" ON storage.objects;

-- Public read for product and machinery images
CREATE POLICY "Public read for public buckets"
  ON storage.objects FOR SELECT TO public
  USING (bucket_id IN ('product-images', 'machinery-images'));

-- Private read for disease-scans and kyc-docs (Strictly owner or admin)
CREATE POLICY "Authenticated read for private buckets"
  ON storage.objects FOR SELECT TO authenticated
  USING (
    bucket_id IN ('product-images', 'machinery-images')
    OR (
      bucket_id IN ('disease-scans', 'kyc-docs')
      AND ((storage.foldername(name))[1] = auth.uid()::text OR public.is_admin())
    )
  );

-- Upload policy: Users can only upload into a subfolder matching their own auth.uid()
CREATE POLICY "Authenticated users isolated upload"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id IN ('product-images', 'disease-scans', 'machinery-images', 'kyc-docs')
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- Update policy: Users can only modify objects in their own folder
CREATE POLICY "Authenticated users isolated update"
  ON storage.objects FOR UPDATE TO authenticated
  USING (
    (storage.foldername(name))[1] = auth.uid()::text OR public.is_admin()
  )
  WITH CHECK (
    (storage.foldername(name))[1] = auth.uid()::text OR public.is_admin()
  );

-- Delete policy: Users can only delete objects in their own folder
CREATE POLICY "Authenticated users isolated delete"
  ON storage.objects FOR DELETE TO authenticated
  USING (
    (storage.foldername(name))[1] = auth.uid()::text OR public.is_admin()
  );
