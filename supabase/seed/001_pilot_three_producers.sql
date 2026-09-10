-- ============================================================================
-- 001_pilot_three_producers.sql
-- Module: VyaparSetu Pilot Catalog Seed (Development & Testing)
-- Description: Deterministically cleans old test products and seeds 15
--              presentation-quality products across the 3 target Producer accounts:
--              1. additionalservices.dev@gmail.com (Punjab Phulkari Works - 5 items)
--              2. guptatarshit00@gmail.com (Ramanujan Handlooms - 5 items)
--              3. guptatarshit30@gmail.com (Ramesh Kheti Baadi - 5 items)
--
-- Safety Guarantees:
-- 1. Scoped Deletion: Deletes products ONLY belonging to the 3 target emails.
--    Products belonging to all other producers remain completely untouched.
-- 2. Existence Assertion: Fails safely before modifying anything if any of
--    the 3 auth accounts or their producer_profiles records do not exist.
-- 3. Atomic Transaction: Wrapped in BEGIN ... COMMIT.
-- 4. Preserves Verification & Auth: Does NOT touch verification fields,
--    passwords, sessions, or user metadata.
-- 5. No Hardcoded Product IDs: Uses PostgreSQL gen_random_uuid() for IDs.
-- ============================================================================

BEGIN;

DO $$
DECLARE
    v_producer_1_id UUID;
    v_producer_2_id UUID;
    v_producer_3_id UUID;
    v_missing_auth TEXT := '';
    v_missing_profiles TEXT := '';
    v_deleted_count INTEGER := 0;
