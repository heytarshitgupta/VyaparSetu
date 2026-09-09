-- ============================================================================
-- 012_onboarding_v2_business_verification.sql
-- Module: VyaparSetu Producer Onboarding V2 & Business Verification Architecture
-- Description:
--   1. Adds Step 3 optional business profile attributes:
--      - team_size (machine-readable codes: solo, 2_5, 6_10, 11_25, 25_plus)
--      - typical_monthly_sales (ranges: below_10k, 10k_50k, 50k_1l, 1l_5l, above_5l, prefer_not_to_say)
--      - production_capacity_quantity, production_capacity_unit, production_capacity_period
--        (enforces co-occurrence: either all NULL or all populated with quantity > 0)
--      - selling_channels (PostgreSQL TEXT[] array with canonical codes and mutual exclusivity
--        for 'not_selling_yet')
--   2. Adds backend-authoritative market_access_scope column:
--      - Scope levels: 'local', 'state', 'national' (defaults to 'state')
--      - 'state' is the standard default for all onboarded producers (intra-state platform access).
--      - 'national' is unlocked upon successful prototype GST verification.
--      - 'local' is available for hyperlocal/community distribution.
--      - Direct client write is completely REVOKED; controlled strictly by trusted backend/RPC.
--   3. Hardens GST verification data model & client privileges:
--      - Reuses existing gst_registered, gstin, and gst_verification_status from Migration 005.
--      - Adds audit timestamp gst_verified_at.
--      - Omits speculative columns (no gst_legal_name or gstin_hash).
--      - REVOKES direct client INSERT and UPDATE on gstin to prevent tampering or stale verified state.
--      - Adds BEFORE UPDATE trigger trg_producer_gst_state_change to reset verified state if
--        gst_registered is un-declared.
--   4. Implements trusted public.verify_producer_gst_prototype(p_gstin TEXT) RPC:
--      - Explicitly documented as a prototype simulation (validates 15-char structure and state codes;
--        does NOT connect to government GSTN APIs).
--      - Deterministic demo simulation (rejection on 'FAIL' or 4th char of PAN = 'X').
--      - Idempotent and protects already-verified records against conflicting retries.
--      - Automatically upgrades market_access_scope to 'national' upon verified status.
--      - Returns safe masked GSTIN ('07******4F1Z5').
--   5. Implements trusted public.reset_producer_gst_verification() RPC:
--      - Allows explicit reset of GST status and reverts market_access_scope to 'state'.
--   6. Implements trusted public.complete_producer_onboarding() RPC:
--      - Enforces server-side rule: Step 1 (email verified in auth.users + full_name) +
--        Step 2 (mandatory business name, category, and location) = Onboarding Completed.
--      - Business description (bio) is optional for low-friction onboarding.
--      - PAN, GST, and Aadhaar are strictly decoupled from onboarding completion.
--      - Preserves step progress for existing users without regression.
--   7. Updates public.advance_producer_onboarding_step() RPC:
--      - Aligns step progression with Onboarding V2 architecture.
--      - Removes obsolete Step 4 blocking gate from Migration 007.
--   8. Configures explicit column-level privilege whitelist for authenticated clients:
--      - Permits write on user-declared Step 3 fields.
--      - Strictly retains backend-only ownership over verification & market access states.
--
-- Backward Compatibility:
--   All new columns are additive with nullable or safe defaults (DEFAULT '{}', DEFAULT 'state').
--   Zero destructive drops. Historical migrations 001-011 remain unmodified.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. ADD STEP 3 (ABOUT YOUR BUSINESS - OPTIONAL) COLUMNS
-- ----------------------------------------------------------------------------
ALTER TABLE public.producer_profiles
    -- A. Team Size
    ADD COLUMN IF NOT EXISTS team_size VARCHAR(20),

    -- B. Typical Monthly Sales Range
    ADD COLUMN IF NOT EXISTS typical_monthly_sales VARCHAR(30),

    -- C. Production Capacity (Quantity, Unit, Period)
    ADD COLUMN IF NOT EXISTS production_capacity_quantity NUMERIC(12, 2),
    ADD COLUMN IF NOT EXISTS production_capacity_unit VARCHAR(30),
    ADD COLUMN IF NOT EXISTS production_capacity_period VARCHAR(20),

    -- D. Current Selling Channels (Array of machine-readable channel codes)
    ADD COLUMN IF NOT EXISTS selling_channels TEXT[] NOT NULL DEFAULT '{}';

