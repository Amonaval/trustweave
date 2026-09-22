-- TRUSTWEAVE D12 CANONICAL CURRENT-STATE BASELINE.
-- Materialized after fresh-project structural/security/API/behavior/product parity on 2026-09-20.
-- DO NOT apply these files to the historical golden project as an upgrade sequence.
-- Historical supabase/migrations/001..123 remain immutable upgrade history.
REVOKE ALL ON TABLE "public"."association_household_admins" FROM PUBLIC, "anon", "authenticated", "service_role", "postgres";
GRANT INSERT, SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER, MAINTAIN ON TABLE "public"."association_household_admins" TO "postgres";
GRANT INSERT, SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER, MAINTAIN ON TABLE "public"."association_household_admins" TO "service_role";
REVOKE ALL ON TABLE "public"."family_association_awards" FROM PUBLIC, "anon", "authenticated", "service_role", "postgres";
GRANT INSERT, SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER, MAINTAIN ON TABLE "public"."family_association_awards" TO "postgres";
GRANT INSERT, SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER, MAINTAIN ON TABLE "public"."family_association_awards" TO "service_role";
REVOKE ALL ON TABLE "public"."family_association_family_memberships" FROM PUBLIC, "anon", "authenticated", "service_role", "postgres";
GRANT INSERT, SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER, MAINTAIN ON TABLE "public"."family_association_family_memberships" TO "postgres";
GRANT INSERT, SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER, MAINTAIN ON TABLE "public"."family_association_family_memberships" TO "service_role";
REVOKE ALL ON TABLE "public"."family_association_finance_ledger" FROM PUBLIC, "anon", "authenticated", "service_role", "postgres";
GRANT INSERT, SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER, MAINTAIN ON TABLE "public"."family_association_finance_ledger" TO "postgres";
GRANT INSERT, SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER, MAINTAIN ON TABLE "public"."family_association_finance_ledger" TO "service_role";
REVOKE ALL ON TABLE "public"."family_association_membership_years" FROM PUBLIC, "anon", "authenticated", "service_role", "postgres";
GRANT INSERT, SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER, MAINTAIN ON TABLE "public"."family_association_membership_years" TO "postgres";
GRANT INSERT, SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER, MAINTAIN ON TABLE "public"."family_association_membership_years" TO "service_role";
REVOKE ALL ON TABLE "public"."family_association_role_catalog" FROM PUBLIC, "anon", "authenticated", "service_role", "postgres";
GRANT INSERT, SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER, MAINTAIN ON TABLE "public"."family_association_role_catalog" TO "postgres";
GRANT INSERT, SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER, MAINTAIN ON TABLE "public"."family_association_role_catalog" TO "service_role";
REVOKE ALL ON TABLE "public"."family_association_role_history" FROM PUBLIC, "anon", "authenticated", "service_role", "postgres";
GRANT INSERT, SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER, MAINTAIN ON TABLE "public"."family_association_role_history" TO "postgres";
GRANT INSERT, SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER, MAINTAIN ON TABLE "public"."family_association_role_history" TO "service_role";
REVOKE ALL ON TABLE "public"."family_association_settings" FROM PUBLIC, "anon", "authenticated", "service_role", "postgres";
GRANT INSERT, SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER, MAINTAIN ON TABLE "public"."family_association_settings" TO "postgres";
GRANT INSERT, SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER, MAINTAIN ON TABLE "public"."family_association_settings" TO "service_role";
