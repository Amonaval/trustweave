-- TRUSTWEAVE D12 CANONICAL CURRENT-STATE BASELINE.
-- Materialized after fresh-project structural/security/API/behavior/product parity on 2026-09-20.
-- DO NOT apply these files to the historical golden project as an upgrade sequence.
-- Historical supabase/migrations/001..123 remain immutable upgrade history.

ALTER TABLE "public"."api_command_idempotency" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."change_requests" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."contribution_suggestions" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."guide_feedback" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."network_ballot_eligibility" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."network_ballot_nominations" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."network_ballot_options" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."network_ballot_participation" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."network_ballot_votes" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."network_ballots" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."network_fund_transactions" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."network_funds" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "members can read own change requests" ON "public"."change_requests" AS PERMISSIVE FOR SELECT TO "authenticated" USING (((submitted_by = auth.uid()) OR is_admin()));
CREATE POLICY "tenant isolation change_requests" ON "public"."change_requests" AS RESTRICTIVE FOR ALL TO "authenticated" USING ((network_id = current_network_id())) WITH CHECK ((network_id = current_network_id()));
CREATE POLICY "tenant isolation contribution_suggestions" ON "public"."contribution_suggestions" AS RESTRICTIVE FOR ALL TO "authenticated" USING ((network_id = current_network_id())) WITH CHECK ((network_id = current_network_id()));