-- ----------------------------------------------------------------------------
-- 2. ADD MARKET ACCESS SCOPE (BACKEND-AUTHORITATIVE)
-- ----------------------------------------------------------------------------
-- Governs platform distribution reach (local, state, national).
-- Default is 'state' (intra-state platform discovery for all onboarded producers).
-- Upgraded to 'national' upon verified business compliance (e.g. GST).
ALTER TABLE public.producer_profiles
    ADD COLUMN IF NOT EXISTS market_access_scope VARCHAR(20) NOT NULL DEFAULT 'state';

CREATE INDEX IF NOT EXISTS idx_producer_profiles_market_access
    ON public.producer_profiles(market_access_scope);

-- ----------------------------------------------------------------------------
-- 3. EXPAND GST VERIFICATION AUDIT ARTIFACTS
-- ----------------------------------------------------------------------------
-- Reuses existing gst_registered, gstin, gst_verification_status from Migration 005.
-- Adds verification timestamp.
ALTER TABLE public.producer_profiles
    ADD COLUMN IF NOT EXISTS gst_verified_at TIMESTAMPTZ;

-- ----------------------------------------------------------------------------
-- 4. DEFENSIVE CHECK CONSTRAINTS
-- ----------------------------------------------------------------------------

-- A. Team Size check
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_catalog.pg_constraint
        WHERE conname = 'chk_producer_team_size'
          AND conrelid = 'public.producer_profiles'::regclass
    ) THEN
        ALTER TABLE public.producer_profiles
            ADD CONSTRAINT chk_producer_team_size
                CHECK (team_size IS NULL OR team_size IN ('solo', '2_5', '6_10', '11_25', '25_plus'));
    END IF;
END $$;

-- B. Typical Monthly Sales check
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_catalog.pg_constraint
        WHERE conname = 'chk_producer_monthly_sales'
          AND conrelid = 'public.producer_profiles'::regclass
    ) THEN
        ALTER TABLE public.producer_profiles
            ADD CONSTRAINT chk_producer_monthly_sales
                CHECK (typical_monthly_sales IS NULL OR typical_monthly_sales IN (
                    'below_10k',
                    '10k_50k',
                    '50k_1l',
                    '1l_5l',
                    'above_5l',
                    'prefer_not_to_say'
                ));
    END IF;
END $$;

-- C. Production Capacity checks (All-or-none co-occurrence + strictly positive quantity)
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_catalog.pg_constraint
        WHERE conname = 'chk_producer_capacity_all_or_none'
          AND conrelid = 'public.producer_profiles'::regclass
    ) THEN
        ALTER TABLE public.producer_profiles
            ADD CONSTRAINT chk_producer_capacity_all_or_none
                CHECK (
                    (production_capacity_quantity IS NULL AND production_capacity_unit IS NULL AND production_capacity_period IS NULL)
                    OR
                    (production_capacity_quantity IS NOT NULL AND production_capacity_quantity > 0
                     AND production_capacity_unit IS NOT NULL
                     AND production_capacity_period IS NOT NULL)
                );
    END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_catalog.pg_constraint
        WHERE conname = 'chk_producer_capacity_unit'
          AND conrelid = 'public.producer_profiles'::regclass
    ) THEN
        ALTER TABLE public.producer_profiles
            ADD CONSTRAINT chk_producer_capacity_unit
                CHECK (production_capacity_unit IS NULL OR production_capacity_unit IN (
                    'pieces',
                    'kg',
                    'litres',
                    'packs',
                    'boxes',
                    'other'
                ));
    END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_catalog.pg_constraint
        WHERE conname = 'chk_producer_capacity_period'
          AND conrelid = 'public.producer_profiles'::regclass
    ) THEN
        ALTER TABLE public.producer_profiles
            ADD CONSTRAINT chk_producer_capacity_period
                CHECK (production_capacity_period IS NULL OR production_capacity_period IN (
                    'week',
                    'month',
                    'year'
                ));
    END IF;
