-- ============================================================================
-- 007_resumable_producer_onboarding.sql
-- Module: VyaparSetu Resumable Producer Onboarding (Step 4E2.1 / Step 4E2.3)
-- Description: Adds persistent server-backed onboarding progress tracking to
--              public.producer_profiles and provides a secure, monotonic RPC
--              to advance onboarding steps safely across browser refreshes,
--              restarts, and sign-outs.
--
-- Security Guarantees & Architectural Boundaries:
-- 1. Server-Authoritative: onboarding_step SMALLINT is stored in Supabase.
-- 2. Direct client UPDATE on onboarding_step is NOT granted; progression is
--    strictly mediated by public.advance_producer_onboarding_step() RPC.
-- 3. The RPC uses SECURITY DEFINER with search_path = '' and derives caller
--    identity exclusively via auth.uid().
-- 4. Enforces expected_current_step: guards against stale client state and
--    enforces strict single-step forward progression (next = expected + 1).
-- 5. Server-Side Prerequisite Checks: The RPC validates saved database data
--    before advancing each step (Flutter validation is UX; RPC is security).
-- 6. Step 4 -> 5 Blocked: Generic progression RPC cannot decide Step 4
--    completion while Aadhaar/GST/Address compliance workflows are evolving.
-- 7. Monotonic & Idempotent: Back-navigation or re-saving earlier steps will
--    never regress the server's recorded progress.
-- 8. Concurrency Protection: Uses SELECT ... FOR UPDATE row locking.
-- 9. Lifecycle Protection: If onboarding_status = 'completed', returns
--    idempotent success without mutation. The RPC never sets completed status.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. ADD ONBOARDING_STEP COLUMN TO PRODUCER_PROFILES
-- ----------------------------------------------------------------------------
-- Represents the next step the producer should complete (1 to 5):
-- 1 = Basic Details
-- 2 = Business / Craft Details
-- 3 = Location Details
-- 4 = Identity & Compliance
-- 5 = Review & Submit
ALTER TABLE public.producer_profiles
    ADD COLUMN IF NOT EXISTS onboarding_step SMALLINT NOT NULL DEFAULT 1;

-- ----------------------------------------------------------------------------
-- 2. CHECK CONSTRAINT FOR VALID ONBOARDING STEPS
-- ----------------------------------------------------------------------------
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_catalog.pg_constraint
        WHERE conname = 'chk_producer_onboarding_step'
          AND conrelid = 'public.producer_profiles'::regclass
    ) THEN
        ALTER TABLE public.producer_profiles
            ADD CONSTRAINT chk_producer_onboarding_step
                CHECK (onboarding_step >= 1 AND onboarding_step <= 5);
    END IF;
END $$;

-- ----------------------------------------------------------------------------
-- 3. DETERMINISTIC DATA BACKFILL FOR EXISTING PRODUCERS
-- ----------------------------------------------------------------------------
-- Inspects existing stored profile and producer_profile data to infer and
-- restore progress accurately without resetting existing artisans to Step 1.
-- NOTE: onboarding_status belongs to public.producer_profiles (pp).
UPDATE public.producer_profiles pp
SET onboarding_step = CASE
    -- A. Already completed onboarding lifecycle:
    WHEN pp.onboarding_status = 'completed'::public.onboarding_status THEN 5

    -- B. Completed Step 3 (Location details present and valid):
    WHEN pp.state IS NOT NULL AND pg_catalog.btrim(pp.state) <> ''
         AND pp.district IS NOT NULL AND pg_catalog.length(pg_catalog.btrim(pp.district)) >= 2
         AND pp.city IS NOT NULL AND pg_catalog.length(pg_catalog.btrim(pp.city)) >= 2
         AND pp.pincode IS NOT NULL AND pp.pincode ~ '^[1-9][0-9]{5}$'
         AND pp.address IS NOT NULL AND pg_catalog.length(pg_catalog.btrim(pp.address)) >= 5
         THEN 4

    -- C. Completed Step 2 (Craft & Business details present and valid):
    WHEN pp.business_name IS NOT NULL AND pg_catalog.length(pg_catalog.btrim(pp.business_name)) >= 2
         AND pp.craft_category IS NOT NULL AND pg_catalog.btrim(pp.craft_category) <> ''
         THEN 3

    -- D. Completed Step 1 (Basic details present in profiles):
    WHEN p.full_name IS NOT NULL AND pg_catalog.length(pg_catalog.btrim(p.full_name)) >= 2
         THEN 2

    -- E. New / Unstarted:
    ELSE 1
