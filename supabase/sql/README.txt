============================================================
SUPABASE SQL MIGRATIONS AND AUDIT HISTORY
============================================================

OVERVIEW
------------------------------------------------------------
This directory stores all version-controlled, auditable SQL migration
scripts executed for the VyaparSetu backend.


MIGRATION LOG
------------------------------------------------------------
1. 001_database_foundation.sql
   - Status: EXECUTED in Supabase SQL Editor (Step 2D).
   - Contains: Enums (user_role, onboarding_status, verification_status), tables (profiles, producer_profiles, app_sessions), updated_at trigger function, owner-only RLS policies, column privilege whitelists, partial unique active session index, and register_app_session() secure RPC.

2. 002_producer_auth_rpc.sql
   - Status: EXECUTED in Supabase SQL Editor (Step 3D).
   - Contains: Initial public.register_producer_profile(p_full_name TEXT) RPC with SECURITY DEFINER, search_path = '', auth.users metadata lookup, and strict Buyer/Admin role conversion rejection.
   - Note: Contained runtime pg_catalog.coalesce qualification error (42883).

3. 003_fix_producer_registration_rpc.sql
   - Status: EXECUTED in Supabase SQL Editor (Step 3L).
   - Contains: Fixed pg_catalog.coalesce usage with native COALESCE.
   - Note: Real runtime testing exposed secondary 42883 error on pg_catalog.trim(text).

4. 004_fix_producer_rpc_sql_expressions.sql
   - Status: EXECUTED AND LIVE VERIFIED in Supabase SQL Editor (Step 3N).
   - Contains: Comprehensive SQL-expression audit fixing TRIM, LENGTH, COALESCE, and CURRENT_TIMESTAMP to use standard PostgreSQL language constructs under empty search_path.

5. 005_expand_producer_onboarding_schema.sql
   - Status: EXECUTED in Supabase SQL Editor (Step 4B0.3).
   - Contains: Expands public.producer_profiles for Onboarding & Compliance. Creates gst_verification_status enum. Enforces strict trust boundaries: explicitly REVOKES direct client INSERT/UPDATE on onboarding_status (granted in 001); restricts client writes to declared inputs (gst_registered, gstin); keeps all identity artifacts (pan_last4, pan_hash, aadhaar_last4, aadhaar_verification_reference) and verification statuses strictly backend-only. Prohibits storage of raw Aadhaar.

6. 006_pan_verification_prototype.sql
   - Status: EXECUTED in Supabase SQL Editor (Step 4E2.3 / Step 4E2.4).
   - Contains: Secure SECURITY DEFINER function public.verify_producer_pan_prototype(p_pan TEXT, p_name TEXT, p_dob DATE) RETURNS JSONB.
   - Security & Correctness:
     * Uses auth.uid() exclusively; enforces search_path = ''.
     * Acquired FOR UPDATE row lock on caller's producer_profiles record.
     * Protection of Verified Identity: If caller is already verified, a matching PAN returns idempotent success ('already_verified'); a different or failing PAN returns 'already_verified_conflict' and NEVER destroys, erases, or alters verified artifacts.
     * Simulated rejection only applies to unverified or rejected accounts.
     * Raw PAN is never persisted and never returned.
     * Prototype Fingerprint Note: pg_catalog.sha256((v_pan || ':' || v_uid::TEXT)::BYTEA) is a prototype pseudonymous integrity fingerprint, not encryption or offline-secure protection. Production systems must use server-secret HMAC or tokenization vaults.
     * Runtime Note: Execution revealed secondary 42883 on pg_catalog.trim(text) inside the function body (which requires pg_catalog.btrim like Migration 007). Client error handling safely caught and sanitized the database error in UI without crashing.

7. 007_resumable_producer_onboarding.sql
   - Status: EXECUTED in Supabase SQL Editor (Step 4E2.4).
   - Contains: Adds onboarding_step SMALLINT NOT NULL DEFAULT 1 (CHECK 1 to 5) to public.producer_profiles. Deterministically backfills existing producer records based on saved drafts (Step 3 location -> 4, Step 2 craft -> 3, Step 1 basic -> 2, completed -> 5). Creates trusted public.advance_producer_onboarding_step(expected_current_step, next_step) SECURITY DEFINER RPC.
   - Security & Correctness:
     * Server-authoritative; no direct client UPDATE on onboarding_step (verified 42501).
     * Uses SELECT ... FOR UPDATE row locking.
     * Strictly enforces expected_current_step: guards against stale state and enforces single-step progression (next = expected + 1).
     * Server-Side Prerequisites: Validates saved database data (1->2 checks profiles.full_name; 2->3 checks producer_profiles business_name & craft_category; 3->4 checks location fields & pincode format using pg_catalog.btrim). Prevents skipping via repeated RPC calls.
     * Step 4 -> 5 Blocked: Verified live; returns 'identity_compliance_incomplete' with onboarding_step remaining 4.
     * Lifecycle Protection: If onboarding_status = 'completed', returns 'already_completed' without mutation. Never sets completed status.
     * Runtime Verified: Existing test producer was accurately backfilled to Step 4. Refreshing the browser or navigating Back preserves server progress at Step 4.

8. 008_fix_pan_verification_trim.sql
   - Status: EXECUTED in Supabase SQL Editor (Step 4E2.6).
   - Purpose: Migration 006 executed successfully in Supabase, but calling verify_producer_pan_prototype at runtime revealed an invalid pg_catalog.trim(text) call that raised PostgreSQL error 42883. Migration 008 replaced public.verify_producer_pan_prototype(TEXT, TEXT, DATE) using pg_catalog.btrim while leaving historical migrations 006 and 007 untouched.
   - Contains:
     * Replaces verify_producer_pan_prototype with pg_catalog.btrim for input normalization.
     * Preserves all approved security behavior: auth.uid() identity, producer role check, row locking (FOR UPDATE), PAN regex, name/DOB checks, prototype SHA-256 fingerprint, already_verified idempotency, already_verified_conflict protection, and unlogged raw PAN memory boundaries.
     * Reapplies REVOKE ALL from PUBLIC, anon and GRANT EXECUTE to authenticated.
   - Runtime Verified (Step 4E2.6):
     * Successful verification with demo PAN ABCDE1234F: pan_last4 set to '234F', pan_hash set to 64 hex characters, pan_verification_status = 'verified'.
     * Same-PAN submission returns 'already_verified' idempotently without data mutation.
     * Different-PAN submission (ABCDE5678G) returns 'already_verified_conflict' and protects original verified artifacts from overwrite.
     * Masked PAN ******234F persists correctly after page reload; raw PAN is never stored.

9. 009_create_products_schema.sql
   - Status: READY FOR EXECUTION in Supabase SQL Editor (Step 6B.1).
   - Contains: Creates public.product_status enum ('draft', 'active', 'hidden'), public.products table with FK to public.producer_profiles(id) ON DELETE CASCADE, defensive check constraints for non-empty name and positive price (active requires price, name >= 2, category >= 2), automated updated_at trigger, indexes on producer_id, (producer_id, status), and created_at, and strict owner-only RLS policies (SELECT, INSERT, UPDATE, DELETE strictly scoped to auth.uid() = producer_id). Active products remain owner-only in this milestone; Buyer marketplace access and Supabase Storage bucket integration are explicitly deferred.

