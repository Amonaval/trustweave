-- TRUSTWEAVE D12 CANONICAL CURRENT-STATE BASELINE.
-- Materialized after fresh-project structural/security/API/behavior/product parity on 2026-09-20.
-- DO NOT apply these files to the historical golden project as an upgrade sequence.
-- Historical supabase/migrations/001..123 remain immutable upgrade history.

ALTER TABLE "public"."family_creation_requests" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."family_digest_state" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."family_engagement_events" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."family_intake_access" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."family_intake_conflicts" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."family_intake_decisions" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."family_intake_events" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."family_intake_match_candidates" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."family_intake_people" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."family_intake_relationships" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."family_intake_sessions" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."family_join_codes" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."family_relationships" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."member_life_events" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."memories" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."memory_people" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."memory_reactions" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."profile_submissions" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "requester reads own family requests" ON "public"."family_creation_requests" AS PERMISSIVE FOR SELECT TO "authenticated" USING (((requester_user_id = auth.uid()) OR is_platform_owner()));
CREATE POLICY "admins can manage relationships" ON "public"."family_relationships" AS PERMISSIVE FOR ALL TO "authenticated" USING (is_admin()) WITH CHECK (is_admin());
CREATE POLICY "authenticated members can read relationships" ON "public"."family_relationships" AS PERMISSIVE FOR SELECT TO "authenticated" USING (true);
CREATE POLICY "tenant isolation family_relationships" ON "public"."family_relationships" AS RESTRICTIVE FOR ALL TO "authenticated" USING ((network_id = current_network_id())) WITH CHECK ((network_id = current_network_id()));
CREATE POLICY "tenant isolation member_life_events" ON "public"."member_life_events" AS RESTRICTIVE FOR ALL TO "authenticated" USING ((network_id = current_network_id())) WITH CHECK ((network_id = current_network_id()));
CREATE POLICY "tenant isolation memories" ON "public"."memories" AS RESTRICTIVE FOR ALL TO "authenticated" USING ((network_id = current_network_id())) WITH CHECK ((network_id = current_network_id()));
CREATE POLICY "members read family memory people" ON "public"."memory_people" AS PERMISSIVE FOR SELECT TO "authenticated" USING ((network_id = current_network_id()));
CREATE POLICY "tenant isolation memory_people" ON "public"."memory_people" AS RESTRICTIVE FOR ALL TO "authenticated" USING ((network_id = current_network_id())) WITH CHECK ((network_id = current_network_id()));
CREATE POLICY "admins can manage submissions" ON "public"."profile_submissions" AS PERMISSIVE FOR ALL TO "authenticated" USING (is_admin()) WITH CHECK (is_admin());
CREATE POLICY "members can create submissions" ON "public"."profile_submissions" AS PERMISSIVE FOR INSERT TO "authenticated" WITH CHECK (true);
CREATE POLICY "members can read own submissions" ON "public"."profile_submissions" AS PERMISSIVE FOR SELECT TO "authenticated" USING (((submitted_by = auth.uid()) OR is_admin()));
CREATE POLICY "tenant isolation profile_submissions" ON "public"."profile_submissions" AS RESTRICTIVE FOR ALL TO "authenticated" USING ((network_id = current_network_id())) WITH CHECK ((network_id = current_network_id()));
