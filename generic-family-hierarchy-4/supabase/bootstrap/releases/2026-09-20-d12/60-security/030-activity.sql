-- TRUSTWEAVE D12 CANONICAL CURRENT-STATE BASELINE.
-- Materialized after fresh-project structural/security/API/behavior/product parity on 2026-09-20.
-- DO NOT apply these files to the historical golden project as an upgrade sequence.
-- Historical supabase/migrations/001..123 remain immutable upgrade history.

ALTER TABLE "public"."community_event_responses" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."community_events" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."community_family_links" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."community_group_members" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."community_groups" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."community_introduction_requests" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."community_posts" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."community_profile_cards" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."community_spaces" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."community_trust_edges" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."network_activities" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."network_activity_comments" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."network_activity_reactions" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."network_activity_rsvps" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."network_media_assets" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."participation_events" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "members create own event response" ON "public"."community_event_responses" AS PERMISSIVE FOR INSERT TO "authenticated" WITH CHECK ((user_id = auth.uid()));
CREATE POLICY "members delete own event response" ON "public"."community_event_responses" AS PERMISSIVE FOR DELETE TO "authenticated" USING ((user_id = auth.uid()));
CREATE POLICY "members read own event response" ON "public"."community_event_responses" AS PERMISSIVE FOR SELECT TO "authenticated" USING (((user_id = auth.uid()) OR is_admin()));
CREATE POLICY "members update own event response" ON "public"."community_event_responses" AS PERMISSIVE FOR UPDATE TO "authenticated" USING ((user_id = auth.uid())) WITH CHECK ((user_id = auth.uid()));
CREATE POLICY "tenant isolation community_event_responses" ON "public"."community_event_responses" AS RESTRICTIVE FOR ALL TO "authenticated" USING ((network_id = current_network_id())) WITH CHECK ((network_id = current_network_id()));
CREATE POLICY "admins manage community events" ON "public"."community_events" AS PERMISSIVE FOR ALL TO "authenticated" USING (is_admin()) WITH CHECK (is_admin());
CREATE POLICY "members read community events" ON "public"."community_events" AS PERMISSIVE FOR SELECT TO "authenticated" USING (true);
CREATE POLICY "tenant isolation community_events" ON "public"."community_events" AS RESTRICTIVE FOR ALL TO "authenticated" USING ((network_id = current_network_id())) WITH CHECK ((network_id = current_network_id()));
CREATE POLICY "admins manage community group members" ON "public"."community_group_members" AS PERMISSIVE FOR ALL TO "authenticated" USING (is_admin()) WITH CHECK (is_admin());
CREATE POLICY "members read community group members" ON "public"."community_group_members" AS PERMISSIVE FOR SELECT TO "authenticated" USING (true);
CREATE POLICY "tenant isolation community_group_members" ON "public"."community_group_members" AS RESTRICTIVE FOR ALL TO "authenticated" USING ((network_id = current_network_id())) WITH CHECK ((network_id = current_network_id()));
CREATE POLICY "admins manage community groups" ON "public"."community_groups" AS PERMISSIVE FOR ALL TO "authenticated" USING (is_admin()) WITH CHECK (is_admin());
CREATE POLICY "members read community groups" ON "public"."community_groups" AS PERMISSIVE FOR SELECT TO "authenticated" USING (true);
CREATE POLICY "tenant isolation community_groups" ON "public"."community_groups" AS RESTRICTIVE FOR ALL TO "authenticated" USING ((network_id = current_network_id())) WITH CHECK ((network_id = current_network_id()));
CREATE POLICY "tenant isolation participation_events" ON "public"."participation_events" AS RESTRICTIVE FOR ALL TO "authenticated" USING ((network_id = current_network_id())) WITH CHECK ((network_id = current_network_id()));