BEGIN
    -- ------------------------------------------------------------------------
    -- 1. RESOLVE PRODUCER UUIDS FROM auth.users
    -- ------------------------------------------------------------------------
    SELECT id INTO v_producer_1_id
    FROM auth.users
    WHERE email = 'additionalservices.dev@gmail.com';

    SELECT id INTO v_producer_2_id
    FROM auth.users
    WHERE email = 'guptatarshit00@gmail.com';

    SELECT id INTO v_producer_3_id
    FROM auth.users
    WHERE email = 'guptatarshit30@gmail.com';

    -- ------------------------------------------------------------------------
    -- 2. ASSERTION: ALL 3 AUTH ACCOUNTS MUST EXIST
    -- ------------------------------------------------------------------------
    IF v_producer_1_id IS NULL THEN
        v_missing_auth := v_missing_auth || 'additionalservices.dev@gmail.com; ';
    END IF;
    IF v_producer_2_id IS NULL THEN
        v_missing_auth := v_missing_auth || 'guptatarshit00@gmail.com; ';
    END IF;
    IF v_producer_3_id IS NULL THEN
        v_missing_auth := v_missing_auth || 'guptatarshit30@gmail.com; ';
    END IF;

    IF v_missing_auth <> '' THEN
        RAISE EXCEPTION 'ABORTING SEED: The following target auth.users accounts were not found: % Please ensure all 3 users are registered in Supabase Auth before running this seed script.', v_missing_auth;
    END IF;

    -- ------------------------------------------------------------------------
    -- 3. ASSERTION: ALL 3 PRODUCER PROFILES MUST EXIST
    -- ------------------------------------------------------------------------
    IF NOT EXISTS (SELECT 1 FROM public.producer_profiles WHERE id = v_producer_1_id) THEN
        v_missing_profiles := v_missing_profiles || 'additionalservices.dev@gmail.com (id: ' || v_producer_1_id || '); ';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM public.producer_profiles WHERE id = v_producer_2_id) THEN
        v_missing_profiles := v_missing_profiles || 'guptatarshit00@gmail.com (id: ' || v_producer_2_id || '); ';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM public.producer_profiles WHERE id = v_producer_3_id) THEN
        v_missing_profiles := v_missing_profiles || 'guptatarshit30@gmail.com (id: ' || v_producer_3_id || '); ';
    END IF;

    IF v_missing_profiles <> '' THEN
        RAISE EXCEPTION 'ABORTING SEED: The following producer_profiles rows were not found: % Please ensure producer profiles are initialized.', v_missing_profiles;
    END IF;

    -- ------------------------------------------------------------------------
    -- 4. SCOPED CLEANUP OF OLD PRODUCTS
    -- ------------------------------------------------------------------------
    -- Deletes ONLY products belonging to these 3 producers.
    -- All other producers and other database tables remain untouched.
    WITH deleted_rows AS (
        DELETE FROM public.products
        WHERE producer_id IN (v_producer_1_id, v_producer_2_id, v_producer_3_id)
        RETURNING id
    )
    SELECT COUNT(*) INTO v_deleted_count FROM deleted_rows;

    RAISE NOTICE 'Removed % old product(s) across the 3 target producers.', v_deleted_count;

    -- ------------------------------------------------------------------------
    -- 5. INSERT CLEAN PILOT CATALOGUE (15 PRODUCTS)
    -- ------------------------------------------------------------------------

    -- ========================================================================
    -- PRODUCER 1: additionalservices.dev@gmail.com (Punjab Phulkari Works)
    -- Focus: Punjabi Artisan Textiles / Clothing
    -- ========================================================================
    INSERT INTO public.products (
        id, producer_id, name, description, category, price, unit, images, status
    ) VALUES
    (
        gen_random_uuid(),
        v_producer_1_id,
        'Hand Embroidered Phulkari Dupatta',
        'Traditional geometric floral embroidery on pure Chanderi silk fabric with resham thread work and scalloped borders.',
        'clothing',
        1850.00,
        'piece',
        '{}'::TEXT[],
        'active'::public.product_status
    ),
    (
        gen_random_uuid(),
        v_producer_1_id,
        'Phulkari Cushion Cover Pair',
        'Set of two matching handcrafted cotton cushion covers featuring geometric Patiala embroidery patterns with zipper enclosure.',
        'home',
        650.00,
        'pack',
        '{}'::TEXT[],
        'active'::public.product_status
    ),
    (
        gen_random_uuid(),
        v_producer_1_id,
        'Punjabi Embroidered Tote Bag',
        'Durable canvas tote bag with hand-embroidered Phulkari front panel, twin shoulder handles, and inner pocket.',
        'clothing',
        480.00,
        'piece',
        '{}'::TEXT[],
        'active'::public.product_status
    ),
    (
        gen_random_uuid(),
        v_producer_1_id,
        'Handcrafted Phulkari Stole',
        'Lightweight cotton-silk stole with dense multicolor needlework motifs, suitable for daily and festive wear.',
        'clothing',
        1200.00,
        'piece',
        '{}'::TEXT[],
        'active'::public.product_status
    ),
    (
        gen_random_uuid(),
        v_producer_1_id,
        'Traditional Fabric Potli Bag',
        'Handcrafted festive drawstring potli bag with bead accents and vibrant floral thread embroidery.',
        'clothing',
        350.00,
        'piece',
        '{}'::TEXT[],
        'active'::public.product_status
    );

    -- ========================================================================
    -- PRODUCER 2: guptatarshit00@gmail.com (Ramanujan Handlooms)
    -- Focus: Handloom & Artisan Utility Products
    -- ========================================================================
    INSERT INTO public.products (
        id, producer_id, name, description, category, price, unit, images, status
    ) VALUES
    (
        gen_random_uuid(),
        v_producer_2_id,
        'Handwoven Cotton Table Runner',
        'Thick loom-woven cotton table runner with woven border motifs and natural fringe ends for dining tables.',
        'home',
        520.00,
        'piece',
        '{}'::TEXT[],
        'active'::public.product_status
    ),
    (
        gen_random_uuid(),
        v_producer_2_id,
        'Handloom Kitchen Towel Set',
        'Pack of four highly absorbent waffle-weave pure cotton kitchen cleaning and drying towels.',
        'home',
        380.00,
        'pack',
        '{}'::TEXT[],
        'active'::public.product_status
    ),
    (
        gen_random_uuid(),
        v_producer_2_id,
        'Woven Storage Basket',
        'Multipurpose sturdy storage basket handwoven with natural moonj grass and cotton yarn handles.',
        'handicraft',
        750.00,
        'piece',
        '{}'::TEXT[],
        'active'::public.product_status
    ),
    (
        gen_random_uuid(),
        v_producer_2_id,
        'Handmade Decorative Wall Hanging',
        'Artisan wall tapestry woven with unbleached cotton cord and wooden rod mount for living room decor.',
        'handicraft',
        890.00,
        'piece',
        '{}'::TEXT[],
        'active'::public.product_status
    ),
    (
        gen_random_uuid(),
        v_producer_2_id,
        'Handcrafted Cotton Floor Mat',
        'Reversible woven cotton floor rug (durrie) with striped geometric weave, durable for high-traffic entryways.',
        'home',
        420.00,
        'piece',
        '{}'::TEXT[],
        'active'::public.product_status
    );

    -- ========================================================================
    -- PRODUCER 3: guptatarshit30@gmail.com (Ramesh Kheti Baadi)
    -- Focus: Farm & Homemade Food Products
    -- ========================================================================
    INSERT INTO public.products (
        id, producer_id, name, description, category, price, unit, images, status
    ) VALUES
    (
        gen_random_uuid(),
        v_producer_3_id,
        'Cold Pressed Mustard Oil',
        'Pure kachi ghani mustard oil traditionally extracted from locally harvested mustard seeds with pungent aroma.',
        'food',
        210.00,
        'litre',
        '{}'::TEXT[],
        'active'::public.product_status
    ),
    (
        gen_random_uuid(),
        v_producer_3_id,
        'Punjabi Jaggery Blocks',
        'Naturally boiled sugarcane jaggery (gur) set into traditional solid blocks with earthy caramel sweetness.',
        'food',
        95.00,
        'kg',
        '{}'::TEXT[],
        'active'::public.product_status
    ),
    (
        gen_random_uuid(),
        v_producer_3_id,
        'Farm Fresh Turmeric Powder',
        'Sun-dried and slow-ground whole turmeric root powder rich in natural curcumin with deep yellow color.',
        'food',
        160.00,
        'pack',
        '{}'::TEXT[],
        'active'::public.product_status
    ),
    (
        gen_random_uuid(),
        v_producer_3_id,
        'Traditional Wheat Flour',
        'Stone-ground whole wheat chakki atta from premium Punjab wheat retaining wholesome bran and fiber.',
        'food',
        340.00,
        'pack',
        '{}'::TEXT[],
        'active'::public.product_status
    ),
    (
        gen_random_uuid(),
        v_producer_3_id,
        'Sun-Dried Red Chilli Pack',
        'Whole stemless red chillies sun-dried on open farm mats, offering rich color and medium heat.',
        'food',
        140.00,
        'pack',
        '{}'::TEXT[],
        'active'::public.product_status
    );

    RAISE NOTICE 'Successfully seeded 15 clean pilot products across the 3 target producers.';
END $$;

COMMIT;
