-- ============================================================================
-- 015_pilot_marketplace_foundation.sql
-- Module: VyaparSetu Pilot Marketplace Foundation (Step 7 - Schema Only)
-- Description: Creates the minimal secure database schema required for pilot
--              marketplace data:
--              1. public.buyer_profiles (supports both auth and synthetic buyers)
--              2. public.buyer_requests (pilot buyer demand signals)
--              3. public.orders (pilot marketplace transaction history)
--
-- Security Guarantees & Architectural Boundaries:
-- 1. Decoupled Buyer Identity: buyer_profiles uses gen_random_uuid() for primary key
--    with optional auth_user_id REFERENCES auth.users(id). This cleanly permits
--    synthetic demo buyers for pilot seeding without requiring mock auth accounts.
-- 2. Producer Protection: Existing producer_profiles and products tables remain
--    strictly untouched. No raw identity/PAN data is introduced.
-- 3. Strict Row Level Security (RLS):
--    - Authenticated buyers can only read/manage their own profiles, requests, and orders.
--    - Authenticated verified producers can only read 'active' buyer requests for
--      marketplace discovery / BI signals.
--    - Authenticated producers can only view and update their own received orders.
--    - Anonymous users have zero access (REVOKE ALL).
-- 4. Audit Triggers: Automated updated_at triggers reusing public.handle_updated_at().
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. BUYER PROFILES TABLE
-- ----------------------------------------------------------------------------
-- Represents buyer entities for pilot transactions, demand requests, and BI.
-- Supports synthetic buyers (auth_user_id IS NULL) and real buyers (auth_user_id NOT NULL).

CREATE TABLE IF NOT EXISTS public.buyer_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    auth_user_id UUID NULL REFERENCES auth.users(id) ON DELETE SET NULL,
    display_name TEXT NOT NULL,
    business_name TEXT NULL,
    buyer_type TEXT NOT NULL,
    state TEXT NOT NULL,
    district TEXT NOT NULL,
    city TEXT NULL,
    pincode TEXT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT pg_catalog.now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT pg_catalog.now(),
    CONSTRAINT uq_buyer_profiles_auth_user_id UNIQUE (auth_user_id)
);

-- Defensive Constraints for buyer_profiles
DO $$ BEGIN
    ALTER TABLE public.buyer_profiles
        ADD CONSTRAINT chk_buyer_profiles_display_name_not_empty
            CHECK (pg_catalog.length(pg_catalog.btrim(display_name)) > 0);
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    ALTER TABLE public.buyer_profiles
        ADD CONSTRAINT chk_buyer_profiles_type
            CHECK (buyer_type IN ('consumer', 'retailer', 'wholesaler', 'institution'));
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    ALTER TABLE public.buyer_profiles
        ADD CONSTRAINT chk_buyer_profiles_state_not_empty
            CHECK (pg_catalog.length(pg_catalog.btrim(state)) > 0);
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    ALTER TABLE public.buyer_profiles
        ADD CONSTRAINT chk_buyer_profiles_district_not_empty
            CHECK (pg_catalog.length(pg_catalog.btrim(district)) > 0);
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    ALTER TABLE public.buyer_profiles
        ADD CONSTRAINT chk_buyer_profiles_pincode_format
            CHECK (pincode IS NULL OR pincode ~ '^[1-9][0-9]{5}$');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Indexes for buyer_profiles
CREATE INDEX IF NOT EXISTS idx_buyer_profiles_auth_user_id
    ON public.buyer_profiles(auth_user_id)
    WHERE auth_user_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_buyer_profiles_type
    ON public.buyer_profiles(buyer_type);

CREATE INDEX IF NOT EXISTS idx_buyer_profiles_location
    ON public.buyer_profiles(state, district);

-- Automated updated_at trigger
DROP TRIGGER IF EXISTS trg_buyer_profiles_updated_at ON public.buyer_profiles;
CREATE TRIGGER trg_buyer_profiles_updated_at
    BEFORE UPDATE ON public.buyer_profiles
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();


-- ----------------------------------------------------------------------------
-- 2. BUYER REQUESTS TABLE
-- ----------------------------------------------------------------------------
-- Stores demand posts and sourcing requirements from buyers.

