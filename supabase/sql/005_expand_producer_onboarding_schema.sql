-- ============================================================================
-- 005_expand_producer_onboarding_schema.sql
-- Module: VyaparSetu Producer Onboarding Data Model & Verification Expansion (Step 4B0.2)
-- Description: Expands public.producer_profiles with fields for Identity, Compliance,
--              GST, and granular verification statuses. Preserves existing data,
--              strictly protects onboarding_status and verification outcomes by
--              revoking direct client write privileges, and prohibits storage of
--              raw Aadhaar/PAN.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. CUSTOM ENUM FOR GST VERIFICATION
-- ----------------------------------------------------------------------------
-- Distinguishes non-GST registered producers ('not_applicable')
-- from GST-registered producers undergoing compliance verification.
DO $$ BEGIN
    CREATE TYPE public.gst_verification_status AS ENUM (
        'not_applicable',
        'unverified',
        'pending',
        'verified',
        'rejected'
    );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- ----------------------------------------------------------------------------
-- 2. EXPAND PRODUCER_PROFILES COLUMNS
-- ----------------------------------------------------------------------------
-- All columns are added with backward-compatible defaults to ensure existing
-- rows remain valid and undisturbed.

ALTER TABLE public.producer_profiles
    -- A. PAN Identity (Populated only via future trusted verification RPC; Zero plaintext PAN)
    ADD COLUMN IF NOT EXISTS pan_last4 VARCHAR(4),
    ADD COLUMN IF NOT EXISTS pan_hash TEXT,
    ADD COLUMN IF NOT EXISTS pan_verification_status public.verification_status NOT NULL DEFAULT 'unverified',

    -- B. Aadhaar Identity (Populated only via future trusted verification RPC; Raw Aadhaar strictly PROHIBITED)
    ADD COLUMN IF NOT EXISTS aadhaar_last4 VARCHAR(4),
    ADD COLUMN IF NOT EXISTS aadhaar_verification_reference TEXT,
    ADD COLUMN IF NOT EXISTS aadhaar_verification_status public.verification_status NOT NULL DEFAULT 'unverified',

    -- C. GST & Tax Compliance (User-declared compliance details)
    ADD COLUMN IF NOT EXISTS gst_registered BOOLEAN NOT NULL DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS gstin VARCHAR(15),
    ADD COLUMN IF NOT EXISTS gst_verification_status public.gst_verification_status NOT NULL DEFAULT 'not_applicable',

    -- D. Workshop Address Verification
    ADD COLUMN IF NOT EXISTS address_verification_status public.verification_status NOT NULL DEFAULT 'unverified';

-- ----------------------------------------------------------------------------
-- 3. DEFENSIVE CHECK CONSTRAINTS
-- ----------------------------------------------------------------------------
-- Validates data formats defensively without breaking incremental drafting.

DO $$ BEGIN
    ALTER TABLE public.producer_profiles
        ADD CONSTRAINT chk_producer_pan_last4
            CHECK (pan_last4 IS NULL OR pan_last4 ~ '^[0-9A-Za-z]{4}$');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    ALTER TABLE public.producer_profiles
        ADD CONSTRAINT chk_producer_pan_hash
            CHECK (pan_hash IS NULL OR pan_hash ~ '^[0-9a-fA-F]{64}$');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    ALTER TABLE public.producer_profiles
        ADD CONSTRAINT chk_producer_aadhaar_last4
            CHECK (aadhaar_last4 IS NULL OR aadhaar_last4 ~ '^[0-9]{4}$');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    ALTER TABLE public.producer_profiles
        ADD CONSTRAINT chk_producer_pincode
            CHECK (pincode = '' OR pincode ~ '^[1-9][0-9]{5}$');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    ALTER TABLE public.producer_profiles
        ADD CONSTRAINT chk_producer_gstin
            CHECK (gstin IS NULL OR gstin ~ '^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    ALTER TABLE public.producer_profiles
        ADD CONSTRAINT chk_producer_gst_consistency
            CHECK ((gst_registered = FALSE AND gstin IS NULL) OR (gst_registered = TRUE));
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- ----------------------------------------------------------------------------
-- 4. PRIVILEGE HARDENING & TRUST BOUNDARY ENFORCEMENT
-- ----------------------------------------------------------------------------
-- A. PROTECT ONBOARDING STATUS:
-- Revoke direct client INSERT and UPDATE on onboarding_status (granted in migration 001).
-- Onboarding state transitions (e.g. to 'completed') must be performed exclusively
-- through trusted backend RPC/workflow logic upon final validation.
REVOKE INSERT (onboarding_status), UPDATE (onboarding_status)
    ON TABLE public.producer_profiles
    FROM anon, authenticated, PUBLIC;

-- B. CLIENT-WRITABLE WHITELIST:
-- Authenticated clients can insert/update user-declared compliance inputs (gst_registered, gstin).
GRANT INSERT (
    gst_registered,
    gstin
) ON TABLE public.producer_profiles TO authenticated;

GRANT UPDATE (
    gst_registered,
    gstin
) ON TABLE public.producer_profiles TO authenticated;

-- C. TRUSTED-BACKEND-ONLY FIELDS:
-- The following columns have NO client INSERT/UPDATE grants and can only be
-- modified by trusted backend functions:
-- - onboarding_status
-- - verification_status
-- - pan_last4
-- - pan_hash
-- - pan_verification_status
-- - aadhaar_last4
-- - aadhaar_verification_reference
-- - aadhaar_verification_status
-- - gst_verification_status
-- - address_verification_status
