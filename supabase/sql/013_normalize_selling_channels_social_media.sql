-- ============================================================================
-- MIGRATION 013: NORMALIZE SELLING CHANNELS TO CANONICAL 'social_media'
-- ============================================================================
-- Description:
--   Executed Migration 012 originally allowed 'instagram_facebook' in the
--   chk_producer_selling_channels_valid CHECK constraint.
--   Onboarding V2 canonically writes 'social_media' across all app layers.
--
--   Execution Order (Safe Transactional Flow):
--     1. Drop existing chk_producer_selling_channels_valid constraint FIRST.
--        (Crucial: If the UPDATE ran first, PostgreSQL would reject 'social_media'
--        because Migration 012's active CHECK constraint did not allow it).
--     2. Normalize historical 'instagram_facebook' array elements to
--        canonical 'social_media' (deduplicating if both coexisted).
--     3. Recreate chk_producer_selling_channels_valid to strictly allow only
--        the canonical set containing 'social_media'.
--     4. Preserves / verifies chk_producer_selling_channels_no_conflict
--        exclusivity constraint on 'not_selling_yet'.
--
-- Safe & Idempotent: Can be run safely in Supabase SQL Editor.
-- Migration 012 remains immutable and untouched.
-- ============================================================================

BEGIN;

-- ----------------------------------------------------------------------------
-- 1. Drop existing constraint allowing legacy 'instagram_facebook'
--    (Must drop before UPDATE to prevent constraint violation on new value)
-- ----------------------------------------------------------------------------
ALTER TABLE public.producer_profiles
    DROP CONSTRAINT IF EXISTS chk_producer_selling_channels_valid;

-- ----------------------------------------------------------------------------
-- 2. Normalize existing historical array values ('instagram_facebook' -> 'social_media')
--    - Collapses duplicates safely if both values somehow exist (DISTINCT)
--    - Preserves empty arrays and all non-legacy values
--    - Preserves TEXT[] array type
--    - Touches only rows containing 'instagram_facebook'
-- ----------------------------------------------------------------------------
UPDATE public.producer_profiles
SET selling_channels = (
    SELECT COALESCE(array_agg(DISTINCT val ORDER BY val), '{}'::TEXT[])
    FROM (
        SELECT CASE
            WHEN elem = 'instagram_facebook' THEN 'social_media'
            ELSE elem
        END AS val
        FROM unnest(selling_channels) AS elem
    ) sub
)
WHERE 'instagram_facebook' = ANY(selling_channels);

-- ----------------------------------------------------------------------------
-- 3. Recreate constraint with canonical 'social_media'
-- ----------------------------------------------------------------------------
ALTER TABLE public.producer_profiles
    ADD CONSTRAINT chk_producer_selling_channels_valid
        CHECK (selling_channels <@ ARRAY[
            'local_customers',
            'local_shops',
            'whatsapp',
            'social_media',
            'online_marketplaces',
            'exhibitions_fairs',
            'not_selling_yet'
        ]::TEXT[]);

-- ----------------------------------------------------------------------------
-- 4. Defensively ensure 'not_selling_yet' exclusivity constraint is active
-- ----------------------------------------------------------------------------
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_catalog.pg_constraint
        WHERE conname = 'chk_producer_selling_channels_no_conflict'
          AND conrelid = 'public.producer_profiles'::regclass
    ) THEN
        ALTER TABLE public.producer_profiles
            ADD CONSTRAINT chk_producer_selling_channels_no_conflict
                CHECK (
                    NOT ('not_selling_yet' = ANY(selling_channels))
                    OR selling_channels = ARRAY['not_selling_yet']::TEXT[]
                );
    END IF;
END $$;

COMMIT;

-- ============================================================================
-- POST-MIGRATION VERIFICATION QUERIES (Run manually in SQL Editor after execution)
-- ============================================================================
-- A. Check remaining legacy values (Expected: 0 rows):
--    SELECT id, selling_channels
--    FROM public.producer_profiles
--    WHERE 'instagram_facebook' = ANY(selling_channels);
--
-- B. Inspect constraint definitions from pg_constraint:
--    SELECT conname, pg_get_constraintdef(oid)
--    FROM pg_constraint
--    WHERE conname IN ('chk_producer_selling_channels_valid', 'chk_producer_selling_channels_no_conflict')
--      AND conrelid = 'public.producer_profiles'::regclass;
--
-- C. Verify supported values logically:
--    Ensure allowed values are exactly:
--    local_customers, local_shops, whatsapp, social_media,
--    online_marketplaces, exhibitions_fairs, not_selling_yet.
-- ============================================================================