END $$;

-- D. Selling Channels array checks (Canonical elements + non-conflict for 'not_selling_yet')
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_catalog.pg_constraint
        WHERE conname = 'chk_producer_selling_channels_valid'
          AND conrelid = 'public.producer_profiles'::regclass
    ) THEN
        ALTER TABLE public.producer_profiles
            ADD CONSTRAINT chk_producer_selling_channels_valid
                CHECK (selling_channels <@ ARRAY[
                    'local_customers',
                    'local_shops',
                    'whatsapp',
                    'instagram_facebook',
                    'online_marketplaces',
                    'exhibitions_fairs',
                    'not_selling_yet'
                ]::TEXT[]);
    END IF;
END $$;

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

-- E. Market Access Scope check
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_catalog.pg_constraint
        WHERE conname = 'chk_producer_market_access_scope'
          AND conrelid = 'public.producer_profiles'::regclass
    ) THEN
        ALTER TABLE public.producer_profiles
            ADD CONSTRAINT chk_producer_market_access_scope
                CHECK (market_access_scope IN ('local', 'state', 'national'));
    END IF;
END $$;

-- ----------------------------------------------------------------------------
-- 5. PRIVILEGE AUDIT & CLIENT WHITELIST FOR STEP 3 FIELDS
-- ----------------------------------------------------------------------------

-- A. Grant authenticated users column-level write on user-declared Step 3 inputs:
GRANT INSERT (
    team_size,
    typical_monthly_sales,
    production_capacity_quantity,
    production_capacity_unit,
    production_capacity_period,
    selling_channels
) ON TABLE public.producer_profiles TO authenticated;

GRANT UPDATE (
    team_size,
    typical_monthly_sales,
    production_capacity_quantity,
    production_capacity_unit,
    production_capacity_period,
    selling_channels
) ON TABLE public.producer_profiles TO authenticated;

-- B. GST SECURITY HARDENING:
-- Revoke direct client INSERT/UPDATE on gstin (which was previously granted in 005).
-- gstin can now ONLY be written via the trusted verify_producer_gst_prototype() RPC.
-- market_access_scope, gst_verified_at, and gst_verification_status remain strictly backend-only.
REVOKE INSERT (gstin), UPDATE (gstin)
    ON TABLE public.producer_profiles
    FROM anon, authenticated, PUBLIC;

-- ----------------------------------------------------------------------------
-- 6. TRIGGER TO PREVENT STALE VERIFICATION STATE
-- ----------------------------------------------------------------------------
-- If a producer toggles gst_registered to FALSE, this trigger resets verification
-- artifacts and reverts market_access_scope to 'state'.
CREATE OR REPLACE FUNCTION public.handle_producer_gst_state_change()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = ''
AS $$
BEGIN
    IF NEW.gst_registered = FALSE AND OLD.gst_registered = TRUE THEN
        NEW.gst_verification_status = 'not_applicable'::public.gst_verification_status;
        NEW.gstin = NULL;
        NEW.gst_verified_at = NULL;
        NEW.market_access_scope = 'state';
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_producer_gst_state_change ON public.producer_profiles;
CREATE TRIGGER trg_producer_gst_state_change
    BEFORE UPDATE ON public.producer_profiles
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_producer_gst_state_change();

