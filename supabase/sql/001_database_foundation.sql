-- ============================================================================
-- 001_database_foundation.sql
-- Module: VyaparSetu Database Foundation (Step 2C - Hardened)
-- Description: Core custom types, user profiles, producer profiles,
--              single-active-session concurrency tracking, strict private RLS,
--              explicit column-level privilege whitelist, and secure session management.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. CUSTOM ENUMS
-- ----------------------------------------------------------------------------

-- Defines available user personas in VyaparSetu
CREATE TYPE public.user_role AS ENUM (
    'buyer',
    'producer',
    'admin'
);

-- Tracks progression through the Producer profile creation wizard
CREATE TYPE public.onboarding_status AS ENUM (
    'not_started',
    'in_progress',
    'completed'
);

-- Governs trust level and verification tier for Producers
CREATE TYPE public.verification_status AS ENUM (
    'unverified',
    'pending',
    'verified',
    'rejected'
);

-- ----------------------------------------------------------------------------
-- 2. AUTOMATED TIMESTAMP TRIGGER FUNCTION
-- ----------------------------------------------------------------------------
-- Uses empty search_path and schema-qualified references for security.

CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = ''
AS $$
BEGIN
    NEW.updated_at = pg_catalog.now();
    RETURN NEW;
END;
$$;

-- ----------------------------------------------------------------------------
-- 3. PROFILES TABLE (Shared User Identity)
-- ----------------------------------------------------------------------------
-- Extends auth.users with public profile metadata.
-- auth.users remains the sole authentication authority; phone/email here are
-- non-authoritative profile copies.

CREATE TABLE public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    phone TEXT,
    email TEXT,
    full_name TEXT NOT NULL DEFAULT '',
    role public.user_role NOT NULL DEFAULT 'buyer',
    avatar_url TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT pg_catalog.now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT pg_catalog.now()
);

CREATE INDEX idx_profiles_role ON public.profiles(role);

CREATE TRIGGER trg_profiles_updated_at
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

-- ----------------------------------------------------------------------------
-- 4. PRODUCER_PROFILES TABLE (Producer Domain Specifics)
-- ----------------------------------------------------------------------------
-- Stores craft categories, business details, and onboarding/verification state.
-- Sensitive identity data (raw Aadhaar/PAN) is strictly excluded.

CREATE TABLE public.producer_profiles (
    id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
    business_name TEXT NOT NULL DEFAULT '',
    craft_category TEXT NOT NULL DEFAULT '',
    bio TEXT,
    state TEXT NOT NULL DEFAULT '',
    district TEXT NOT NULL DEFAULT '',
    city TEXT NOT NULL DEFAULT '',
    pincode TEXT NOT NULL DEFAULT '',
    address TEXT,
    onboarding_status public.onboarding_status NOT NULL DEFAULT 'not_started',
    verification_status public.verification_status NOT NULL DEFAULT 'unverified',
    created_at TIMESTAMPTZ NOT NULL DEFAULT pg_catalog.now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT pg_catalog.now()
);

CREATE INDEX idx_producer_profiles_craft ON public.producer_profiles(craft_category);
CREATE INDEX idx_producer_profiles_verification ON public.producer_profiles(verification_status);

CREATE TRIGGER trg_producer_profiles_updated_at
    BEFORE UPDATE ON public.producer_profiles
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

-- ----------------------------------------------------------------------------
-- 5. APP_SESSIONS TABLE (Single-Active-Session Tracking)
-- ----------------------------------------------------------------------------
-- Tracks session token hashes. Plaintext tokens are never stored.
-- Hash format is strictly constrained to 64 hexadecimal characters.
-- device_info is bounded untrusted informational metadata.

CREATE TABLE public.app_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    session_token_hash TEXT NOT NULL,
    device_info VARCHAR(255),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT pg_catalog.now(),
    last_active_at TIMESTAMPTZ NOT NULL DEFAULT pg_catalog.now(),
    revoked_at TIMESTAMPTZ,
    CONSTRAINT chk_app_sessions_hash_format
        CHECK (session_token_hash ~ '^[0-9a-fA-F]{64}$')
);

-- CRITICAL: Partial unique index guarantees that no user can have more than
-- one active session row in PostgreSQL concurrently.
CREATE UNIQUE INDEX idx_app_sessions_single_active_user
    ON public.app_sessions(user_id)
    WHERE (is_active = TRUE);

CREATE INDEX idx_app_sessions_token_hash
    ON public.app_sessions(session_token_hash);

-- ----------------------------------------------------------------------------
-- 6. ROW LEVEL SECURITY (Strictly Private-by-Default)
-- ----------------------------------------------------------------------------
-- RLS is row-level, not column-level. Therefore, foundation tables are private
-- to their owner. Public listings will be served via column-filtered views later.

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.producer_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.app_sessions ENABLE ROW LEVEL SECURITY;

-- A. profiles RLS policies
CREATE POLICY "profiles_select_own"
    ON public.profiles
    FOR SELECT
    TO authenticated
    USING (auth.uid() = id);

CREATE POLICY "profiles_insert_own"
    ON public.profiles
    FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = id);

