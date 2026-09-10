-- ============================================================================
-- 002_pilot_buyers_requests_orders.sql
-- Module: VyaparSetu Pilot Marketplace Connected Dataset (Development & Testing)
-- Description: Deterministically creates 12 synthetic buyers, 20 buyer requests,
--              and 28 marketplace orders connected to the 3 real producers
--              and 15 existing products:
--              1. 12 synthetic buyers (auth_user_id = NULL) across Punjab and wider India
--              2. 20 buyer requests with realistic demand curves (10 active, 4 matched, 3 fulfilled, 2 cancelled, 1 expired)
--              3. 28 orders with complete transaction history (18 completed, 3 confirmed, 2 pending, 5 cancelled)
--
-- Safety Guarantees:
-- 1. Scoped Deletion: Deletes ONLY the fixed deterministic demo UUIDs used in this seed.
--    Any unrelated future buyers, requests, or orders are strictly untouched.
-- 2. Dynamic Resolution: Resolves Producer IDs from auth.users and Product IDs
--    dynamically from public.products by producer_id + name. Zero hardcoded product UUIDs.
-- 3. Pre-Condition Assertion: Verifies all 3 producer accounts and all 15 products
--    exist in the database before proceeding; fails safely otherwise.
-- 4. Constraint Compliance: Enforces all Migration 015 CHECK constraints and lifecycle
--    rules (completed_at only on completed orders, cancelled_at only on cancelled).
-- 5. Atomic Transaction: Wrapped in BEGIN ... COMMIT.
-- ============================================================================

BEGIN;

DO $$
DECLARE
    -- Producer UUIDs resolved dynamically
    v_producer_1_id UUID;
    v_producer_2_id UUID;
    v_producer_3_id UUID;

    -- Product UUIDs resolved dynamically
    v_p1_dupatta_id UUID;
    v_p1_cushion_id UUID;
    v_p1_tote_id UUID;
    v_p1_stole_id UUID;
    v_p1_potli_id UUID;

    v_p2_runner_id UUID;
    v_p2_towel_id UUID;
    v_p2_basket_id UUID;
    v_p2_hanging_id UUID;
    v_p2_mat_id UUID;

    v_p3_oil_id UUID;
    v_p3_jaggery_id UUID;
    v_p3_turmeric_id UUID;
    v_p3_flour_id UUID;
    v_p3_chilli_id UUID;

    v_missing_products TEXT := '';
