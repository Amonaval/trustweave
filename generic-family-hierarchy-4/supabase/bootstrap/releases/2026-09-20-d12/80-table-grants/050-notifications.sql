-- TRUSTWEAVE D12 CANONICAL CURRENT-STATE BASELINE.
-- Materialized after fresh-project structural/security/API/behavior/product parity on 2026-09-20.
-- DO NOT apply these files to the historical golden project as an upgrade sequence.
-- Historical supabase/migrations/001..123 remain immutable upgrade history.

REVOKE ALL ON TABLE "public"."network_notification_roles" FROM PUBLIC, "anon", "authenticated", "service_role";
REVOKE ALL ON TABLE "public"."notification_preferences" FROM PUBLIC, "anon", "authenticated", "service_role";
REVOKE ALL ON TABLE "public"."notifications" FROM PUBLIC, "anon", "authenticated", "service_role";
REVOKE ALL ON TABLE "public"."push_subscriptions" FROM PUBLIC, "anon", "authenticated", "service_role";
GRANT SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER ON TABLE "public"."network_notification_roles" TO "postgres" WITH GRANT OPTION;
GRANT SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER ON TABLE "public"."network_notification_roles" TO "service_role";
GRANT SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER ON TABLE "public"."notification_preferences" TO "postgres" WITH GRANT OPTION;
GRANT SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER ON TABLE "public"."notification_preferences" TO "service_role";
GRANT SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER ON TABLE "public"."notifications" TO "anon";
GRANT SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER ON TABLE "public"."notifications" TO "postgres" WITH GRANT OPTION;
GRANT SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER ON TABLE "public"."notifications" TO "service_role";
GRANT SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER ON TABLE "public"."push_subscriptions" TO "postgres" WITH GRANT OPTION;
GRANT SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER ON TABLE "public"."push_subscriptions" TO "service_role";