-- ----------------------------------------------------------------------------
-- 7. TRUSTED GST VERIFICATION RPC (PROTOTYPE SIMULATION ONLY)
-- ----------------------------------------------------------------------------
-- Architecture & Prototype Truthfulness:
-- 1. Explicitly a PROTOTYPE SIMULATION.
--    This RPC performs defensive format and state-code validation.
--    It does NOT connect to GSTN, the GST Portal, or Government of India APIs.
-- 2. SECURITY DEFINER with search_path = '' and fully qualified object references.
-- 3. Caller identity derived strictly from auth.uid(); requires role = 'producer'.
-- 4. Row lock (FOR UPDATE) serializes requests.
-- 5. Validates 15-character GSTIN structure & Indian State/UT code (01-38, 97, 99).
-- 6. Protects verified state:
--    - Same GSTIN -> Idempotent success ('already_verified')
--    - Conflicting GSTIN -> Rejected ('already_verified_conflict'); preserves existing record
-- 7. Deterministic Demo Rule:
--    - Contains 'FAIL' or 4th char of PAN part (6th char of GSTIN) = 'X' -> Simulates rejection
--    - Otherwise -> Simulates success; sets gst_verification_status = 'verified',
--      market_access_scope = 'national', and records timestamp.
-- 8. Returns safe masked GSTIN ('07******4F1Z5').
CREATE OR REPLACE FUNCTION public.verify_producer_gst_prototype(
    p_gstin TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    v_uid UUID;
    v_role public.user_role;
    v_current_status public.gst_verification_status;
    v_current_gstin VARCHAR(15);
    v_gstin TEXT;
    v_state_code TEXT;
    v_state_num INTEGER;
    v_masked_gstin TEXT;
    v_is_demo_rejection BOOLEAN;
BEGIN
    -- 1. Authenticate caller
    v_uid := auth.uid();
    IF v_uid IS NULL THEN
        RETURN jsonb_build_object(
            'success', FALSE,
            'status', 'unauthenticated',
            'message', 'Authentication required to verify GSTIN.'
        );
    END IF;

    -- 2. Authorize caller role (must be 'producer')
    SELECT role INTO v_role
    FROM public.profiles
    WHERE id = v_uid;

    IF v_role IS NULL OR v_role <> 'producer'::public.user_role THEN
        RETURN jsonb_build_object(
            'success', FALSE,
            'status', 'unauthorized',
            'message', 'Only registered producers can verify GST details.'
        );
    END IF;

    -- 3. Confirm caller row exists in public.producer_profiles and load current status
    SELECT gst_verification_status, gstin
    INTO v_current_status, v_current_gstin
    FROM public.producer_profiles
    WHERE id = v_uid
    FOR UPDATE;

    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'success', FALSE,
            'status', 'not_found',
            'message', 'Producer profile record not found.'
        );
    END IF;

    -- 4. Normalize input using pg_catalog.btrim and upper
    v_gstin := pg_catalog.upper(pg_catalog.btrim(COALESCE(p_gstin, '')));

    -- 5. Validate GSTIN format: exactly 15 characters
    -- Structure: 2 digits (state), 5 letters, 4 digits, 1 letter (PAN), 1 entity digit, 'Z', 1 check char
    IF v_gstin !~ '^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$' THEN
        RETURN jsonb_build_object(
            'success', FALSE,
            'status', 'invalid_format',
            'message', 'Invalid GSTIN format. Must be 15 characters (e.g. 07AAAAA0000A1Z5).'
        );
    END IF;

    -- 6. Validate Indian State / UT Code (first 2 digits: 01-38, 97, 99)
    v_state_code := pg_catalog.substr(v_gstin, 1, 2);
    v_state_num := v_state_code::INTEGER;
    IF (v_state_num < 1 OR v_state_num > 38) AND v_state_num NOT IN (97, 99) THEN
        RETURN jsonb_build_object(
            'success', FALSE,
            'status', 'invalid_state_code',
            'message', 'Invalid state code in GSTIN. First 2 digits must correspond to a valid Indian State/UT.'
        );
    END IF;

    -- 7. Compute safe masked display identifier: State code + 6 asterisks + last 5 characters
    v_masked_gstin := v_state_code || '******' || pg_catalog.right(v_gstin, 5);

    -- 8. Protect Already-Verified Identity
    IF v_current_status = 'verified'::public.gst_verification_status THEN
        -- Case A: Same GSTIN submitted -> Idempotent success
        IF v_current_gstin IS NOT NULL AND v_current_gstin = v_gstin THEN
            RETURN jsonb_build_object(
                'success', TRUE,
                'status', 'already_verified',
                'message', 'GSTIN is already verified for this account.',
                'masked_gstin', v_masked_gstin,
                'market_access_scope', 'national'
            );
        ELSE
            -- Case B: Different GSTIN submitted -> Conflict; preserve existing verified record
            RETURN jsonb_build_object(
                'success', FALSE,
                'status', 'already_verified_conflict',
                'message', 'A verified GSTIN is already associated with this account. Explicit reset is required to change it.',
                'masked_gstin', v_state_code || '******' || pg_catalog.right(COALESCE(v_current_gstin, v_gstin), 5)
            );
        END IF;
    END IF;

    -- 9. Deterministic Demo Simulation Rule (Only for unverified / rejected callers)
    -- - GSTIN containing 'FAIL' or having 4th char of PAN part (6th character) = 'X' simulates rejection.
    -- - All other format-valid GSTINs simulate successful prototype verification.
    v_is_demo_rejection := (v_gstin LIKE '%FAIL%') OR (pg_catalog.substr(v_gstin, 6, 1) = 'X');

    IF v_is_demo_rejection THEN
        UPDATE public.producer_profiles
        SET gst_verification_status = 'rejected'::public.gst_verification_status,
            gst_verified_at = NULL,
            market_access_scope = 'state',
            updated_at = pg_catalog.now()
        WHERE id = v_uid;

        RETURN jsonb_build_object(
            'success', FALSE,
            'status', 'rejected',
            'message', 'GSTIN could not be validated in prototype environment. Please check your 15-digit GSTIN.',
            'masked_gstin', v_masked_gstin
        );
    END IF;

    -- 10. Successful Prototype Verification: Persist verified artifacts & grant 'national' market access
    UPDATE public.producer_profiles
    SET gst_registered = TRUE,
        gstin = v_gstin,
        gst_verification_status = 'verified'::public.gst_verification_status,
        gst_verified_at = pg_catalog.now(),
        market_access_scope = 'national',
        updated_at = pg_catalog.now()
    WHERE id = v_uid;

    -- 11. Return safe structured result (Truthful prototype confirmation)
    RETURN jsonb_build_object(
        'success', TRUE,
        'status', 'verified',
        'message', 'GSTIN format and state code validated successfully in prototype environment. National market access unlocked.',
        'masked_gstin', v_masked_gstin,
        'state_code', v_state_code,
        'market_access_scope', 'national'
    );
