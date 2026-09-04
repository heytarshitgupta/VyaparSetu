-- ============================================================================
-- 011_fix_product_image_ownership_policy.sql
-- Module: VyaparSetu Product Image Storage Ownership Policy Fix (Step 6C.3A)
-- Description: Resolves the cross-schema table RLS failure on storage.objects
--              by introducing a hardened, non-exposed SECURITY DEFINER helper
--              (private.producer_owns_product) and updating the Storage RLS
--              policies for the private 'product-images' bucket.
--
-- Security Guarantees & Architectural Boundaries:
-- 1. Double Ownership Preserved:
--    Storage operations (INSERT, SELECT, DELETE) strictly enforce:
--    A. First folder segment = auth.uid()::text (caller's own user folder).
--    B. Second folder segment = owned product verified via private.producer_owns_product.
-- 2. Hardened SECURITY DEFINER Helper:
--    - Lives in isolated 'private' schema (never exposed to PostgREST API).
--    - Derives caller identity strictly via auth.uid(); caller cannot supply arbitrary user IDs.
--    - Pins search_path = '' to prevent search-path injection.
--    - Uses safe text comparison (p.id::text = product_id_text) preventing 22P02 UUID syntax crashes.
--    - Returns strictly boolean (no product data exposed).
--    - Explicitly revokes EXECUTE from PUBLIC and anon; grants EXECUTE and USAGE only to authenticated.
-- 3. RLS Decoupling:
--    Avoids the nested RLS permission barrier between Supabase Storage engine
--    (supabase_storage_admin) and public.products table RLS while strictly verifying
--    that the product belongs to the authenticated caller (p.producer_id = auth.uid()).
-- 4. Delete-Lifecycle Notice:
--    Because storage DELETE requires an existing owned product, image cleanup
--    must be invoked prior to deleting the public.products database record.
-- 5. No Schema / Bucket Alteration:
--    Leaves public.products, public.producer_profiles, and storage.buckets intact.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. ISOLATED PRIVATE SCHEMA
-- ----------------------------------------------------------------------------
CREATE SCHEMA IF NOT EXISTS private;

-- Grant minimal USAGE to authenticated role so RLS policies can invoke helper
REVOKE ALL ON SCHEMA private FROM PUBLIC, anon;
GRANT USAGE ON SCHEMA private TO authenticated;

-- ----------------------------------------------------------------------------
-- 2. HARDENED SECURITY DEFINER PRODUCT OWNERSHIP HELPER
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION private.producer_owns_product(p_product_id_text text)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
SET search_path = ''
AS $$
DECLARE
    v_owns boolean;
BEGIN
    -- Caller must be authenticated
    IF auth.uid() IS NULL OR p_product_id_text IS NULL THEN
        RETURN false;
    END IF;

    -- Query public.products strictly scoped to the authenticated caller's identity.
    -- Safe text comparison avoids 22P02 invalid UUID syntax errors on malformed paths.
    SELECT EXISTS (
        SELECT 1
        FROM public.products p
        WHERE p.id::text = p_product_id_text
          AND p.producer_id = auth.uid()
    ) INTO v_owns;

    RETURN COALESCE(v_owns, false);
END;
$$;

-- Revoke all default privileges and permit execution exclusively to authenticated
REVOKE ALL ON FUNCTION private.producer_owns_product(text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION private.producer_owns_product(text) TO authenticated;

-- ----------------------------------------------------------------------------
-- 3. REVISE STORAGE RLS POLICIES (storage.objects)
-- ----------------------------------------------------------------------------

-- Drop Migration 010 policies to replace with helper-backed versions
DROP POLICY IF EXISTS "product_images_insert_own" ON storage.objects;
DROP POLICY IF EXISTS "product_images_select_own" ON storage.objects;
DROP POLICY IF EXISTS "product_images_delete_own" ON storage.objects;

-- A. Producer INSERT: Authenticated producer can only upload into their own
--    user folder for an authentically owned product.
CREATE POLICY "product_images_insert_own"
    ON storage.objects
    FOR INSERT
    TO authenticated
    WITH CHECK (
        bucket_id = 'product-images'
        AND pg_catalog.array_length(storage.foldername(name), 1) = 2
        AND (storage.foldername(name))[1] = (auth.uid())::text
        AND private.producer_owns_product((storage.foldername(name))[2])
    );

-- B. Producer SELECT: Authenticated producer can only read/download images from
--    their own product folders. No public or Buyer read permitted.
CREATE POLICY "product_images_select_own"
    ON storage.objects
    FOR SELECT
    TO authenticated
    USING (
        bucket_id = 'product-images'
        AND pg_catalog.array_length(storage.foldername(name), 1) = 2
        AND (storage.foldername(name))[1] = (auth.uid())::text
        AND private.producer_owns_product((storage.foldername(name))[2])
    );

-- C. Producer DELETE: Authenticated producer can only delete images from
--    their own product folders. Cross-user deletion is blocked.
CREATE POLICY "product_images_delete_own"
    ON storage.objects
    FOR DELETE
    TO authenticated
    USING (
        bucket_id = 'product-images'
        AND pg_catalog.array_length(storage.foldername(name), 1) = 2
        AND (storage.foldername(name))[1] = (auth.uid())::text
        AND private.producer_owns_product((storage.foldername(name))[2])
    );