CREATE TABLE IF NOT EXISTS public.buyer_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    buyer_id UUID NOT NULL REFERENCES public.buyer_profiles(id) ON DELETE CASCADE,
    product_name TEXT NOT NULL,
    category TEXT NOT NULL,
    quantity NUMERIC NOT NULL,
    unit TEXT NOT NULL,
    target_price NUMERIC(10, 2) NULL,
    urgency TEXT NOT NULL DEFAULT 'medium',
    status TEXT NOT NULL DEFAULT 'active',
    state TEXT NOT NULL,
    district TEXT NOT NULL,
    notes TEXT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT pg_catalog.now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT pg_catalog.now()
);

-- Defensive Constraints for buyer_requests
DO $$ BEGIN
    ALTER TABLE public.buyer_requests
        ADD CONSTRAINT chk_buyer_requests_product_name_not_empty
            CHECK (pg_catalog.length(pg_catalog.btrim(product_name)) > 0);
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    ALTER TABLE public.buyer_requests
        ADD CONSTRAINT chk_buyer_requests_category_not_empty
            CHECK (pg_catalog.length(pg_catalog.btrim(category)) > 0);
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    ALTER TABLE public.buyer_requests
        ADD CONSTRAINT chk_buyer_requests_quantity_positive
            CHECK (quantity > 0);
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    ALTER TABLE public.buyer_requests
        ADD CONSTRAINT chk_buyer_requests_unit_not_empty
            CHECK (pg_catalog.length(pg_catalog.btrim(unit)) > 0);
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    ALTER TABLE public.buyer_requests
        ADD CONSTRAINT chk_buyer_requests_target_price_non_negative
            CHECK (target_price IS NULL OR target_price >= 0);
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    ALTER TABLE public.buyer_requests
        ADD CONSTRAINT chk_buyer_requests_urgency
            CHECK (urgency IN ('low', 'medium', 'high'));
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    ALTER TABLE public.buyer_requests
        ADD CONSTRAINT chk_buyer_requests_status
            CHECK (status IN ('active', 'matched', 'fulfilled', 'cancelled', 'expired'));
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    ALTER TABLE public.buyer_requests
        ADD CONSTRAINT chk_buyer_requests_state_not_empty
            CHECK (pg_catalog.length(pg_catalog.btrim(state)) > 0);
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    ALTER TABLE public.buyer_requests
        ADD CONSTRAINT chk_buyer_requests_district_not_empty
            CHECK (pg_catalog.length(pg_catalog.btrim(district)) > 0);
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Indexes for buyer_requests
CREATE INDEX IF NOT EXISTS idx_buyer_requests_buyer_id
    ON public.buyer_requests(buyer_id);

CREATE INDEX IF NOT EXISTS idx_buyer_requests_category
    ON public.buyer_requests(category);

CREATE INDEX IF NOT EXISTS idx_buyer_requests_status
    ON public.buyer_requests(status);

CREATE INDEX IF NOT EXISTS idx_buyer_requests_location
    ON public.buyer_requests(state, district);

CREATE INDEX IF NOT EXISTS idx_buyer_requests_created_at
    ON public.buyer_requests(created_at DESC);

-- Automated updated_at trigger
DROP TRIGGER IF EXISTS trg_buyer_requests_updated_at ON public.buyer_requests;
CREATE TRIGGER trg_buyer_requests_updated_at
    BEFORE UPDATE ON public.buyer_requests
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();


-- ----------------------------------------------------------------------------
-- 3. ORDERS TABLE
-- ----------------------------------------------------------------------------
-- Records marketplace transactions connecting buyers and producers for products.

