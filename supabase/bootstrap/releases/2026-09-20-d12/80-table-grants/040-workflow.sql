-- TRUSTWEAVE D12 CANONICAL CURRENT-STATE BASELINE.
-- Materialized after fresh-project structural/security/API/behavior/product parity on 2026-09-20.
-- DO NOT apply these files to the historical golden project as an upgrade sequence.
-- Historical supabase/migrations/001..123 remain immutable upgrade history.
REVOKE ALL ON TABLE "public"."api_command_idempotency" FROM PUBLIC, "anon", "authenticated", "service_role", "postgres";
GRANT INSERT, SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER, MAINTAIN ON TABLE "public"."api_command_idempotency" TO "postgres";
GRANT INSERT, SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER, MAINTAIN ON TABLE "public"."api_command_idempotency" TO "service_role";
REVOKE ALL ON TABLE "public"."change_requests" FROM PUBLIC, "anon", "authenticated", "service_role", "postgres";
GRANT INSERT, SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER, MAINTAIN ON TABLE "public"."change_requests" TO "postgres";
GRANT INSERT, SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER, MAINTAIN ON TABLE "public"."change_requests" TO "anon";
GRANT SELECT, TRUNCATE, REFERENCES, TRIGGER, MAINTAIN ON TABLE "public"."change_requests" TO "authenticated";
GRANT INSERT, SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER, MAINTAIN ON TABLE "public"."change_requests" TO "service_role";
REVOKE ALL ON TABLE "public"."contribution_suggestions" FROM PUBLIC, "anon", "authenticated", "service_role", "postgres";
GRANT INSERT, SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER, MAINTAIN ON TABLE "public"."contribution_suggestions" TO "postgres";
GRANT INSERT, SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER, MAINTAIN ON TABLE "public"."contribution_suggestions" TO "service_role";
REVOKE ALL ON TABLE "public"."guide_feedback" FROM PUBLIC, "anon", "authenticated", "service_role", "postgres";
GRANT INSERT, SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER, MAINTAIN ON TABLE "public"."guide_feedback" TO "postgres";
GRANT INSERT, SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER, MAINTAIN ON TABLE "public"."guide_feedback" TO "service_role";
REVOKE ALL ON TABLE "public"."network_ballot_eligibility" FROM PUBLIC, "anon", "authenticated", "service_role", "postgres";
GRANT INSERT, SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER, MAINTAIN ON TABLE "public"."network_ballot_eligibility" TO "postgres";
GRANT INSERT, SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER, MAINTAIN ON TABLE "public"."network_ballot_eligibility" TO "service_role";
REVOKE ALL ON TABLE "public"."network_ballot_nominations" FROM PUBLIC, "anon", "authenticated", "service_role", "postgres";
GRANT INSERT, SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER, MAINTAIN ON TABLE "public"."network_ballot_nominations" TO "postgres";
GRANT INSERT, SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER, MAINTAIN ON TABLE "public"."network_ballot_nominations" TO "service_role";
REVOKE ALL ON TABLE "public"."network_ballot_options" FROM PUBLIC, "anon", "authenticated", "service_role", "postgres";
GRANT INSERT, SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER, MAINTAIN ON TABLE "public"."network_ballot_options" TO "postgres";
GRANT INSERT, SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER, MAINTAIN ON TABLE "public"."network_ballot_options" TO "service_role";
REVOKE ALL ON TABLE "public"."network_ballot_participation" FROM PUBLIC, "anon", "authenticated", "service_role", "postgres";
GRANT INSERT, SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER, MAINTAIN ON TABLE "public"."network_ballot_participation" TO "postgres";
GRANT INSERT, SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER, MAINTAIN ON TABLE "public"."network_ballot_participation" TO "service_role";
REVOKE ALL ON TABLE "public"."network_ballot_votes" FROM PUBLIC, "anon", "authenticated", "service_role", "postgres";
GRANT INSERT, SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER, MAINTAIN ON TABLE "public"."network_ballot_votes" TO "postgres";
GRANT INSERT, SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER, MAINTAIN ON TABLE "public"."network_ballot_votes" TO "service_role";
REVOKE ALL ON TABLE "public"."network_ballots" FROM PUBLIC, "anon", "authenticated", "service_role", "postgres";
GRANT INSERT, SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER, MAINTAIN ON TABLE "public"."network_ballots" TO "postgres";
GRANT INSERT, SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER, MAINTAIN ON TABLE "public"."network_ballots" TO "service_role";
REVOKE ALL ON TABLE "public"."network_fund_transactions" FROM PUBLIC, "anon", "authenticated", "service_role", "postgres";
GRANT INSERT, SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER, MAINTAIN ON TABLE "public"."network_fund_transactions" TO "postgres";
GRANT INSERT, SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER, MAINTAIN ON TABLE "public"."network_fund_transactions" TO "service_role";
REVOKE ALL ON TABLE "public"."network_funds" FROM PUBLIC, "anon", "authenticated", "service_role", "postgres";
GRANT INSERT, SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER, MAINTAIN ON TABLE "public"."network_funds" TO "postgres";
GRANT INSERT, SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER, MAINTAIN ON TABLE "public"."network_funds" TO "service_role";