END;
$$;

REVOKE ALL ON FUNCTION public.verify_producer_gst_prototype(TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.verify_producer_gst_prototype(TEXT) TO authenticated;

-- ----------------------------------------------------------------------------
-- 8. TRUSTED GST VERIFICATION RESET RPC
-- ----------------------------------------------------------------------------
-- Allows a producer to explicitly reset their GST verification status and return
-- to 'state' market access scope in order to submit a corrected GSTIN.
CREATE OR REPLACE FUNCTION public.reset_producer_gst_verification()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    v_uid UUID;
    v_role public.user_role;
BEGIN
    -- 1. Authenticate caller
    v_uid := auth.uid();
    IF v_uid IS NULL THEN
        RETURN jsonb_build_object(
            'success', FALSE,
            'status', 'unauthenticated',
            'message', 'Authentication required to reset GST verification.'
        );
    END IF;

    -- 2. Authorize caller role (must be 'producer')
    SELECT role INTO v_role
    FROM public.profiles
    WHERE id = v_uid;

    IF v_role IS NULL OR v_role <> 'producer'::public.user_role THEN
        RETURN jsonb_build_object(
            'success', FALSE,
            'status', 'unauthorized',
            'message', 'Only registered producers can reset GST verification.'
        );
    END IF;

    -- 3. Reset GST state to unverified
    UPDATE public.producer_profiles
    SET gst_verification_status = 'unverified'::public.gst_verification_status,
        gstin = NULL,
        gst_verified_at = NULL,
        market_access_scope = 'state',
        updated_at = pg_catalog.now()
    WHERE id = v_uid;

    RETURN jsonb_build_object(
        'success', TRUE,
        'status', 'reset',
        'message', 'GST verification status has been reset. You may now enter and verify a new GSTIN.',
        'market_access_scope', 'state'
    );
END;
$$;

REVOKE ALL ON FUNCTION public.reset_producer_gst_verification() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.reset_producer_gst_verification() TO authenticated;

-- ----------------------------------------------------------------------------
-- 9. TRUSTED ONBOARDING COMPLETION RPC
-- ----------------------------------------------------------------------------
-- Enforces server-side rule:
--   Step 1 account verified (email confirmed in auth.users + full_name)
--   + Step 2 required business information completed (name, category, location)
--   = Producer may complete onboarding and enter Home.
--
-- Business description (bio) is optional for low-friction onboarding.
-- PAN, GST, and Aadhaar are strictly decoupled from onboarding completion.
-- Step 3 is optional.
CREATE OR REPLACE FUNCTION public.complete_producer_onboarding()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    v_uid UUID;
    v_role public.user_role;
    v_full_name TEXT;
    v_auth_email TEXT;
    v_email_confirmed_at TIMESTAMPTZ;
    v_confirmed_at TIMESTAMPTZ;
    v_current_onboarding_status public.onboarding_status;
    v_server_step SMALLINT;
    v_business_name TEXT;
    v_craft_category TEXT;
    v_state TEXT;
    v_district TEXT;
    v_city TEXT;
    v_pincode TEXT;
BEGIN
    -- 1. Authenticate caller
    v_uid := auth.uid();
    IF v_uid IS NULL THEN
        RETURN jsonb_build_object(
            'success', FALSE,
            'status', 'unauthenticated',
            'message', 'Authentication required to complete onboarding.'
        );
    END IF;

    -- 2. Authorize caller role (must be 'producer')
    SELECT role, full_name
    INTO v_role, v_full_name
    FROM public.profiles
    WHERE id = v_uid;

    IF v_role IS NULL OR v_role <> 'producer'::public.user_role THEN
        RETURN jsonb_build_object(
            'success', FALSE,
            'status', 'unauthorized',
            'message', 'Only registered producers can complete onboarding.'
        );
    END IF;

    -- 3. Retrieve caller's producer_profile with row lock
    SELECT onboarding_status, onboarding_step, business_name, craft_category, state, district, city, pincode
    INTO v_current_onboarding_status, v_server_step, v_business_name, v_craft_category, v_state, v_district, v_city, v_pincode
    FROM public.producer_profiles
    WHERE id = v_uid
    FOR UPDATE;

    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'success', FALSE,
            'status', 'not_found',
            'message', 'Producer profile not found.'
        );
    END IF;

    -- 4. Idempotent success if already completed
    IF v_current_onboarding_status = 'completed'::public.onboarding_status THEN
        RETURN jsonb_build_object(
            'success', TRUE,
            'status', 'already_completed',
            'message', 'Producer onboarding is already completed.'
        );
    END IF;

    -- 5. Validate Step 1 Prerequisite A: Email confirmation check from auth.users
    SELECT email, email_confirmed_at, confirmed_at
    INTO v_auth_email, v_email_confirmed_at, v_confirmed_at
    FROM auth.users
    WHERE id = v_uid;

    IF v_auth_email IS NOT NULL AND v_email_confirmed_at IS NULL AND v_confirmed_at IS NULL THEN
        RETURN jsonb_build_object(
            'success', FALSE,
            'status', 'email_unverified',
            'message', 'Email verification is required before completing onboarding.'
        );
    END IF;

    -- 6. Validate Step 1 Prerequisite B: Full Name in public.profiles
    IF v_full_name IS NULL OR pg_catalog.length(pg_catalog.btrim(v_full_name)) < 2 THEN
        RETURN jsonb_build_object(
            'success', FALSE,
            'status', 'prerequisite_failed',
            'message', 'Account full name must be at least 2 characters.'
        );
    END IF;

    -- 7. Validate Step 2 Prerequisites (Mandatory Business & Location Details)
    -- Note: bio is optional for low-friction onboarding
    IF v_business_name IS NULL OR pg_catalog.length(pg_catalog.btrim(v_business_name)) < 2 THEN
        RETURN jsonb_build_object(
            'success', FALSE,
            'status', 'prerequisite_failed',
            'message', 'Business name must be at least 2 characters.'
        );
    END IF;

    IF v_craft_category IS NULL OR pg_catalog.btrim(v_craft_category) = '' THEN
        RETURN jsonb_build_object(
            'success', FALSE,
            'status', 'prerequisite_failed',
            'message', 'Business craft category must be specified.'
        );
    END IF;

    IF v_state IS NULL OR pg_catalog.btrim(v_state) = '' THEN
        RETURN jsonb_build_object(
            'success', FALSE,
            'status', 'prerequisite_failed',
            'message', 'State or Union Territory must be specified.'
        );
    END IF;

    IF v_district IS NULL OR pg_catalog.length(pg_catalog.btrim(v_district)) < 2 THEN
        RETURN jsonb_build_object(
            'success', FALSE,
            'status', 'prerequisite_failed',
            'message', 'District must be at least 2 characters.'
        );
    END IF;

    IF v_city IS NULL OR pg_catalog.length(pg_catalog.btrim(v_city)) < 2 THEN
        RETURN jsonb_build_object(
            'success', FALSE,
            'status', 'prerequisite_failed',
            'message', 'Area, village, or city must be at least 2 characters.'
        );
    END IF;

    IF v_pincode IS NULL OR v_pincode !~ '^[1-9][0-9]{5}$' THEN
        RETURN jsonb_build_object(
            'success', FALSE,
            'status', 'prerequisite_failed',
            'message', 'A valid 6-digit postal PIN code is required.'
        );
    END IF;

    -- 8. Persist completion (Preserve step number if already at or beyond step 3)
    UPDATE public.producer_profiles
    SET onboarding_status = 'completed'::public.onboarding_status,
        onboarding_step = CASE WHEN v_server_step >= 3 THEN v_server_step ELSE 3 END,
        updated_at = pg_catalog.now()
    WHERE id = v_uid;

    RETURN jsonb_build_object(
        'success', TRUE,
        'status', 'completed',
        'message', 'Producer onboarding completed successfully.'
    );
