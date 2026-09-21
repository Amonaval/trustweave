-- TRUSTWEAVE D12 CANONICAL CURRENT-STATE BASELINE.
-- Materialized after fresh-project structural/security/API/behavior/product parity on 2026-09-20.
-- DO NOT apply these files to the historical golden project as an upgrade sequence.
-- Historical supabase/migrations/001..123 remain immutable upgrade history.
REVOKE ALL ON TABLE "public"."cross_network_discovery_candidates" FROM PUBLIC, "anon", "authenticated", "service_role", "postgres";
GRANT INSERT, SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER, MAINTAIN ON TABLE "public"."cross_network_discovery_candidates" TO "postgres";
GRANT INSERT, SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER, MAINTAIN ON TABLE "public"."cross_network_discovery_candidates" TO "service_role";
REVOKE ALL ON TABLE "public"."federated_introduction_outcomes" FROM PUBLIC, "anon", "authenticated", "service_role", "postgres";
GRANT INSERT, SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER, MAINTAIN ON TABLE "public"."federated_introduction_outcomes" TO "postgres";
GRANT INSERT, SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER, MAINTAIN ON TABLE "public"."federated_introduction_outcomes" TO "service_role";
REVOKE ALL ON TABLE "public"."federated_introductions" FROM PUBLIC, "anon", "authenticated", "service_role", "postgres";
GRANT INSERT, SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER, MAINTAIN ON TABLE "public"."federated_introductions" TO "postgres";
GRANT INSERT, SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER, MAINTAIN ON TABLE "public"."federated_introductions" TO "service_role";
REVOKE ALL ON TABLE "public"."federated_request_routes" FROM PUBLIC, "anon", "authenticated", "service_role", "postgres";
GRANT INSERT, SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER, MAINTAIN ON TABLE "public"."federated_request_routes" TO "postgres";
GRANT INSERT, SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER, MAINTAIN ON TABLE "public"."federated_request_routes" TO "service_role";
REVOKE ALL ON TABLE "public"."federated_requests" FROM PUBLIC, "anon", "authenticated", "service_role", "postgres";
GRANT INSERT, SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER, MAINTAIN ON TABLE "public"."federated_requests" TO "postgres";
GRANT INSERT, SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER, MAINTAIN ON TABLE "public"."federated_requests" TO "service_role";
REVOKE ALL ON TABLE "public"."federated_scope_profiles" FROM PUBLIC, "anon", "authenticated", "service_role", "postgres";
GRANT INSERT, SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER, MAINTAIN ON TABLE "public"."federated_scope_profiles" TO "postgres";
GRANT INSERT, SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER, MAINTAIN ON TABLE "public"."federated_scope_profiles" TO "service_role";
REVOKE ALL ON TABLE "public"."federated_trust_receipts" FROM PUBLIC, "anon", "authenticated", "service_role", "postgres";
GRANT INSERT, SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER, MAINTAIN ON TABLE "public"."federated_trust_receipts" TO "postgres";
GRANT INSERT, SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER, MAINTAIN ON TABLE "public"."federated_trust_receipts" TO "service_role";
REVOKE ALL ON TABLE "public"."federation_umbrella_admins" FROM PUBLIC, "anon", "authenticated", "service_role", "postgres";
GRANT INSERT, SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER, MAINTAIN ON TABLE "public"."federation_umbrella_admins" TO "postgres";
GRANT INSERT, SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER, MAINTAIN ON TABLE "public"."federation_umbrella_admins" TO "service_role";
REVOKE ALL ON TABLE "public"."federation_umbrellas" FROM PUBLIC, "anon", "authenticated", "service_role", "postgres";
GRANT INSERT, SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER, MAINTAIN ON TABLE "public"."federation_umbrellas" TO "postgres";
GRANT INSERT, SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER, MAINTAIN ON TABLE "public"."federation_umbrellas" TO "service_role";
REVOKE ALL ON TABLE "public"."network_effect_events" FROM PUBLIC, "anon", "authenticated", "service_role", "postgres";
GRANT INSERT, SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER, MAINTAIN ON TABLE "public"."network_effect_events" TO "postgres";
GRANT INSERT, SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER, MAINTAIN ON TABLE "public"."network_effect_events" TO "service_role";
REVOKE ALL ON TABLE "public"."network_passports" FROM PUBLIC, "anon", "authenticated", "service_role", "postgres";
GRANT INSERT, SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER, MAINTAIN ON TABLE "public"."network_passports" TO "postgres";
GRANT INSERT, SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER, MAINTAIN ON TABLE "public"."network_passports" TO "service_role";
REVOKE ALL ON TABLE "public"."network_trust_bridges" FROM PUBLIC, "anon", "authenticated", "service_role", "postgres";
GRANT INSERT, SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER, MAINTAIN ON TABLE "public"."network_trust_bridges" TO "postgres";
GRANT INSERT, SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER, MAINTAIN ON TABLE "public"."network_trust_bridges" TO "service_role";
REVOKE ALL ON TABLE "public"."network_umbrella_affiliations" FROM PUBLIC, "anon", "authenticated", "service_role", "postgres";
GRANT INSERT, SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER, MAINTAIN ON TABLE "public"."network_umbrella_affiliations" TO "postgres";
GRANT INSERT, SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER, MAINTAIN ON TABLE "public"."network_umbrella_affiliations" TO "service_role";
REVOKE ALL ON TABLE "public"."trusted_introduction_requests" FROM PUBLIC, "anon", "authenticated", "service_role", "postgres";
GRANT INSERT, SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER, MAINTAIN ON TABLE "public"."trusted_introduction_requests" TO "postgres";
GRANT INSERT, SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER, MAINTAIN ON TABLE "public"."trusted_introduction_requests" TO "service_role";
