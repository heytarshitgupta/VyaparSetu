-- ============================================================================
-- 009_create_products_schema.sql
-- Module: VyaparSetu Products Database Foundation (Step 6B.1)
-- Description: Creates canonical public.products table, product_status enum,
--              defensive lifecycle & pricing constraints, index foundation,
--              automated updated_at trigger, and strict owner-only RLS policies.
--
-- Security Guarantees & Architectural Boundaries:
-- 1. Producer Identity: producer_id references public.producer_profiles(id),
--    which strictly equals auth.users(id). Enforces that only registered
--    producers can own products.
-- 2. Owner-Only RLS: For Step 6B, SELECT, INSERT, UPDATE, and DELETE are strictly
--    scoped to auth.uid() = producer_id.
-- 3. Buyer Boundary: Active products are NOT generally readable yet. Public/Buyer
--    marketplace discovery will be introduced in a future dedicated migration.
-- 4. Storage Boundary: No Storage bucket is created in this step. The images
--    array stores forward-compatible relative paths or references, defaulting
--    to an empty array '{}'. Real storage bucket policies will follow in Step 6C.
-- 5. Lifecycle Rules: Exactly three states ('draft', 'active', 'hidden').
--    No premature moderation statuses ('under_review', 'needs_changes', etc.).
-- 6. Price Constraint: NUMERIC(12, 2) in INR. Price may be NULL for drafts,
--    must be strictly positive (> 0) if provided, and is mandatory for 'active'.
-- 7. Multilingual Text Preservation: Stores original Unicode strings for name,
--    description, category, and unit without forced translation overwrite.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. CUSTOM ENUM FOR PRODUCT LIFECYCLE
-- ----------------------------------------------------------------------------
DO $$ BEGIN
    CREATE TYPE public.product_status AS ENUM (
        'draft',
        'active',
        'hidden'
    );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- ----------------------------------------------------------------------------
-- 2. PRODUCTS TABLE
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    producer_id UUID NOT NULL REFERENCES public.producer_profiles(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT NOT NULL DEFAULT '',
    category TEXT NOT NULL DEFAULT '',
    price NUMERIC(12, 2),
    unit VARCHAR(50) NOT NULL DEFAULT 'piece',
    images TEXT[] NOT NULL DEFAULT '{}',
    status public.product_status NOT NULL DEFAULT 'draft',
    created_at TIMESTAMPTZ NOT NULL DEFAULT pg_catalog.now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT pg_catalog.now()
);

-- ----------------------------------------------------------------------------
-- 3. DEFENSIVE CHECK CONSTRAINTS
-- ----------------------------------------------------------------------------

-- A. Product name cannot be empty or purely whitespace
DO $$ BEGIN
    ALTER TABLE public.products
        ADD CONSTRAINT chk_products_name_not_empty
            CHECK (pg_catalog.length(pg_catalog.btrim(name)) > 0);
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- B. Price must be strictly positive (> 0) whenever provided
DO $$ BEGIN
    ALTER TABLE public.products
        ADD CONSTRAINT chk_products_price_positive
            CHECK (price IS NULL OR price > 0);
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- C. Active products MUST have a valid positive price
DO $$ BEGIN
    ALTER TABLE public.products
        ADD CONSTRAINT chk_products_active_requires_price
            CHECK (status <> 'active' OR (price IS NOT NULL AND price > 0));
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- D. Active products MUST have a substantial name (at least 2 characters)
DO $$ BEGIN
    ALTER TABLE public.products
        ADD CONSTRAINT chk_products_active_requires_name
            CHECK (status <> 'active' OR pg_catalog.length(pg_catalog.btrim(name)) >= 2);
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- E. Active products MUST have a category (at least 2 characters)
DO $$ BEGIN
    ALTER TABLE public.products
        ADD CONSTRAINT chk_products_active_requires_category
            CHECK (status <> 'active' OR pg_catalog.length(pg_catalog.btrim(category)) >= 2);
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- ----------------------------------------------------------------------------
-- 4. AUTOMATED UPDATED_AT TRIGGER
-- ----------------------------------------------------------------------------
-- Reuses existing public.handle_updated_at() trigger function from Migration 001.
DROP TRIGGER IF EXISTS trg_products_updated_at ON public.products;
CREATE TRIGGER trg_products_updated_at
    BEFORE UPDATE ON public.products
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

-- ----------------------------------------------------------------------------
-- 5. PERFORMANCE INDEXES
-- ----------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_products_producer_id
    ON public.products(producer_id);

CREATE INDEX IF NOT EXISTS idx_products_producer_status
    ON public.products(producer_id, status);

CREATE INDEX IF NOT EXISTS idx_products_created_at
    ON public.products(created_at DESC);

-- ----------------------------------------------------------------------------
-- 6. ROW LEVEL SECURITY (RLS) - OWNER ONLY FOR STEP 6B
-- ----------------------------------------------------------------------------
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if rerun
DROP POLICY IF EXISTS "products_select_own" ON public.products;
DROP POLICY IF EXISTS "products_insert_own" ON public.products;
DROP POLICY IF EXISTS "products_update_own" ON public.products;
DROP POLICY IF EXISTS "products_delete_own" ON public.products;

-- A. Producer SELECT: Can only read their own products
CREATE POLICY "products_select_own"
    ON public.products
    FOR SELECT
    TO authenticated
    USING (auth.uid() = producer_id);

-- B. Producer INSERT: Can only create products for themselves
CREATE POLICY "products_insert_own"
    ON public.products
    FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = producer_id);

-- C. Producer UPDATE: Can only modify their own products
CREATE POLICY "products_update_own"
    ON public.products
    FOR UPDATE
    TO authenticated
    USING (auth.uid() = producer_id)
    WITH CHECK (auth.uid() = producer_id);

-- D. Producer DELETE: Can only delete their own products (Hard DELETE)
CREATE POLICY "products_delete_own"
    ON public.products
    FOR DELETE
    TO authenticated
    USING (auth.uid() = producer_id);

-- ----------------------------------------------------------------------------
-- 7. PRIVILEGE WHITELIST
-- ----------------------------------------------------------------------------
REVOKE ALL ON TABLE public.products FROM anon, authenticated, PUBLIC;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.products TO authenticated;