END;
$$;

REVOKE ALL ON FUNCTION public.complete_producer_onboarding() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.complete_producer_onboarding() TO authenticated;

-- ----------------------------------------------------------------------------
-- 10. UPDATE ADVANCE_PRODUCER_ONBOARDING_STEP RPC FOR ONBOARDING V2
-- ----------------------------------------------------------------------------
-- Replaces Migration 007 implementation to align with 3-step V2 structure:
-- Step 1 -> 2: Verifies Full Name in profiles
-- Step 2 -> 3: Verifies Step 2 required business & location fields (bio is optional)
-- Allows forward progression without the obsolete Step 4 blocking gate.
CREATE OR REPLACE FUNCTION public.advance_producer_onboarding_step(
    expected_current_step SMALLINT,
    next_step SMALLINT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    v_uid UUID;
    v_role public.user_role;
    v_full_name TEXT;
    v_server_step SMALLINT;
    v_onboarding_status public.onboarding_status;
    v_business_name TEXT;
    v_craft_category TEXT;
    v_state TEXT;
    v_district TEXT;
    v_city TEXT;
    v_pincode TEXT;
BEGIN
    -- 1. Authenticate caller
    v_uid := auth.uid();
    IF v_uid IS NULL THEN
        RETURN jsonb_build_object(
            'success', FALSE,
            'status', 'unauthenticated',
            'message', 'Authentication required to advance onboarding progress.'
        );
    END IF;

    -- 2. Authorize caller role (must be 'producer')
    SELECT role, full_name
    INTO v_role, v_full_name
    FROM public.profiles
    WHERE id = v_uid;

    IF v_role IS NULL OR v_role <> 'producer'::public.user_role THEN
        RETURN jsonb_build_object(
            'success', FALSE,
            'status', 'unauthorized',
            'message', 'Only registered producers can update onboarding progress.'
        );
    END IF;

    -- 3. Retrieve caller's producer_profile with row lock
    SELECT onboarding_step, onboarding_status, business_name, craft_category, state, district, city, pincode
    INTO v_server_step, v_onboarding_status, v_business_name, v_craft_category, v_state, v_district, v_city, v_pincode
    FROM public.producer_profiles
    WHERE id = v_uid
    FOR UPDATE;

    IF v_server_step IS NULL THEN
        RETURN jsonb_build_object(
            'success', FALSE,
            'status', 'not_found',
            'message', 'Producer profile not found.'
        );
    END IF;

    -- 4. If onboarding is already completed, return safe idempotent result
    IF v_onboarding_status = 'completed'::public.onboarding_status THEN
        RETURN jsonb_build_object(
            'success', TRUE,
            'status', 'already_completed',
            'onboarding_step', v_server_step
        );
    END IF;

    -- 5. Validate next_step bounds
    IF next_step IS NULL OR next_step < 1 OR next_step > 5 THEN
        RETURN jsonb_build_object(
            'success', FALSE,
            'status', 'invalid_step',
            'message', 'Target onboarding step must be between 1 and 5.'
        );
    END IF;

    -- 6. Idempotency & Monotonicity
    IF v_server_step >= next_step THEN
        RETURN jsonb_build_object(
            'success', TRUE,
            'status', 'already_advanced',
            'onboarding_step', v_server_step
        );
    END IF;

    -- 7. Validate expected_current_step to guard against stale client state
    IF expected_current_step IS NULL THEN
        RETURN jsonb_build_object(
            'success', FALSE,
            'status', 'invalid_step',
            'message', 'Expected current step is required.'
        );
    END IF;

    IF v_server_step <> expected_current_step THEN
        RETURN jsonb_build_object(
            'success', FALSE,
            'status', 'stale_client_state',
            'message', 'Client progress is out of sync with server.',
            'onboarding_step', v_server_step
        );
    END IF;

    -- 8. Enforce single-step progression
    IF next_step <> expected_current_step + 1 THEN
        RETURN jsonb_build_object(
            'success', FALSE,
            'status', 'invalid_progression',
            'message', 'Cannot skip intermediate onboarding steps.',
            'onboarding_step', v_server_step
        );
    END IF;

    -- 9. Server-Side Prerequisite Validation
    IF expected_current_step = 1 THEN
        -- Prerequisite 1 -> 2: Full Name in public.profiles
        IF v_full_name IS NULL OR pg_catalog.length(pg_catalog.btrim(v_full_name)) < 2 THEN
            RETURN jsonb_build_object(
                'success', FALSE,
                'status', 'prerequisite_failed',
                'message', 'Basic details (Full Name) must be completed before advancing.',
                'onboarding_step', v_server_step
            );
        END IF;

    ELSIF expected_current_step = 2 THEN
        -- Prerequisite 2 -> 3: Step 2 Required Business & Location Details (bio is optional)
        IF v_business_name IS NULL OR pg_catalog.length(pg_catalog.btrim(v_business_name)) < 2
           OR v_craft_category IS NULL OR pg_catalog.btrim(v_craft_category) = ''
           OR v_state IS NULL OR pg_catalog.btrim(v_state) = ''
           OR v_district IS NULL OR pg_catalog.length(pg_catalog.btrim(v_district)) < 2
           OR v_city IS NULL OR pg_catalog.length(pg_catalog.btrim(v_city)) < 2
           OR v_pincode IS NULL OR v_pincode !~ '^[1-9][0-9]{5}$' THEN
            RETURN jsonb_build_object(
                'success', FALSE,
                'status', 'prerequisite_failed',
                'message', 'All required business details (name, category, location) must be saved before advancing.',
                'onboarding_step', v_server_step
            );
        END IF;

    ELSE
        -- Steps beyond 2 can advance freely
        NULL;
    END IF;

    -- 10. Persist advancement (Monotonic progression)
    UPDATE public.producer_profiles
    SET onboarding_step = next_step,
        updated_at = pg_catalog.now()
    WHERE id = v_uid;

    RETURN jsonb_build_object(
        'success', TRUE,
        'status', 'advanced',
        'onboarding_step', next_step
    );
END;
$$;

REVOKE ALL ON FUNCTION public.advance_producer_onboarding_step(SMALLINT, SMALLINT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.advance_producer_onboarding_step(SMALLINT, SMALLINT) TO authenticated;
