-- ============================================================================
-- 010_create_product_images_storage.sql
-- Module: VyaparSetu Product Image Storage & Security (Step 6C.2)
-- Description: Configures the dedicated private 'product-images' Storage bucket,
--              enforces strict 5 MB file-size and image MIME type constraints,
--              and establishes owner-scoped Storage RLS policies for authenticated
--              producers on storage.objects.
--
-- Security Guarantees & Architectural Boundaries:
-- 1. Private Bucket: 'product-images' is strictly private (public = false).
--    No anonymous access, no public URL exposure, and no Buyer marketplace read
--    access yet (Buyer discovery remains deferred to a future dedicated migration).
-- 2. Strict Path Contract:
--    All uploaded objects must follow the exact 3-segment folder hierarchy:
--    <producer_user_uuid>/<product_uuid>/<generated_filename>
-- 3. Double-Ownership RLS Verification:
--    Every Storage operation (INSERT, SELECT, DELETE) strictly verifies BOTH:
--    A. First folder segment matches the authenticated caller: (storage.foldername(name))[1] = auth.uid()::text
--    B. Second folder segment matches an existing product row owned by the same producer:
--       EXISTS (SELECT 1 FROM public.products p WHERE p.id::text = (storage.foldername(name))[2] AND p.producer_id = auth.uid())
-- 4. Safe UUID Evaluation:
--    Product ID comparison casts products.id::text to match the path segment text,
--    preventing PostgreSQL 22P02 invalid UUID syntax errors on malformed paths.
-- 5. No UPDATE/Upsert Policy:
--    In-place object mutation is disallowed. Image replacement operates via
--    new object insertion followed by cleanup of the superseded object.
-- 6. No Schema Alteration:
--    Leaves public.products, public.producer_profiles, and migration 009 untouched.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. PRODUCT IMAGES STORAGE BUCKET CONFIGURATION
-- ----------------------------------------------------------------------------
-- Creates or updates the private 'product-images' bucket with 5 MB file size
-- limit and allowed image MIME types.
INSERT INTO storage.buckets (
    id,
    name,
    public,
    file_size_limit,
    allowed_mime_types
)
VALUES (
    'product-images',
    'product-images',
    false,
    5242880, -- 5 MB in bytes
    ARRAY['image/jpeg', 'image/png', 'image/webp']::text[]
)
ON CONFLICT (id) DO UPDATE SET
    public = false,
    file_size_limit = 5242880,
    allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/webp']::text[];

-- ----------------------------------------------------------------------------
-- 2. STORAGE ROW LEVEL SECURITY POLICIES (storage.objects)
-- ----------------------------------------------------------------------------
-- Note: RLS is already permanently enabled on storage.objects by Supabase.
-- Attempting 'ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY' fails with
-- 42501 (must be owner of table objects) because storage.objects is owned by
-- supabase_storage_admin.

-- Drop existing policies if re-applying
DROP POLICY IF EXISTS "product_images_insert_own" ON storage.objects;
DROP POLICY IF EXISTS "product_images_select_own" ON storage.objects;
DROP POLICY IF EXISTS "product_images_delete_own" ON storage.objects;

-- A. Producer INSERT: Authenticated producer can only upload into their own
--    folder for a product they authentically own in public.products.
CREATE POLICY "product_images_insert_own"
    ON storage.objects
    FOR INSERT
    TO authenticated
    WITH CHECK (
        bucket_id = 'product-images'
        AND pg_catalog.array_length(storage.foldername(name), 1) = 2
        AND (storage.foldername(name))[1] = (auth.uid())::text
        AND EXISTS (
            SELECT 1
            FROM public.products p
            WHERE p.id::text = (storage.foldername(name))[2]
              AND p.producer_id = auth.uid()
        )
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
        AND EXISTS (
            SELECT 1
            FROM public.products p
            WHERE p.id::text = (storage.foldername(name))[2]
              AND p.producer_id = auth.uid()
        )
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
        AND EXISTS (
            SELECT 1
            FROM public.products p
            WHERE p.id::text = (storage.foldername(name))[2]
              AND p.producer_id = auth.uid()
        )
    );
