-- ============================================================================
-- 014_simplify_pan_prototype_verification.sql
-- Module: VyaparSetu PAN Verification Prototype Cleanup
-- Description: Replaces public.verify_producer_pan_prototype with a single-parameter
--              contract: verify_producer_pan_prototype(p_pan TEXT).
--
-- Background & Architectural Context:
-- 1. Migration 006/008 originally defined verify_producer_pan_prototype with
--    (p_pan TEXT, p_name TEXT, p_dob DATE).
-- 2. Security audit proved that p_name and p_dob were dead prototype parameters:
--    they were checked for basic null/length gates but never matched against an
--    external registry, never compared with producers.full_name, and never stored.
-- 3. VyaparSetu does not query authoritative government PAN registries (NSDL/ITD)
--    in this SIH prototype. Retaining p_name/p_dob created a contract bug where
--    post-onboarding verification without DOB failed with 'invalid_dob'.
-- 4. This migration replaces the RPC with a truthful single-parameter contract (p_pan)
--    that performs local format validation, deterministic demo simulation, and
--    account-scoped protected metadata storage.
--
-- Security & Storage Details:
-- - SECURITY DEFINER with search_path = '' and fully qualified object references.
-- - Caller identity derived strictly from auth.uid(); requires role = 'producer'.
-- - Row lock (FOR UPDATE) serializes requests on public.producer_profiles.
-- - Raw PAN is transient and is NEVER stored in database tables.
-- - pan_last4 (last 4 characters of PAN) is stored for UI display.
-- - Account-Scoped Deterministic Hash:
--     pan_hash = encode(sha256((v_pan || ':' || v_uid::TEXT)::BYTEA), 'hex')
--   NOTE ON HASHING: This is account-scoped deterministic hashing (incorporating
--   the caller's UUID), NOT a global salted HMAC.
-- - Known Prototype Limitation: Because the hash incorporates auth.uid() and lookup
--   is strictly scoped to the calling account (WHERE id = v_uid), this prototype
--   does NOT prevent cross-account duplicates (Account A and Account B submitting
--   the same PAN will both succeed). A global duplicate-prevention mechanism
--   using a server-held keyed HMAC / blind index can be designed in a future migration.
-- ============================================================================

BEGIN;

-- 1. Explicitly drop the legacy 3-parameter function signature
-- This prevents an orphaned, overloaded function with dead parameters from remaining callable.
DROP FUNCTION IF EXISTS public.verify_producer_pan_prototype(TEXT, TEXT, DATE);

-- 2. Create the new truthful 1-parameter RPC
CREATE OR REPLACE FUNCTION public.verify_producer_pan_prototype(
    p_pan TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    v_uid UUID;
    v_role public.user_role;
    v_current_status public.verification_status;
    v_current_last4 TEXT;
    v_current_hash TEXT;
    v_pan TEXT;
    v_last4 TEXT;
    v_pan_hash TEXT;
    v_masked_pan TEXT;
    v_is_demo_rejection BOOLEAN;
BEGIN
    -- 1. Authenticate caller
    v_uid := auth.uid();
    IF v_uid IS NULL THEN
        RETURN jsonb_build_object(
            'success', FALSE,
            'status', 'unauthenticated',
            'record_status', 'unauthorized',
            'message', 'Authentication required to record PAN details.'
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
            'record_status', 'unauthorized',
            'message', 'Only registered producers can record PAN details.'
        );
    END IF;

    -- 3. Confirm caller row exists in public.producer_profiles and lock row
    SELECT pan_verification_status, pan_last4, pan_hash
      INTO v_current_status, v_current_last4, v_current_hash
      FROM public.producer_profiles
     WHERE id = v_uid
       FOR UPDATE;

    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'success', FALSE,
            'status', 'not_found',
            'record_status', 'account_not_found',
            'message', 'Producer profile record not found.'
        );
    END IF;

    -- 4. Normalize input using pg_catalog.btrim and uppercase
    v_pan := pg_catalog.upper(pg_catalog.btrim(COALESCE(p_pan, '')));

    -- 5. Validate PAN format: exactly 5 uppercase letters, 4 digits, 1 uppercase letter
    IF v_pan !~ '^[A-Z]{5}[0-9]{4}[A-Z]$' THEN
        RETURN jsonb_build_object(
            'success', FALSE,
            'status', 'invalid_format',
            'record_status', 'invalid_format',
            'message', 'Invalid PAN format. Must be 10 characters (e.g. ABCDE1234F).'
        );
    END IF;

    -- 6. Compute incoming normalized artifacts
    v_last4 := pg_catalog.right(v_pan, 4);
    -- Account-scoped deterministic hash incorporating caller UUID
    v_pan_hash := pg_catalog.encode(
        pg_catalog.sha256((v_pan || ':' || v_uid::TEXT)::BYTEA),
        'hex'
    );
    v_masked_pan := '******' || v_last4;

    -- 7. Protect already-verified identity for this account
    IF v_current_status = 'verified'::public.verification_status THEN
        -- Case A: Same PAN details submitted -> Idempotent success
        IF v_current_hash IS NOT NULL AND v_current_hash = v_pan_hash THEN
            RETURN jsonb_build_object(
                'success', TRUE,
                'status', 'already_verified',
                'record_status', 'already_recorded',
                'message', 'PAN details are already recorded for this account.',
                'pan_last4', v_current_last4,
                'masked_pan', '******' || COALESCE(v_current_last4, v_last4)
            );
        ELSE
            -- Case B: Different PAN submitted -> Conflict; preserve existing verified record
            RETURN jsonb_build_object(
                'success', FALSE,
                'status', 'already_verified_conflict',
                'record_status', 'already_recorded_conflict',
                'message', 'A PAN is already associated with this account. Re-verification is required to change it.',
                'pan_last4', v_current_last4,
                'masked_pan', '******' || COALESCE(v_current_last4, '')
            );
        END IF;
    END IF;

    -- 8. Deterministic Demo Simulation Rule (Only for unverified / rejected callers)
    -- For evaluation & testing:
    -- - PAN starting with 'FAIL' (e.g. FAILA1234B) or having 4th letter 'X' (e.g. ABCXE1234F) simulates rejection.
    -- - All other format-valid PANs simulate successful verification.
    v_is_demo_rejection := (v_pan LIKE 'FAIL%') OR (pg_catalog.substr(v_pan, 4, 1) = 'X');

    IF v_is_demo_rejection THEN
        UPDATE public.producer_profiles
        SET pan_last4 = NULL,
            pan_hash = NULL,
            pan_verification_status = 'rejected'::public.verification_status
        WHERE id = v_uid;

        RETURN jsonb_build_object(
            'success', FALSE,
            'status', 'rejected',
            'record_status', 'simulated_failure',
            'message', 'PAN details could not be recorded in demo environment.',
            'pan_last4', NULL,
            'masked_pan', NULL
        );
    END IF;

    -- 9. Successful Verification: Persist artifacts for unverified caller
    UPDATE public.producer_profiles
    SET pan_last4 = v_last4,
        pan_hash = v_pan_hash,
        pan_verification_status = 'verified'::public.verification_status
    WHERE id = v_uid;

    -- 10. Return safe, structured result (Raw PAN is never returned)
    RETURN jsonb_build_object(
        'success', TRUE,
        'status', 'verified',
        'record_status', 'details_recorded',
        'message', 'PAN details recorded successfully in demo environment.',
        'pan_last4', v_last4,
        'masked_pan', v_masked_pan
    );
END;
$$;

-- ----------------------------------------------------------------------------
-- PRIVILEGES
-- ----------------------------------------------------------------------------
-- Revoke execution from PUBLIC and anon; grant execution only to authenticated.
REVOKE ALL ON FUNCTION public.verify_producer_pan_prototype(TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.verify_producer_pan_prototype(TEXT) TO authenticated;

COMMIT;

-- ============================================================================
-- VERIFICATION QUERIES (Run after executing migration)
-- ============================================================================
-- 1. Confirm only the 1-argument overload exists:
-- SELECT proname, proargnames, pronargs, prosrc
-- FROM pg_proc
-- WHERE proname = 'verify_producer_pan_prototype';
-- Expected: 1 row with pronargs = 1 and proargnames = '{p_pan}'.
--
-- 2. Confirm execute permissions:
-- SELECT grantee, privilege_type
-- FROM information_schema.routine_privileges
-- WHERE routine_name = 'verify_producer_pan_prototype';
-- Expected: 'authenticated' with 'EXECUTE', zero rows for 'anon' or 'PUBLIC'.