CREATE POLICY "profiles_update_own"
    ON public.profiles
    FOR UPDATE
    TO authenticated
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- B. producer_profiles RLS policies
CREATE POLICY "producer_profiles_select_own"
    ON public.producer_profiles
    FOR SELECT
    TO authenticated
    USING (auth.uid() = id);

CREATE POLICY "producer_profiles_insert_own"
    ON public.producer_profiles
    FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = id);

CREATE POLICY "producer_profiles_update_own"
    ON public.producer_profiles
    FOR UPDATE
    TO authenticated
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- C. app_sessions RLS policies (SELECT only for owner; mutations via secure RPC)
CREATE POLICY "app_sessions_select_own"
    ON public.app_sessions
    FOR SELECT
    TO authenticated
    USING (auth.uid() = user_id);

-- ----------------------------------------------------------------------------
-- 7. EXPLICIT PRIVILEGE RESET & COLUMN-LEVEL WHITELIST
-- ----------------------------------------------------------------------------

-- Step 7A: Explicitly REVOKE all table-level privileges from anon, authenticated, PUBLIC
REVOKE ALL ON TABLE public.profiles FROM anon, authenticated, PUBLIC;
REVOKE ALL ON TABLE public.producer_profiles FROM anon, authenticated, PUBLIC;
REVOKE ALL ON TABLE public.app_sessions FROM anon, authenticated, PUBLIC;

-- Step 7B: Grant SELECT on tables for authenticated (filtered by RLS)
GRANT SELECT ON TABLE public.profiles TO authenticated;
GRANT SELECT ON TABLE public.producer_profiles TO authenticated;
GRANT SELECT ON TABLE public.app_sessions TO authenticated;

-- Step 7C: Whitelist column-level INSERT and UPDATE privileges for public.profiles
-- Note: 'role', 'created_at', 'updated_at' are deliberately EXCLUDED.
-- 'role' defaults to 'buyer' and can only be modified via future trusted functions.
GRANT INSERT (
    id,
    phone,
    email,
    full_name,
    avatar_url
) ON TABLE public.profiles TO authenticated;

GRANT UPDATE (
    phone,
    email,
    full_name,
    avatar_url
) ON TABLE public.profiles TO authenticated;

-- Step 7D: Whitelist column-level INSERT and UPDATE privileges for public.producer_profiles
-- Note: 'verification_status', 'created_at', 'updated_at' are deliberately EXCLUDED.
-- 'verification_status' defaults to 'unverified' and cannot be self-escalated.
GRANT INSERT (
    id,
    business_name,
    craft_category,
    bio,
    state,
    district,
    city,
    pincode,
    address,
    onboarding_status
) ON TABLE public.producer_profiles TO authenticated;

GRANT UPDATE (
    business_name,
    craft_category,
    bio,
    state,
    district,
    city,
    pincode,
    address,
    onboarding_status
) ON TABLE public.producer_profiles TO authenticated;

-- ----------------------------------------------------------------------------
-- 8. SECURE SESSION REGISTRATION FUNCTION
-- ----------------------------------------------------------------------------
-- Atomically deactivates previous active sessions for the authenticated caller
-- and inserts a new single active session row.
-- Uses empty search_path, schema-qualified references, and strict input checks.

CREATE OR REPLACE FUNCTION public.register_app_session(
    p_session_token_hash TEXT,
    p_device_info TEXT DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    v_user_id UUID;
    v_new_session_id UUID;
    v_sanitized_device_info VARCHAR(255);
BEGIN
    -- 1. Enforce authentication: Resolve user identity exclusively from auth context
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Authentication required: auth.uid() is null';
    END IF;

    -- 2. Validate session token hash format (strictly 64 hexadecimal characters)
    IF p_session_token_hash IS NULL OR p_session_token_hash !~ '^[0-9a-fA-F]{64}$' THEN
        RAISE EXCEPTION 'Invalid session token hash format: must be 64 hexadecimal characters';
    END IF;

    -- 3. Sanitize and bound untrusted device info metadata (max 255 chars)
    IF p_device_info IS NOT NULL THEN
        v_sanitized_device_info := pg_catalog.substr(pg_catalog.trim(p_device_info), 1, 255);
    ELSE
        v_sanitized_device_info := NULL;
    END IF;

    -- 4. Atomically deactivate any active sessions for this user
    UPDATE public.app_sessions
    SET is_active = FALSE,
        revoked_at = pg_catalog.now()
    WHERE user_id = v_user_id
      AND is_active = TRUE;

    -- 5. Insert the new single active session
    INSERT INTO public.app_sessions (
        user_id,
        session_token_hash,
        device_info,
        is_active,
        created_at,
        last_active_at
    ) VALUES (
        v_user_id,
        p_session_token_hash,
        v_sanitized_device_info,
        TRUE,
        pg_catalog.now(),
        pg_catalog.now()
    )
    RETURNING id INTO v_new_session_id;

    RETURN v_new_session_id;
END;
$$;

-- Secure execution permissions: Revoke all from PUBLIC and anon, grant to authenticated only
REVOKE ALL ON FUNCTION public.register_app_session(TEXT, TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.register_app_session(TEXT, TEXT) TO authenticated;
