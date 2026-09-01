-- ============================================================================
-- 004_fix_producer_rpc_sql_expressions.sql
-- Module: VyaparSetu Producer Authentication RPC Audit & Fix (Step 3M)
-- Description: Completely fixes PostgreSQL string function resolution (error 42883)
--              under empty search_path by using standard SQL constructs (TRIM,
--              LENGTH, COALESCE, CURRENT_TIMESTAMP) instead of invalid
--              pg_catalog.trim / pg_catalog.coalesce calls, while preserving
--              all security hardening (SECURITY DEFINER, SET search_path = '',
--              schema-qualified types, auth.users sync, and role boundaries).
-- ============================================================================

CREATE OR REPLACE FUNCTION public.register_producer_profile(
    p_full_name TEXT DEFAULT ''
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    v_user_id UUID;
    v_auth_email TEXT;
    v_auth_phone TEXT;
    v_normalized_name TEXT;
    v_existing_role public.user_role;
    v_existing_name TEXT;
BEGIN
    -- 1. Enforce authentication: Derive caller identity strictly from auth context
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Authentication required: auth.uid() is null';
    END IF;

    -- 2. Fetch authoritative identity metadata directly from auth.users
    SELECT email, phone
    INTO v_auth_email, v_auth_phone
    FROM auth.users
    WHERE id = v_user_id;

    -- 3. Normalize input name using standard SQL TRIM and COALESCE
    v_normalized_name := TRIM(COALESCE(p_full_name, ''));

    -- 4. Inspect existing profile record and role
    SELECT role, full_name
    INTO v_existing_role, v_existing_name
    FROM public.profiles
    WHERE id = v_user_id;

    -- 5. Enforce strict role boundary policy
    IF v_existing_role IS NOT NULL THEN
        -- A. Reject existing Buyer accounts (Conversion not supported in this phase)
        IF v_existing_role = 'buyer'::public.user_role THEN
            RAISE EXCEPTION 'Account already registered as Buyer. Role conversion to Producer is not supported.';
        END IF;

        -- B. Reject Admin accounts
        IF v_existing_role = 'admin'::public.user_role THEN
            RAISE EXCEPTION 'Admin accounts cannot register as Producer.';
        END IF;
    END IF;

    -- 6. Validate full_name for initial profile creation
    IF v_existing_role IS NULL THEN
        IF LENGTH(v_normalized_name) < 2 OR LENGTH(v_normalized_name) > 120 THEN
            RAISE EXCEPTION 'Full name must be between 2 and 120 characters.';
        END IF;

        -- Create initial profile row with role = 'producer'
        INSERT INTO public.profiles (
            id,
            phone,
            email,
            full_name,
            role,
            created_at,
            updated_at
        ) VALUES (
            v_user_id,
            v_auth_phone,
            v_auth_email,
            v_normalized_name,
            'producer'::public.user_role,
            CURRENT_TIMESTAMP,
            CURRENT_TIMESTAMP
        );
    ELSE
        -- Existing Producer: idempotent update (do not overwrite with invalid/empty name)
        UPDATE public.profiles
        SET full_name = CASE
                WHEN LENGTH(v_normalized_name) >= 2 AND LENGTH(v_normalized_name) <= 120
                    THEN v_normalized_name
                ELSE full_name
            END,
            email = COALESCE(v_auth_email, email),
            phone = COALESCE(v_auth_phone, phone),
            updated_at = CURRENT_TIMESTAMP
        WHERE id = v_user_id;
    END IF;

    -- 7. Ensure public.producer_profiles exists (idempotent; preserves existing progress)
    INSERT INTO public.producer_profiles (
        id,
        business_name,
        craft_category,
        onboarding_status,
        verification_status,
        created_at,
        updated_at
    ) VALUES (
        v_user_id,
        '',
        '',
        'not_started'::public.onboarding_status,
        'unverified'::public.verification_status,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP
    )
    ON CONFLICT (id) DO NOTHING;

    -- 8. Return the authenticated user UUID
    RETURN v_user_id;
END;
$$;

-- ----------------------------------------------------------------------------
-- EXECUTION PRIVILEGE HARDENING
-- ----------------------------------------------------------------------------
REVOKE ALL ON FUNCTION public.register_producer_profile(TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.register_producer_profile(TEXT) TO authenticated;
