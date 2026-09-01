============================================================
SUPABASE SQL MIGRATIONS AND AUDIT HISTORY
============================================================

OVERVIEW
------------------------------------------------------------
This directory stores all version-controlled, auditable SQL migration
scripts executed for the VyaparSetu backend.


INTENDED SQL WORKFLOW
------------------------------------------------------------
1. Numbered SQL Files: All SQL statements (tables, foreign keys, triggers, functions, RLS policies) must be drafted and reviewed in sequentially numbered repository files.
   Example naming convention:
   - 001_initial_schema.sql
   - 002_auth_sessions.sql
   - 003_producer_profiles.sql
   - 004_products_and_storage.sql

2. Review and Execution: Reviewed SQL scripts will initially be executed through the Supabase SQL Editor dashboard.

3. Auditable Source of Truth: The exact SQL executed against the Supabase database must remain permanently committed in this Git repository.

4. CLI Compatibility: The numbered file convention ensures seamless future migration to the official Supabase CLI migrations workflow if desired.


STATUS NOTE
------------------------------------------------------------
No production SQL has been executed as part of this setup step.