CREATE TABLE IF NOT EXISTS public.orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    buyer_id UUID NOT NULL REFERENCES public.buyer_profiles(id),
    producer_id UUID NOT NULL REFERENCES public.producer_profiles(id),
    product_id UUID NOT NULL REFERENCES public.products(id),
    buyer_request_id UUID NULL REFERENCES public.buyer_requests(id) ON DELETE SET NULL,
    quantity NUMERIC NOT NULL,
    unit TEXT NOT NULL,
    unit_price NUMERIC(10, 2) NOT NULL,
    total_amount NUMERIC(12, 2) NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending',
    cancel_reason TEXT NULL,
    delivery_state TEXT NULL,
    delivery_district TEXT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT pg_catalog.now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT pg_catalog.now(),
    completed_at TIMESTAMPTZ NULL,
    cancelled_at TIMESTAMPTZ NULL
);

-- Defensive Constraints for orders
DO $$ BEGIN
    ALTER TABLE public.orders
        ADD CONSTRAINT chk_orders_quantity_positive
            CHECK (quantity > 0);
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    ALTER TABLE public.orders
        ADD CONSTRAINT chk_orders_unit_price_non_negative
            CHECK (unit_price >= 0);
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    ALTER TABLE public.orders
        ADD CONSTRAINT chk_orders_total_amount_non_negative
            CHECK (total_amount >= 0);
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    ALTER TABLE public.orders
        ADD CONSTRAINT chk_orders_unit_not_empty
            CHECK (pg_catalog.length(pg_catalog.btrim(unit)) > 0);
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    ALTER TABLE public.orders
        ADD CONSTRAINT chk_orders_status
            CHECK (status IN ('pending', 'confirmed', 'completed', 'cancelled'));
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    ALTER TABLE public.orders
        ADD CONSTRAINT chk_orders_completed_lifecycle
            CHECK (status = 'completed' OR completed_at IS NULL);
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    ALTER TABLE public.orders
        ADD CONSTRAINT chk_orders_cancelled_lifecycle
            CHECK (status = 'cancelled' OR (cancelled_at IS NULL AND cancel_reason IS NULL));
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Indexes for orders
CREATE INDEX IF NOT EXISTS idx_orders_buyer_id
    ON public.orders(buyer_id);

CREATE INDEX IF NOT EXISTS idx_orders_producer_id
    ON public.orders(producer_id);

CREATE INDEX IF NOT EXISTS idx_orders_product_id
    ON public.orders(product_id);

CREATE INDEX IF NOT EXISTS idx_orders_buyer_request_id
    ON public.orders(buyer_request_id);

CREATE INDEX IF NOT EXISTS idx_orders_status
    ON public.orders(status);

CREATE INDEX IF NOT EXISTS idx_orders_created_at
    ON public.orders(created_at DESC);

-- Automated updated_at trigger
DROP TRIGGER IF EXISTS trg_orders_updated_at ON public.orders;
CREATE TRIGGER trg_orders_updated_at
    BEFORE UPDATE ON public.orders
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();


-- ----------------------------------------------------------------------------
-- 4. ROW LEVEL SECURITY (RLS)
-- ----------------------------------------------------------------------------
ALTER TABLE public.buyer_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.buyer_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if rerun
DROP POLICY IF EXISTS "buyer_profiles_select_own" ON public.buyer_profiles;
DROP POLICY IF EXISTS "buyer_profiles_insert_own" ON public.buyer_profiles;
DROP POLICY IF EXISTS "buyer_profiles_update_own" ON public.buyer_profiles;

DROP POLICY IF EXISTS "buyer_requests_select_buyer_own" ON public.buyer_requests;
DROP POLICY IF EXISTS "buyer_requests_select_active_producers" ON public.buyer_requests;
DROP POLICY IF EXISTS "buyer_requests_insert_buyer_own" ON public.buyer_requests;
DROP POLICY IF EXISTS "buyer_requests_update_buyer_own" ON public.buyer_requests;
DROP POLICY IF EXISTS "buyer_requests_delete_buyer_own" ON public.buyer_requests;

DROP POLICY IF EXISTS "orders_select_buyer_own" ON public.orders;
DROP POLICY IF EXISTS "orders_select_producer_own" ON public.orders;
DROP POLICY IF EXISTS "orders_insert_buyer_own" ON public.orders;
DROP POLICY IF EXISTS "orders_update_producer_own" ON public.orders;