END
FROM public.profiles p
WHERE pp.id = p.id;

-- ----------------------------------------------------------------------------
-- 4. TRUSTED SECURITY DEFINER RPC TO ADVANCE ONBOARDING PROGRESS
-- ----------------------------------------------------------------------------
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
    v_address TEXT;
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

    -- 2. Authorize caller role (must be 'producer') and retrieve basic profile data
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

    -- 3. Retrieve caller's producer_profile with row lock to serialize concurrent requests
    SELECT onboarding_step, onboarding_status, business_name, craft_category, state, district, city, pincode, address
    INTO v_server_step, v_onboarding_status, v_business_name, v_craft_category, v_state, v_district, v_city, v_pincode, v_address
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

    -- 4. If onboarding is already completed, return safe idempotent result without mutation
    IF v_onboarding_status = 'completed'::public.onboarding_status THEN
        RETURN jsonb_build_object(
            'success', TRUE,
            'status', 'already_completed',
            'onboarding_step', 5
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

    -- 6. Idempotency & Monotonicity:
    -- If server step is already at or beyond next_step, do NOT regress.
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

    -- 9. Server-Side Prerequisite Validation (Verify actual saved data)
    IF expected_current_step = 1 THEN
        -- Prerequisite for 1 -> 2: Valid Basic Details (Full Name) in public.profiles
        IF v_full_name IS NULL OR pg_catalog.length(pg_catalog.btrim(v_full_name)) < 2 THEN
            RETURN jsonb_build_object(
                'success', FALSE,
                'status', 'prerequisite_failed',
                'message', 'Basic details (Full Name) must be completed before advancing.',
                'onboarding_step', v_server_step
            );
        END IF;

    ELSIF expected_current_step = 2 THEN
        -- Prerequisite for 2 -> 3: Valid Business & Craft Details in public.producer_profiles
        IF v_business_name IS NULL OR pg_catalog.length(pg_catalog.btrim(v_business_name)) < 2
           OR v_craft_category IS NULL OR pg_catalog.btrim(v_craft_category) = '' THEN
            RETURN jsonb_build_object(
                'success', FALSE,
                'status', 'prerequisite_failed',
                'message', 'Business and craft details must be saved before advancing.',
                'onboarding_step', v_server_step
            );
        END IF;

    ELSIF expected_current_step = 3 THEN
        -- Prerequisite for 3 -> 4: Valid Location Details in public.producer_profiles
        IF v_state IS NULL OR pg_catalog.btrim(v_state) = ''
           OR v_district IS NULL OR pg_catalog.length(pg_catalog.btrim(v_district)) < 2
           OR v_city IS NULL OR pg_catalog.length(pg_catalog.btrim(v_city)) < 2
           OR v_pincode IS NULL OR v_pincode !~ '^[1-9][0-9]{5}$'
           OR v_address IS NULL OR pg_catalog.length(pg_catalog.btrim(v_address)) < 5 THEN
            RETURN jsonb_build_object(
                'success', FALSE,
                'status', 'prerequisite_failed',
                'message', 'Valid location details must be saved before advancing.',
                'onboarding_step', v_server_step
            );
        END IF;

    ELSIF expected_current_step = 4 THEN
        -- Step 4 -> 5 is blocked for now: Identity & Compliance completion rules
        -- (PAN, Aadhaar, GST, Address) are still being finalized.
        RETURN jsonb_build_object(
            'success', FALSE,
            'status', 'identity_compliance_incomplete',
            'message', 'Step 4 completion is governed by verification workflows.',
            'onboarding_step', v_server_step
        );

    ELSE
        RETURN jsonb_build_object(
            'success', FALSE,
            'status', 'invalid_step',
            'message', 'Invalid onboarding step requested.',
            'onboarding_step', v_server_step
        );
    END IF;

    -- 10. Persist advancement (Monotonic progression)
    UPDATE public.producer_profiles
    SET onboarding_step = next_step
    WHERE id = v_uid;

    -- Note: onboarding_status is NOT modified here; it remains controlled by trusted completion RPC.

    RETURN jsonb_build_object(
        'success', TRUE,
        'status', 'advanced',
        'onboarding_step', next_step
    );
END;
$$;

-- ----------------------------------------------------------------------------
-- 5. PRIVILEGES
-- ----------------------------------------------------------------------------
-- Revoke execution from public/anon; grant execution only to authenticated.
REVOKE ALL ON FUNCTION public.advance_producer_onboarding_step(SMALLINT, SMALLINT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.advance_producer_onboarding_step(SMALLINT, SMALLINT) TO authenticated;
