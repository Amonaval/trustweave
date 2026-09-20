-- TRUSTWEAVE D12 CANONICAL CURRENT-STATE BASELINE.
-- Materialized after fresh-project structural/security/API/behavior/product parity on 2026-09-20.
-- DO NOT apply these files to the historical golden project as an upgrade sequence.
-- Historical supabase/migrations/001..123 remain immutable upgrade history.

REVOKE ALL ON TABLE "public"."alumni_connections" FROM PUBLIC, "anon", "authenticated", "service_role";
REVOKE ALL ON TABLE "public"."alumni_invitations" FROM PUBLIC, "anon", "authenticated", "service_role";
REVOKE ALL ON TABLE "public"."alumni_network_settings" FROM PUBLIC, "anon", "authenticated", "service_role";
REVOKE ALL ON TABLE "public"."alumni_profiles" FROM PUBLIC, "anon", "authenticated", "service_role";
REVOKE ALL ON TABLE "public"."organization_intelligence_query_signals" FROM PUBLIC, "anon", "authenticated", "service_role";
GRANT SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER ON TABLE "public"."alumni_connections" TO "postgres" WITH GRANT OPTION;
GRANT SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER ON TABLE "public"."alumni_connections" TO "service_role";
GRANT SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER ON TABLE "public"."alumni_invitations" TO "postgres" WITH GRANT OPTION;
GRANT SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER ON TABLE "public"."alumni_invitations" TO "service_role";
GRANT SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER ON TABLE "public"."alumni_network_settings" TO "postgres" WITH GRANT OPTION;
GRANT SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER ON TABLE "public"."alumni_network_settings" TO "service_role";
GRANT SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER ON TABLE "public"."alumni_profiles" TO "postgres" WITH GRANT OPTION;
GRANT SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER ON TABLE "public"."alumni_profiles" TO "service_role";
GRANT SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER ON TABLE "public"."organization_intelligence_query_signals" TO "anon";
GRANT SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER ON TABLE "public"."organization_intelligence_query_signals" TO "authenticated";
GRANT SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER ON TABLE "public"."organization_intelligence_query_signals" TO "postgres" WITH GRANT OPTION;
GRANT SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER ON TABLE "public"."organization_intelligence_query_signals" TO "service_role";
