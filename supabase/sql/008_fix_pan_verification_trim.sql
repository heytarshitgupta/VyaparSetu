-- ============================================================================
-- 008_fix_pan_verification_trim.sql
-- Module: VyaparSetu PAN Verification Prototype Fix (Step 4E2.5)
-- Description: Replaces public.verify_producer_pan_prototype(TEXT, TEXT, DATE)
--              to fix runtime error 42883 caused by pg_catalog.trim(text).
--              Replaces pg_catalog.trim with pg_catalog.btrim while preserving
--              all approved security, authorization, idempotency, row locking,
--              and verified identity conflict protection behaviors.
--
-- Background:
-- - Migration 006 executed successfully in Supabase, but calling the RPC at
--   runtime revealed that PostgreSQL's pg_catalog does not expose a function
--   named trim(text); the underlying two-sided trim implementation in pg_catalog
--   is btrim(text).
-- - This migration replaces the function body with pg_catalog.btrim without
--   modifying historical migration files 006 or 007.
-- ============================================================================

CREATE OR REPLACE FUNCTION public.verify_producer_pan_prototype(
    p_pan TEXT,
    p_name TEXT,
    p_dob DATE
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
    v_name TEXT;
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
            'message', 'Authentication required to verify PAN.'
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
            'message', 'Only registered producers can verify PAN identity.'
        );
    END IF;

    -- 3. Confirm caller row exists in public.producer_profiles and load current status
    SELECT pan_verification_status, pan_last4, pan_hash
    INTO v_current_status, v_current_last4, v_current_hash
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

    -- 4. Normalize inputs using pg_catalog.btrim (two-sided trim)
    v_pan := pg_catalog.upper(pg_catalog.btrim(COALESCE(p_pan, '')));
    v_name := pg_catalog.btrim(COALESCE(p_name, ''));

    -- 5. Validate PAN format: exactly 5 letters, 4 digits, 1 letter
    IF v_pan !~ '^[A-Z]{5}[0-9]{4}[A-Z]$' THEN
        RETURN jsonb_build_object(
            'success', FALSE,
            'status', 'invalid_format',
            'message', 'Invalid PAN format. Must be 10 characters (e.g. ABCDE1234F).'
        );
    END IF;

    -- 6. Validate Name as per PAN
    IF pg_catalog.length(v_name) < 2 OR pg_catalog.length(v_name) > 120 THEN
        RETURN jsonb_build_object(
            'success', FALSE,
            'status', 'invalid_name',
            'message', 'Name as per PAN must be between 2 and 120 characters.'
        );
    END IF;

    -- 7. Validate Date of Birth (must be historical date)
    IF p_dob IS NULL OR p_dob > CURRENT_DATE OR p_dob < DATE '1900-01-01' THEN
        RETURN jsonb_build_object(
            'success', FALSE,
            'status', 'invalid_dob',
            'message', 'Date of Birth must be a valid historical date.'
        );
    END IF;

    -- 8. Compute incoming normalized artifacts
    v_last4 := pg_catalog.right(v_pan, 4);
    v_pan_hash := pg_catalog.encode(
        pg_catalog.sha256((v_pan || ':' || v_uid::TEXT)::BYTEA),
        'hex'
    );
    v_masked_pan := '******' || v_last4;

    -- 9. Protect Already-Verified Identity
    IF v_current_status = 'verified'::public.verification_status THEN
        -- Case A: Same PAN details submitted -> Idempotent success
        IF v_current_hash IS NOT NULL AND v_current_hash = v_pan_hash THEN
            RETURN jsonb_build_object(
                'success', TRUE,
                'status', 'already_verified',
                'message', 'PAN is already verified for this account.',
                'pan_last4', v_current_last4,
                'masked_pan', '******' || COALESCE(v_current_last4, v_last4)
            );
        ELSE
            -- Case B: Different PAN submitted -> Conflict; preserve existing verified record
            RETURN jsonb_build_object(
                'success', FALSE,
                'status', 'already_verified_conflict',
                'message', 'A verified PAN is already associated with this account. Re-verification is required to change it.',
                'pan_last4', v_current_last4,
                'masked_pan', '******' || COALESCE(v_current_last4, '')
            );
        END IF;
    END IF;

    -- 10. Deterministic Demo Simulation Rule (Only for unverified / rejected callers)
    -- For evaluation & testing:
    -- - PAN starting with 'FAIL' (e.g. FAILA1234B) or having 4th letter 'X' (e.g. ABCXE1234F) simulates rejection.
    -- - All other format-valid PANs simulate successful verification.
    v_is_demo_rejection := (v_pan LIKE 'FAIL%') OR (pg_catalog.substr(v_pan, 4, 1) = 'X');

    IF v_is_demo_rejection THEN
        -- Record rejection only on non-verified profile
        UPDATE public.producer_profiles
        SET pan_last4 = NULL,
            pan_hash = NULL,
            pan_verification_status = 'rejected'::public.verification_status
        WHERE id = v_uid;

        RETURN jsonb_build_object(
            'success', FALSE,
            'status', 'rejected',
            'message', 'PAN details could not be verified with records in demo registry.',
            'pan_last4', NULL,
            'masked_pan', NULL
        );
    END IF;

    -- 11. Successful Verification: Persist artifacts for unverified caller
    UPDATE public.producer_profiles
    SET pan_last4 = v_last4,
        pan_hash = v_pan_hash,
        pan_verification_status = 'verified'::public.verification_status
    WHERE id = v_uid;

    -- 12. Return safe, structured result (Raw PAN is never returned)
    RETURN jsonb_build_object(
        'success', TRUE,
        'status', 'verified',
        'message', 'PAN verified successfully in demo environment.',
        'pan_last4', v_last4,
        'masked_pan', v_masked_pan
    );
END;
$$;

-- ----------------------------------------------------------------------------
-- PRIVILEGES
-- ----------------------------------------------------------------------------
-- Revoke execution from public/anon; grant execution only to authenticated.
REVOKE ALL ON FUNCTION public.verify_producer_pan_prototype(TEXT, TEXT, DATE) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.verify_producer_pan_prototype(TEXT, TEXT, DATE) TO authenticated;
