-- ============================================================================
-- 006_pan_verification_prototype.sql
-- Module: VyaparSetu Producer PAN Simulated Verification RPC (Step 4E2 / Step 4E2.3)
-- Description: Implements a secure, controlled, deterministic simulation RPC
--              for PAN verification in the prototype environment.
--
-- Security Guarantees & Architectural Boundaries:
-- 1. SECURITY DEFINER with search_path = '' and fully qualified object references.
-- 2. Caller identity is derived strictly from auth.uid(); client cannot supply user_id.
-- 3. Verifies caller role = 'producer' and caller row exists in producer_profiles.
-- 4. Raw 10-character PAN is NEVER stored in plaintext in any table or column.
-- 5. Stored artifacts are limited to:
--    - pan_last4: 4 alphanumeric chars matching chk_producer_pan_last4
--    - pan_hash: 64-hex SHA-256 digest matching chk_producer_pan_hash
--    - pan_verification_status: 'verified' or 'rejected'
-- 6. Raw PAN is NEVER returned in the RPC response; only masked PAN is returned.
-- 7. Prototype Pseudonymous Fingerprint:
--    - Uses pg_catalog.sha256((v_pan || ':' || v_uid::TEXT)::BYTEA).
--    - NOTE: This is an internal deduplication / integrity check for the prototype.
--      It is NOT encryption and is NOT secure against offline dictionary guessing
--      due to PAN's constrained search space. Production architecture must replace
--      this with a server-secret-keyed HMAC (HMAC-SHA256) or a secure tokenization
--      vault / provider reference.
-- 8. Protection of Verified Identity:
--    - If caller already has pan_verification_status = 'verified', a matching PAN
--      returns idempotent success ('already_verified').
--    - If a different PAN or a rejected PAN is submitted for an already-verified
--      account, the attempt is rejected ('already_verified_conflict') and existing
--      verified artifacts (pan_last4, pan_hash, pan_verification_status) are PRESERVED.
--      A failed retry can NEVER destroy an already-verified identity.
-- 9. Deterministic Demo Simulation Rule:
--    - PAN starting with 'FAIL' or having 4th character 'X' simulates a rejection.
--    - All other format-valid PANs simulate successful verification.
--    - Simulates mock registry records; does NOT connect to Income Tax Dept or GoI.
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
    v_current_last4 VARCHAR(4);
    v_current_hash TEXT;
    v_pan TEXT;
    v_name TEXT;
    v_last4 VARCHAR(4);
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
            'message', 'Only registered producers can verify PAN details.'
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

    -- 4. Normalize inputs
    v_pan := pg_catalog.upper(pg_catalog.trim(COALESCE(p_pan, '')));
    v_name := pg_catalog.trim(COALESCE(p_name, ''));

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