-- 4A. BUYER PROFILES POLICIES
-- Authenticated buyers can only read and manage their own profile row.
-- Synthetic buyers without auth_user_id cannot be queried directly by clients.
CREATE POLICY "buyer_profiles_select_own"
    ON public.buyer_profiles
    FOR SELECT
    TO authenticated
    USING (auth.uid() = auth_user_id);

CREATE POLICY "buyer_profiles_insert_own"
    ON public.buyer_profiles
    FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = auth_user_id);

CREATE POLICY "buyer_profiles_update_own"
    ON public.buyer_profiles
    FOR UPDATE
    TO authenticated
    USING (auth.uid() = auth_user_id)
    WITH CHECK (auth.uid() = auth_user_id);

-- 4B. BUYER REQUESTS POLICIES
-- Authenticated buyers manage their own requests.
CREATE POLICY "buyer_requests_select_buyer_own"
    ON public.buyer_requests
    FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.buyer_profiles bp
            WHERE bp.id = buyer_requests.buyer_id
              AND bp.auth_user_id = auth.uid()
        )
    );

-- Authenticated verified producers can discover active requests for marketplace supply / BI.
CREATE POLICY "buyer_requests_select_active_producers"
    ON public.buyer_requests
    FOR SELECT
    TO authenticated
    USING (
        status = 'active'
        AND EXISTS (
            SELECT 1 FROM public.producer_profiles pp
            WHERE pp.id = auth.uid()
        )
    );

CREATE POLICY "buyer_requests_insert_buyer_own"
    ON public.buyer_requests
    FOR INSERT
    TO authenticated
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.buyer_profiles bp
            WHERE bp.id = buyer_requests.buyer_id
              AND bp.auth_user_id = auth.uid()
        )
    );

CREATE POLICY "buyer_requests_update_buyer_own"
    ON public.buyer_requests
    FOR UPDATE
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.buyer_profiles bp
            WHERE bp.id = buyer_requests.buyer_id
              AND bp.auth_user_id = auth.uid()
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.buyer_profiles bp
            WHERE bp.id = buyer_requests.buyer_id
              AND bp.auth_user_id = auth.uid()
        )
    );

CREATE POLICY "buyer_requests_delete_buyer_own"
    ON public.buyer_requests
    FOR DELETE
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.buyer_profiles bp
            WHERE bp.id = buyer_requests.buyer_id
              AND bp.auth_user_id = auth.uid()
        )
    );

-- 4C. ORDERS POLICIES
-- Buyers can read their own placed orders.
CREATE POLICY "orders_select_buyer_own"
    ON public.orders
    FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.buyer_profiles bp
            WHERE bp.id = orders.buyer_id
              AND bp.auth_user_id = auth.uid()
        )
    );

-- Buyers can place (insert) orders associated with their buyer profile.
CREATE POLICY "orders_insert_buyer_own"
    ON public.orders
    FOR INSERT
    TO authenticated
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.buyer_profiles bp
            WHERE bp.id = orders.buyer_id
              AND bp.auth_user_id = auth.uid()
        )
    );

-- Producers can read orders placed with them.
CREATE POLICY "orders_select_producer_own"
    ON public.orders
    FOR SELECT
    TO authenticated
    USING (producer_id = auth.uid());

-- Producers can update order lifecycle (confirm, fulfill, cancel) for their own orders.
CREATE POLICY "orders_update_producer_own"
    ON public.orders
    FOR UPDATE
    TO authenticated
    USING (producer_id = auth.uid())
    WITH CHECK (producer_id = auth.uid());


-- ----------------------------------------------------------------------------
-- 5. PRIVILEGE WHITELIST
-- ----------------------------------------------------------------------------
REVOKE ALL ON TABLE public.buyer_profiles FROM anon, authenticated, PUBLIC;
REVOKE ALL ON TABLE public.buyer_requests FROM anon, authenticated, PUBLIC;
REVOKE ALL ON TABLE public.orders FROM anon, authenticated, PUBLIC;

GRANT SELECT, INSERT, UPDATE ON TABLE public.buyer_profiles TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.buyer_requests TO authenticated;
GRANT SELECT, INSERT, UPDATE ON TABLE public.orders TO authenticated;