BEGIN
    -- ------------------------------------------------------------------------
    -- 1. RESOLVE PRODUCER UUIDS FROM auth.users
    -- ------------------------------------------------------------------------
    SELECT id INTO v_producer_1_id FROM auth.users WHERE email = 'additionalservices.dev@gmail.com';
    SELECT id INTO v_producer_2_id FROM auth.users WHERE email = 'guptatarshit00@gmail.com';
    SELECT id INTO v_producer_3_id FROM auth.users WHERE email = 'guptatarshit30@gmail.com';

    IF v_producer_1_id IS NULL OR v_producer_2_id IS NULL OR v_producer_3_id IS NULL THEN
        RAISE EXCEPTION 'ABORTING SEED: One or more target Producer auth accounts are missing.';
    END IF;

    -- ------------------------------------------------------------------------
    -- 2. RESOLVE AND ASSERT ALL 15 PRODUCTS EXIST
    -- ------------------------------------------------------------------------
    -- Producer 1 products
    SELECT id INTO v_p1_dupatta_id FROM public.products WHERE producer_id = v_producer_1_id AND name = 'Hand Embroidered Phulkari Dupatta';
    SELECT id INTO v_p1_cushion_id FROM public.products WHERE producer_id = v_producer_1_id AND name = 'Phulkari Cushion Cover Pair';
    SELECT id INTO v_p1_tote_id FROM public.products WHERE producer_id = v_producer_1_id AND name = 'Punjabi Embroidered Tote Bag';
    SELECT id INTO v_p1_stole_id FROM public.products WHERE producer_id = v_producer_1_id AND name = 'Handcrafted Phulkari Stole';
    SELECT id INTO v_p1_potli_id FROM public.products WHERE producer_id = v_producer_1_id AND name = 'Traditional Fabric Potli Bag';

    -- Producer 2 products
    SELECT id INTO v_p2_runner_id FROM public.products WHERE producer_id = v_producer_2_id AND name = 'Handwoven Cotton Table Runner';
    SELECT id INTO v_p2_towel_id FROM public.products WHERE producer_id = v_producer_2_id AND name = 'Handloom Kitchen Towel Set';
    SELECT id INTO v_p2_basket_id FROM public.products WHERE producer_id = v_producer_2_id AND name = 'Woven Storage Basket';
    SELECT id INTO v_p2_hanging_id FROM public.products WHERE producer_id = v_producer_2_id AND name = 'Handmade Decorative Wall Hanging';
    SELECT id INTO v_p2_mat_id FROM public.products WHERE producer_id = v_producer_2_id AND name = 'Handcrafted Cotton Floor Mat';

    -- Producer 3 products
    SELECT id INTO v_p3_oil_id FROM public.products WHERE producer_id = v_producer_3_id AND name = 'Cold Pressed Mustard Oil';
    SELECT id INTO v_p3_jaggery_id FROM public.products WHERE producer_id = v_producer_3_id AND name = 'Punjabi Jaggery Blocks';
    SELECT id INTO v_p3_turmeric_id FROM public.products WHERE producer_id = v_producer_3_id AND name = 'Farm Fresh Turmeric Powder';
    SELECT id INTO v_p3_flour_id FROM public.products WHERE producer_id = v_producer_3_id AND name = 'Traditional Wheat Flour';
    SELECT id INTO v_p3_chilli_id FROM public.products WHERE producer_id = v_producer_3_id AND name = 'Sun-Dried Red Chilli Pack';

    -- Assert completeness
    IF v_p1_dupatta_id IS NULL THEN v_missing_products := v_missing_products || 'P1: Hand Embroidered Phulkari Dupatta; '; END IF;
    IF v_p1_cushion_id IS NULL THEN v_missing_products := v_missing_products || 'P1: Phulkari Cushion Cover Pair; '; END IF;
    IF v_p1_tote_id IS NULL THEN v_missing_products := v_missing_products || 'P1: Punjabi Embroidered Tote Bag; '; END IF;
    IF v_p1_stole_id IS NULL THEN v_missing_products := v_missing_products || 'P1: Handcrafted Phulkari Stole; '; END IF;
    IF v_p1_potli_id IS NULL THEN v_missing_products := v_missing_products || 'P1: Traditional Fabric Potli Bag; '; END IF;

    IF v_p2_runner_id IS NULL THEN v_missing_products := v_missing_products || 'P2: Handwoven Cotton Table Runner; '; END IF;
    IF v_p2_towel_id IS NULL THEN v_missing_products := v_missing_products || 'P2: Handloom Kitchen Towel Set; '; END IF;
    IF v_p2_basket_id IS NULL THEN v_missing_products := v_missing_products || 'P2: Woven Storage Basket; '; END IF;
    IF v_p2_hanging_id IS NULL THEN v_missing_products := v_missing_products || 'P2: Handmade Decorative Wall Hanging; '; END IF;
    IF v_p2_mat_id IS NULL THEN v_missing_products := v_missing_products || 'P2: Handcrafted Cotton Floor Mat; '; END IF;

    IF v_p3_oil_id IS NULL THEN v_missing_products := v_missing_products || 'P3: Cold Pressed Mustard Oil; '; END IF;
    IF v_p3_jaggery_id IS NULL THEN v_missing_products := v_missing_products || 'P3: Punjabi Jaggery Blocks; '; END IF;
    IF v_p3_turmeric_id IS NULL THEN v_missing_products := v_missing_products || 'P3: Farm Fresh Turmeric Powder; '; END IF;
    IF v_p3_flour_id IS NULL THEN v_missing_products := v_missing_products || 'P3: Traditional Wheat Flour; '; END IF;
    IF v_p3_chilli_id IS NULL THEN v_missing_products := v_missing_products || 'P3: Sun-Dried Red Chilli Pack; '; END IF;

    IF v_missing_products <> '' THEN
        RAISE EXCEPTION 'ABORTING SEED: Missing expected product records: % Run 001_pilot_three_producers.sql first.', v_missing_products;
    END IF;

    -- ------------------------------------------------------------------------
    -- 3. SCOPED CLEANUP OF PREVIOUS RUN OF THIS SEED ONLY
    -- ------------------------------------------------------------------------
    DELETE FROM public.orders WHERE id IN (
        '00000000-b003-0000-0000-000000000001', '00000000-b003-0000-0000-000000000002',
        '00000000-b003-0000-0000-000000000003', '00000000-b003-0000-0000-000000000004',
        '00000000-b003-0000-0000-000000000005', '00000000-b003-0000-0000-000000000006',
        '00000000-b003-0000-0000-000000000007', '00000000-b003-0000-0000-000000000008',
        '00000000-b003-0000-0000-000000000009', '00000000-b003-0000-0000-000000000010',
        '00000000-b003-0000-0000-000000000011', '00000000-b003-0000-0000-000000000012',
        '00000000-b003-0000-0000-000000000013', '00000000-b003-0000-0000-000000000014',
        '00000000-b003-0000-0000-000000000015', '00000000-b003-0000-0000-000000000016',
        '00000000-b003-0000-0000-000000000017', '00000000-b003-0000-0000-000000000018',
        '00000000-b003-0000-0000-000000000019', '00000000-b003-0000-0000-000000000020',
        '00000000-b003-0000-0000-000000000021', '00000000-b003-0000-0000-000000000022',
        '00000000-b003-0000-0000-000000000023', '00000000-b003-0000-0000-000000000024',
        '00000000-b003-0000-0000-000000000025', '00000000-b003-0000-0000-000000000026',
        '00000000-b003-0000-0000-000000000027', '00000000-b003-0000-0000-000000000028'
    );

    DELETE FROM public.buyer_requests WHERE id IN (
        '00000000-b002-0000-0000-000000000001', '00000000-b002-0000-0000-000000000002',
        '00000000-b002-0000-0000-000000000003', '00000000-b002-0000-0000-000000000004',
        '00000000-b002-0000-0000-000000000005', '00000000-b002-0000-0000-000000000006',
        '00000000-b002-0000-0000-000000000007', '00000000-b002-0000-0000-000000000008',
        '00000000-b002-0000-0000-000000000009', '00000000-b002-0000-0000-000000000010',
        '00000000-b002-0000-0000-000000000011', '00000000-b002-0000-0000-000000000012',
        '00000000-b002-0000-0000-000000000013', '00000000-b002-0000-0000-000000000014',
        '00000000-b002-0000-0000-000000000015', '00000000-b002-0000-0000-000000000016',
        '00000000-b002-0000-0000-000000000017', '00000000-b002-0000-0000-000000000018',
        '00000000-b002-0000-0000-000000000019', '00000000-b002-0000-0000-000000000020'
    );

    DELETE FROM public.buyer_profiles WHERE id IN (
        '00000000-b001-0000-0000-000000000001', '00000000-b001-0000-0000-000000000002',
        '00000000-b001-0000-0000-000000000003', '00000000-b001-0000-0000-000000000004',
        '00000000-b001-0000-0000-000000000005', '00000000-b001-0000-0000-000000000006',
        '00000000-b001-0000-0000-000000000007', '00000000-b001-0000-0000-000000000008',
        '00000000-b001-0000-0000-000000000009', '00000000-b001-0000-0000-000000000010',
        '00000000-b001-0000-0000-000000000011', '00000000-b001-0000-0000-000000000012'
    );

    -- ------------------------------------------------------------------------
    -- 4. INSERT 12 SYNTHETIC BUYER PROFILES
    -- ------------------------------------------------------------------------
    INSERT INTO public.buyer_profiles (
        id, auth_user_id, display_name, business_name, buyer_type, state, district, city, pincode, created_at
    ) VALUES
    ('00000000-b001-0000-0000-000000000001', NULL, 'Simran Kaur', 'Amritsar Heritage Boutique', 'retailer', 'Punjab', 'Amritsar', 'Amritsar', '143001', pg_catalog.now() - INTERVAL '80 days'),
    ('00000000-b001-0000-0000-000000000002', NULL, 'Harpreet Singh', 'Malwa Handloom Emporium', 'wholesaler', 'Punjab', 'Ludhiana', 'Ludhiana', '141001', pg_catalog.now() - INTERVAL '78 days'),
    ('00000000-b001-0000-0000-000000000003', NULL, 'Rajesh Aggarwal', 'Patiala Kirana Wholesale', 'wholesaler', 'Punjab', 'Patiala', 'Patiala', '147001', pg_catalog.now() - INTERVAL '75 days'),
    ('00000000-b001-0000-0000-000000000004', NULL, 'Manjeet Kaur', 'Sangrur Organic Shoppe', 'retailer', 'Punjab', 'Sangrur', 'Sangrur', '148001', pg_catalog.now() - INTERVAL '70 days'),
    ('00000000-b001-0000-0000-000000000005', NULL, 'Gurmeet Singh Brar', NULL, 'consumer', 'Punjab', 'SAS Nagar', 'Mohali', '160062', pg_catalog.now() - INTERVAL '68 days'),
    ('00000000-b001-0000-0000-000000000006', NULL, 'Ananya Sharma', 'Virasat Living Store', 'retailer', 'Chandigarh', 'Chandigarh', 'Chandigarh', '160017', pg_catalog.now() - INTERVAL '65 days'),
    ('00000000-b001-0000-0000-000000000007', NULL, 'Vikram Malhotra', 'Desi Crafts Collective', 'wholesaler', 'Delhi', 'Central Delhi', 'New Delhi', '110001', pg_catalog.now() - INTERVAL '60 days'),
    ('00000000-b001-0000-0000-000000000008', NULL, 'Sunita Verma', NULL, 'consumer', 'Delhi', 'South Delhi', 'New Delhi', '110019', pg_catalog.now() - INTERVAL '58 days'),
    ('00000000-b001-0000-0000-000000000009', NULL, 'Rajiv Poddar', 'Haveli Home & Textiles', 'retailer', 'Rajasthan', 'Jaipur', 'Jaipur', '302001', pg_catalog.now() - INTERVAL '55 days'),
    ('00000000-b001-0000-0000-000000000010', NULL, 'Neha Kulkarni', 'Gramin Udyog Federation', 'institution', 'Maharashtra', 'Mumbai City', 'Mumbai', '400001', pg_catalog.now() - INTERVAL '50 days'),
    ('00000000-b001-0000-0000-000000000011', NULL, 'Arvind Swaminathan', 'Dakshin Artisan Sourcing', 'institution', 'Karnataka', 'Bengaluru Urban', 'Bengaluru', '560001', pg_catalog.now() - INTERVAL '48 days'),
    ('00000000-b001-0000-0000-000000000012', NULL, 'Priya Nair', NULL, 'consumer', 'Maharashtra', 'Mumbai Suburban', 'Bandra', '400050', pg_catalog.now() - INTERVAL '45 days');

    -- ------------------------------------------------------------------------
    -- 5. INSERT 20 BUYER REQUESTS
    -- ------------------------------------------------------------------------
    INSERT INTO public.buyer_requests (
        id, buyer_id, product_name, category, quantity, unit, target_price, urgency, status, state, district, notes, created_at
    ) VALUES
    -- Active requests (10 items: wide regional demand signals for BI)
    ('00000000-b002-0000-0000-000000000001', '00000000-b001-0000-0000-000000000001', 'Hand Embroidered Phulkari Dupatta', 'clothing', 25, 'piece', 1750.00, 'high', 'active', 'Punjab', 'Amritsar', 'Sourcing festive bridal Phulkari dupattas for boutique showcase', pg_catalog.now() - INTERVAL '14 days'),
    ('00000000-b002-0000-0000-000000000002', '00000000-b001-0000-0000-000000000007', 'Handcrafted Phulkari Stole', 'clothing', 50, 'piece', 1100.00, 'medium', 'active', 'Delhi', 'Central Delhi', 'Autumn festive exhibition collection in Delhi wholesale market', pg_catalog.now() - INTERVAL '12 days'),
    ('00000000-b002-0000-0000-000000000003', '00000000-b001-0000-0000-000000000002', 'Handwoven Cotton Table Runner', 'home', 40, 'piece', 480.00, 'high', 'active', 'Punjab', 'Ludhiana', 'Natural tone cotton runners for home furnishing retail catalog', pg_catalog.now() - INTERVAL '10 days'),
    ('00000000-b002-0000-0000-000000000004', '00000000-b001-0000-0000-000000000006', 'Handloom Kitchen Towel Set', 'home', 60, 'pack', 350.00, 'medium', 'active', 'Chandigarh', 'Chandigarh', 'Absorbent waffle weave cotton towels for boutique kitchen counter', pg_catalog.now() - INTERVAL '9 days'),
    ('00000000-b002-0000-0000-000000000005', '00000000-b001-0000-0000-000000000003', 'Cold Pressed Mustard Oil', 'food', 100, 'litre', 195.00, 'high', 'active', 'Punjab', 'Patiala', 'Bulk supply of cold pressed mustard oil for local retail distribution', pg_catalog.now() - INTERVAL '8 days'),
    ('00000000-b002-0000-0000-000000000006', '00000000-b001-0000-0000-000000000004', 'Punjabi Jaggery Blocks', 'food', 200, 'kg', 85.00, 'medium', 'active', 'Punjab', 'Sangrur', 'Natural sugarcane jaggery blocks needed for winter retail demand', pg_catalog.now() - INTERVAL '7 days'),
    ('00000000-b002-0000-0000-000000000007', '00000000-b001-0000-0000-000000000009', 'Woven Storage Basket', 'handicraft', 30, 'piece', 700.00, 'low', 'active', 'Rajasthan', 'Jaipur', 'Natural moonj grass storage baskets for heritage home decor studio', pg_catalog.now() - INTERVAL '6 days'),
    ('00000000-b002-0000-0000-000000000008', '00000000-b001-0000-0000-000000000010', 'Handmade Decorative Wall Hanging', 'handicraft', 20, 'piece', 820.00, 'low', 'active', 'Maharashtra', 'Mumbai City', 'Artisan woven wall tapestry for cooperative craft exhibition', pg_catalog.now() - INTERVAL '5 days'),
    ('00000000-b002-0000-0000-000000000009', '00000000-b001-0000-0000-000000000008', 'Handcrafted Cotton Floor Mat', 'home', 4, 'piece', 400.00, 'medium', 'active', 'Delhi', 'South Delhi', 'Living room striped geometric cotton durries for residence', pg_catalog.now() - INTERVAL '4 days'),
    ('00000000-b002-0000-0000-000000000010', '00000000-b001-0000-0000-000000000011', 'Farm Fresh Turmeric Powder', 'food', 50, 'pack', 150.00, 'medium', 'active', 'Karnataka', 'Bengaluru Urban', 'Whole turmeric root powder packs for southern organic outlets', pg_catalog.now() - INTERVAL '2 days'),

    -- Matched requests (4 items)
    ('00000000-b002-0000-0000-000000000011', '00000000-b001-0000-0000-000000000001', 'Phulkari Cushion Cover Pair', 'home', 15, 'pack', 620.00, 'high', 'matched', 'Punjab', 'Amritsar', 'Paired cushion covers matching store showcase palette', pg_catalog.now() - INTERVAL '46 days'),
    ('00000000-b002-0000-0000-000000000012', '00000000-b001-0000-0000-000000000002', 'Punjabi Embroidered Tote Bag', 'clothing', 20, 'piece', 450.00, 'medium', 'matched', 'Punjab', 'Ludhiana', 'Artisan embroidered tote bags for urban retail counter', pg_catalog.now() - INTERVAL '51 days'),
    ('00000000-b002-0000-0000-000000000013', '00000000-b001-0000-0000-000000000003', 'Traditional Wheat Flour', 'food', 40, 'pack', 320.00, 'medium', 'matched', 'Punjab', 'Patiala', 'Stone-ground wheat chakki atta packs for retail distribution', pg_catalog.now() - INTERVAL '42 days'),
    ('00000000-b002-0000-0000-000000000014', '00000000-b001-0000-0000-000000000007', 'Handcrafted Cotton Floor Mat', 'home', 25, 'piece', 410.00, 'high', 'matched', 'Delhi', 'Central Delhi', 'Durable reversible cotton durries for Delhi artisan fair', pg_catalog.now() - INTERVAL '36 days'),

    -- Fulfilled requests (3 items)
    ('00000000-b002-0000-0000-000000000015', '00000000-b001-0000-0000-000000000001', 'Hand Embroidered Phulkari Dupatta', 'clothing', 10, 'piece', 1800.00, 'high', 'fulfilled', 'Punjab', 'Amritsar', 'Fulfilled initial batch of silk Phulkari dupattas successfully', pg_catalog.now() - INTERVAL '73 days'),
    ('00000000-b002-0000-0000-000000000016', '00000000-b001-0000-0000-000000000006', 'Handwoven Cotton Table Runner', 'home', 20, 'piece', 500.00, 'high', 'fulfilled', 'Chandigarh', 'Chandigarh', 'Table runner batch fulfilled on schedule for boutique delivery', pg_catalog.now() - INTERVAL '66 days'),
    ('00000000-b002-0000-0000-000000000017', '00000000-b001-0000-0000-000000000004', 'Cold Pressed Mustard Oil', 'food', 50, 'litre', 200.00, 'high', 'fulfilled', 'Punjab', 'Sangrur', 'Initial batch of kachi ghani mustard oil verified and delivered', pg_catalog.now() - INTERVAL '63 days'),

    -- Cancelled requests (2 items)
    ('00000000-b002-0000-0000-000000000018', '00000000-b001-0000-0000-000000000012', 'Traditional Fabric Potli Bag', 'clothing', 15, 'piece', 300.00, 'low', 'cancelled', 'Maharashtra', 'Mumbai Suburban', 'Sourcing cancelled due to change in wedding event dates', pg_catalog.now() - INTERVAL '29 days'),
    ('00000000-b002-0000-0000-000000000019', '00000000-b001-0000-0000-000000000005', 'Sun-Dried Red Chilli Pack', 'food', 10, 'pack', 120.00, 'low', 'cancelled', 'Punjab', 'SAS Nagar', 'Target pricing requirements unviable for producer', pg_catalog.now() - INTERVAL '17 days'),

    -- Expired requests (1 item)
    ('00000000-b002-0000-0000-000000000020', '00000000-b001-0000-0000-000000000010', 'Traditional Fabric Potli Bag', 'clothing', 30, 'piece', 320.00, 'low', 'expired', 'Maharashtra', 'Mumbai City', 'Sourcing request window expired past regional exhibition deadline', pg_catalog.now() - INTERVAL '50 days');

    -- ------------------------------------------------------------------------
    -- 6. INSERT 28 MARKETPLACE ORDERS
    -- ------------------------------------------------------------------------
    -- (18 completed, 3 confirmed, 2 pending, 5 cancelled)

    -- PRODUCER 1 (additionalservices.dev@gmail.com - Punjab Phulkari Works)
    -- Order 1 (completed, linked to req 15)
    INSERT INTO public.orders (
        id, buyer_id, producer_id, product_id, buyer_request_id, quantity, unit, unit_price, total_amount, status, delivery_state, delivery_district, created_at, completed_at
    ) VALUES (
        '00000000-b003-0000-0000-000000000001', '00000000-b001-0000-0000-000000000001', v_producer_1_id, v_p1_dupatta_id, '00000000-b002-0000-0000-000000000015',
        10, 'piece', 1800.00, 18000.00, 'completed', 'Punjab', 'Amritsar', pg_catalog.now() - INTERVAL '72 days', pg_catalog.now() - INTERVAL '67 days'
    );

    -- Order 2 (completed, direct)
    INSERT INTO public.orders (
        id, buyer_id, producer_id, product_id, buyer_request_id, quantity, unit, unit_price, total_amount, status, delivery_state, delivery_district, created_at, completed_at
    ) VALUES (
        '00000000-b003-0000-0000-000000000002', '00000000-b001-0000-0000-000000000007', v_producer_1_id, v_p1_dupatta_id, NULL,
        8, 'piece', 1820.00, 14560.00, 'completed', 'Delhi', 'Central Delhi', pg_catalog.now() - INTERVAL '58 days', pg_catalog.now() - INTERVAL '53 days'
    );

    -- Order 3 (completed, direct)
    INSERT INTO public.orders (
        id, buyer_id, producer_id, product_id, buyer_request_id, quantity, unit, unit_price, total_amount, status, delivery_state, delivery_district, created_at, completed_at
    ) VALUES (
        '00000000-b003-0000-0000-000000000003', '00000000-b001-0000-0000-000000000006', v_producer_1_id, v_p1_dupatta_id, NULL,
        5, 'piece', 1850.00, 9250.00, 'completed', 'Chandigarh', 'Chandigarh', pg_catalog.now() - INTERVAL '24 days', pg_catalog.now() - INTERVAL '20 days'
    );

    -- Order 4 (completed, linked to req 11)
    INSERT INTO public.orders (
        id, buyer_id, producer_id, product_id, buyer_request_id, quantity, unit, unit_price, total_amount, status, delivery_state, delivery_district, created_at, completed_at
    ) VALUES (
        '00000000-b003-0000-0000-000000000004', '00000000-b001-0000-0000-000000000001', v_producer_1_id, v_p1_cushion_id, '00000000-b002-0000-0000-000000000011',
        15, 'pack', 620.00, 9300.00, 'completed', 'Punjab', 'Amritsar', pg_catalog.now() - INTERVAL '45 days', pg_catalog.now() - INTERVAL '40 days'
    );

    -- Order 5 (cancelled, direct)
    INSERT INTO public.orders (
        id, buyer_id, producer_id, product_id, buyer_request_id, quantity, unit, unit_price, total_amount, status, cancel_reason, delivery_state, delivery_district, created_at, cancelled_at
    ) VALUES (
        '00000000-b003-0000-0000-000000000005', '00000000-b001-0000-0000-000000000009', v_producer_1_id, v_p1_cushion_id, NULL,
        10, 'pack', 640.00, 6400.00, 'cancelled', 'Packaging damaged during regional transport hub transit', 'Rajasthan', 'Jaipur', pg_catalog.now() - INTERVAL '31 days', pg_catalog.now() - INTERVAL '30 days'
    );

    -- Order 6 (completed, linked to req 12)
    INSERT INTO public.orders (
        id, buyer_id, producer_id, product_id, buyer_request_id, quantity, unit, unit_price, total_amount, status, delivery_state, delivery_district, created_at, completed_at
    ) VALUES (
        '00000000-b003-0000-0000-000000000006', '00000000-b001-0000-0000-000000000002', v_producer_1_id, v_p1_tote_id, '00000000-b002-0000-0000-000000000012',
        20, 'piece', 450.00, 9000.00, 'completed', 'Punjab', 'Ludhiana', pg_catalog.now() - INTERVAL '50 days', pg_catalog.now() - INTERVAL '46 days'
    );

    -- Order 7 (completed, direct)
    INSERT INTO public.orders (
        id, buyer_id, producer_id, product_id, buyer_request_id, quantity, unit, unit_price, total_amount, status, delivery_state, delivery_district, created_at, completed_at
    ) VALUES (
        '00000000-b003-0000-0000-000000000007', '00000000-b001-0000-0000-000000000010', v_producer_1_id, v_p1_stole_id, NULL,
        12, 'piece', 1150.00, 13800.00, 'completed', 'Maharashtra', 'Mumbai City', pg_catalog.now() - INTERVAL '38 days', pg_catalog.now() - INTERVAL '33 days'
    );

    -- Order 8 (confirmed, direct)
    INSERT INTO public.orders (
        id, buyer_id, producer_id, product_id, buyer_request_id, quantity, unit, unit_price, total_amount, status, delivery_state, delivery_district, created_at
    ) VALUES (
        '00000000-b003-0000-0000-000000000008', '00000000-b001-0000-0000-000000000008', v_producer_1_id, v_p1_stole_id, NULL,
        2, 'piece', 1200.00, 2400.00, 'confirmed', 'Delhi', 'South Delhi', pg_catalog.now() - INTERVAL '5 days'
    );

    -- Order 9 (pending, direct)
    INSERT INTO public.orders (
        id, buyer_id, producer_id, product_id, buyer_request_id, quantity, unit, unit_price, total_amount, status, delivery_state, delivery_district, created_at
    ) VALUES (
        '00000000-b003-0000-0000-000000000009', '00000000-b001-0000-0000-000000000005', v_producer_1_id, v_p1_tote_id, NULL,
        1, 'piece', 480.00, 480.00, 'pending', 'Punjab', 'SAS Nagar', pg_catalog.now() - INTERVAL '2 days'
    );

    -- Order 10 (cancelled, linked to req 18)
    INSERT INTO public.orders (
        id, buyer_id, producer_id, product_id, buyer_request_id, quantity, unit, unit_price, total_amount, status, cancel_reason, delivery_state, delivery_district, created_at, cancelled_at
    ) VALUES (
        '00000000-b003-0000-0000-000000000010', '00000000-b001-0000-0000-000000000012', v_producer_1_id, v_p1_potli_id, '00000000-b002-0000-0000-000000000018',
        15, 'piece', 300.00, 4500.00, 'cancelled', 'Buyer wedding event dates rescheduled', 'Maharashtra', 'Mumbai Suburban', pg_catalog.now() - INTERVAL '28 days', pg_catalog.now() - INTERVAL '27 days'
    );

    -- PRODUCER 2 (guptatarshit00@gmail.com - Ramanujan Handlooms)
    -- Order 11 (completed, linked to req 16)
    INSERT INTO public.orders (
        id, buyer_id, producer_id, product_id, buyer_request_id, quantity, unit, unit_price, total_amount, status, delivery_state, delivery_district, created_at, completed_at
    ) VALUES (
        '00000000-b003-0000-0000-000000000011', '00000000-b001-0000-0000-000000000006', v_producer_2_id, v_p2_runner_id, '00000000-b002-0000-0000-000000000016',
        20, 'piece', 500.00, 10000.00, 'completed', 'Chandigarh', 'Chandigarh', pg_catalog.now() - INTERVAL '65 days', pg_catalog.now() - INTERVAL '60 days'
    );

    -- Order 12 (completed, direct)
    INSERT INTO public.orders (
        id, buyer_id, producer_id, product_id, buyer_request_id, quantity, unit, unit_price, total_amount, status, delivery_state, delivery_district, created_at, completed_at
    ) VALUES (
        '00000000-b003-0000-0000-000000000012', '00000000-b001-0000-0000-000000000002', v_producer_2_id, v_p2_runner_id, NULL,
        15, 'piece', 490.00, 7350.00, 'completed', 'Punjab', 'Ludhiana', pg_catalog.now() - INTERVAL '44 days', pg_catalog.now() - INTERVAL '39 days'
    );

    -- Order 13 (pending, direct)
    INSERT INTO public.orders (
        id, buyer_id, producer_id, product_id, buyer_request_id, quantity, unit, unit_price, total_amount, status, delivery_state, delivery_district, created_at
    ) VALUES (
        '00000000-b003-0000-0000-000000000013', '00000000-b001-0000-0000-000000000009', v_producer_2_id, v_p2_runner_id, NULL,
        10, 'piece', 510.00, 5100.00, 'pending', 'Rajasthan', 'Jaipur', pg_catalog.now() - INTERVAL '1 day'
    );

    -- Order 14 (completed, linked to req 4)
    INSERT INTO public.orders (
        id, buyer_id, producer_id, product_id, buyer_request_id, quantity, unit, unit_price, total_amount, status, delivery_state, delivery_district, created_at, completed_at
    ) VALUES (
        '00000000-b003-0000-0000-000000000014', '00000000-b001-0000-0000-000000000006', v_producer_2_id, v_p2_towel_id, '00000000-b002-0000-0000-000000000004',
        30, 'pack', 360.00, 10800.00, 'completed', 'Chandigarh', 'Chandigarh', pg_catalog.now() - INTERVAL '55 days', pg_catalog.now() - INTERVAL '51 days'
    );

    -- Order 15 (completed, direct)
    INSERT INTO public.orders (
        id, buyer_id, producer_id, product_id, buyer_request_id, quantity, unit, unit_price, total_amount, status, delivery_state, delivery_district, created_at, completed_at
    ) VALUES (
        '00000000-b003-0000-0000-000000000015', '00000000-b001-0000-0000-000000000008', v_producer_2_id, v_p2_towel_id, NULL,
        3, 'pack', 380.00, 1140.00, 'completed', 'Delhi', 'South Delhi', pg_catalog.now() - INTERVAL '22 days', pg_catalog.now() - INTERVAL '19 days'
    );

    -- Order 16 (cancelled, direct)
    INSERT INTO public.orders (
        id, buyer_id, producer_id, product_id, buyer_request_id, quantity, unit, unit_price, total_amount, status, cancel_reason, delivery_state, delivery_district, created_at, cancelled_at
    ) VALUES (
        '00000000-b003-0000-0000-000000000016', '00000000-b001-0000-0000-000000000009', v_producer_2_id, v_p2_basket_id, NULL,
        8, 'piece', 720.00, 5760.00, 'cancelled', 'Bulk MOQ commercial terms could not be agreed', 'Rajasthan', 'Jaipur', pg_catalog.now() - INTERVAL '48 days', pg_catalog.now() - INTERVAL '47 days'
    );

    -- Order 17 (completed, linked to req 14)
    INSERT INTO public.orders (
        id, buyer_id, producer_id, product_id, buyer_request_id, quantity, unit, unit_price, total_amount, status, delivery_state, delivery_district, created_at, completed_at
    ) VALUES (
        '00000000-b003-0000-0000-000000000017', '00000000-b001-0000-0000-000000000007', v_producer_2_id, v_p2_mat_id, '00000000-b002-0000-0000-000000000014',
        25, 'piece', 410.00, 10250.00, 'completed', 'Delhi', 'Central Delhi', pg_catalog.now() - INTERVAL '35 days', pg_catalog.now() - INTERVAL '30 days'
    );

    -- Order 18 (completed, direct)
    INSERT INTO public.orders (
        id, buyer_id, producer_id, product_id, buyer_request_id, quantity, unit, unit_price, total_amount, status, delivery_state, delivery_district, created_at, completed_at
    ) VALUES (
        '00000000-b003-0000-0000-000000000018', '00000000-b001-0000-0000-000000000011', v_producer_2_id, v_p2_hanging_id, NULL,
        6, 'piece', 850.00, 5100.00, 'completed', 'Karnataka', 'Bengaluru Urban', pg_catalog.now() - INTERVAL '15 days', pg_catalog.now() - INTERVAL '10 days'
    );

    -- Order 19 (confirmed, direct)
    INSERT INTO public.orders (
        id, buyer_id, producer_id, product_id, buyer_request_id, quantity, unit, unit_price, total_amount, status, delivery_state, delivery_district, created_at
    ) VALUES (
        '00000000-b003-0000-0000-000000000019', '00000000-b001-0000-0000-000000000010', v_producer_2_id, v_p2_basket_id, NULL,
        15, 'piece', 700.00, 10500.00, 'confirmed', 'Maharashtra', 'Mumbai City', pg_catalog.now() - INTERVAL '4 days'
    );

    -- Order 20 (cancelled, linked to req 9)
    INSERT INTO public.orders (
        id, buyer_id, producer_id, product_id, buyer_request_id, quantity, unit, unit_price, total_amount, status, cancel_reason, delivery_state, delivery_district, created_at, cancelled_at
    ) VALUES (
        '00000000-b003-0000-0000-000000000020', '00000000-b001-0000-0000-000000000004', v_producer_2_id, v_p2_mat_id, '00000000-b002-0000-0000-000000000009',
        12, 'piece', 390.00, 4680.00, 'cancelled', 'Logistics delivery route temporarily unavailable', 'Punjab', 'Sangrur', pg_catalog.now() - INTERVAL '40 days', pg_catalog.now() - INTERVAL '39 days'
    );

    -- PRODUCER 3 (guptatarshit30@gmail.com - Ramesh Kheti Baadi)
    -- Order 21 (completed, linked to req 17)
    INSERT INTO public.orders (
        id, buyer_id, producer_id, product_id, buyer_request_id, quantity, unit, unit_price, total_amount, status, delivery_state, delivery_district, created_at, completed_at
    ) VALUES (
        '00000000-b003-0000-0000-000000000021', '00000000-b001-0000-0000-000000000004', v_producer_3_id, v_p3_oil_id, '00000000-b002-0000-0000-000000000017',
        50, 'litre', 200.00, 10000.00, 'completed', 'Punjab', 'Sangrur', pg_catalog.now() - INTERVAL '62 days', pg_catalog.now() - INTERVAL '58 days'
    );

    -- Order 22 (completed, direct)
    INSERT INTO public.orders (
        id, buyer_id, producer_id, product_id, buyer_request_id, quantity, unit, unit_price, total_amount, status, delivery_state, delivery_district, created_at, completed_at
    ) VALUES (
        '00000000-b003-0000-0000-000000000022', '00000000-b001-0000-0000-000000000003', v_producer_3_id, v_p3_oil_id, NULL,
        60, 'litre', 198.00, 11880.00, 'completed', 'Punjab', 'Patiala', pg_catalog.now() - INTERVAL '32 days', pg_catalog.now() - INTERVAL '29 days'
    );

    -- Order 23 (completed, direct)
    INSERT INTO public.orders (
        id, buyer_id, producer_id, product_id, buyer_request_id, quantity, unit, unit_price, total_amount, status, delivery_state, delivery_district, created_at, completed_at
    ) VALUES (
        '00000000-b003-0000-0000-000000000023', '00000000-b001-0000-0000-000000000004', v_producer_3_id, v_p3_jaggery_id, NULL,
        100, 'kg', 90.00, 9000.00, 'completed', 'Punjab', 'Sangrur', pg_catalog.now() - INTERVAL '52 days', pg_catalog.now() - INTERVAL '48 days'
    );

    -- Order 24 (completed, direct)
    INSERT INTO public.orders (
        id, buyer_id, producer_id, product_id, buyer_request_id, quantity, unit, unit_price, total_amount, status, delivery_state, delivery_district, created_at, completed_at
    ) VALUES (
        '00000000-b003-0000-0000-000000000024', '00000000-b001-0000-0000-000000000003', v_producer_3_id, v_p3_jaggery_id, NULL,
        150, 'kg', 88.00, 13200.00, 'completed', 'Punjab', 'Patiala', pg_catalog.now() - INTERVAL '26 days', pg_catalog.now() - INTERVAL '22 days'
    );

    -- Order 25 (completed, linked to req 13)
    INSERT INTO public.orders (
        id, buyer_id, producer_id, product_id, buyer_request_id, quantity, unit, unit_price, total_amount, status, delivery_state, delivery_district, created_at, completed_at
    ) VALUES (
        '00000000-b003-0000-0000-000000000025', '00000000-b001-0000-0000-000000000003', v_producer_3_id, v_p3_flour_id, '00000000-b002-0000-0000-000000000013',
        40, 'pack', 320.00, 12800.00, 'completed', 'Punjab', 'Patiala', pg_catalog.now() - INTERVAL '41 days', pg_catalog.now() - INTERVAL '37 days'
    );

    -- Order 26 (completed, direct)
    INSERT INTO public.orders (
        id, buyer_id, producer_id, product_id, buyer_request_id, quantity, unit, unit_price, total_amount, status, delivery_state, delivery_district, created_at, completed_at
    ) VALUES (
        '00000000-b003-0000-0000-000000000026', '00000000-b001-0000-0000-000000000011', v_producer_3_id, v_p3_turmeric_id, NULL,
        30, 'pack', 150.00, 4500.00, 'completed', 'Karnataka', 'Bengaluru Urban', pg_catalog.now() - INTERVAL '12 days', pg_catalog.now() - INTERVAL '8 days'
    );

    -- Order 27 (confirmed, direct)
    INSERT INTO public.orders (
        id, buyer_id, producer_id, product_id, buyer_request_id, quantity, unit, unit_price, total_amount, status, delivery_state, delivery_district, created_at
    ) VALUES (
        '00000000-b003-0000-0000-000000000027', '00000000-b001-0000-0000-000000000002', v_producer_3_id, v_p3_flour_id, NULL,
        20, 'pack', 330.00, 6600.00, 'confirmed', 'Punjab', 'Ludhiana', pg_catalog.now() - INTERVAL '3 days'
    );

    -- Order 28 (cancelled, linked to req 19)
    INSERT INTO public.orders (
        id, buyer_id, producer_id, product_id, buyer_request_id, quantity, unit, unit_price, total_amount, status, cancel_reason, delivery_state, delivery_district, created_at, cancelled_at
    ) VALUES (
        '00000000-b003-0000-0000-000000000028', '00000000-b001-0000-0000-000000000005', v_producer_3_id, v_p3_chilli_id, '00000000-b002-0000-0000-000000000019',
        10, 'pack', 120.00, 1200.00, 'cancelled', 'Producer could not accommodate custom packaging specifications', 'Punjab', 'SAS Nagar', pg_catalog.now() - INTERVAL '16 days', pg_catalog.now() - INTERVAL '15 days'
    );

    RAISE NOTICE 'Successfully seeded connected pilot marketplace: 12 buyers, 20 requests, 28 orders.';
END $$;

COMMIT;
