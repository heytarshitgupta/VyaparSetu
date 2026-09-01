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
