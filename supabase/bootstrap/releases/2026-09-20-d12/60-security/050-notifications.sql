-- TRUSTWEAVE D12 CANONICAL CURRENT-STATE BASELINE.
-- Materialized after fresh-project structural/security/API/behavior/product parity on 2026-09-20.
-- DO NOT apply these files to the historical golden project as an upgrade sequence.
-- Historical supabase/migrations/001..123 remain immutable upgrade history.

ALTER TABLE "public"."network_notification_roles" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."notification_preferences" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."notifications" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."push_subscriptions" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "tenant isolation notification_preferences" ON "public"."notification_preferences" AS RESTRICTIVE FOR ALL TO "authenticated" USING ((network_id = current_network_id())) WITH CHECK ((network_id = current_network_id()));
CREATE POLICY "users manage own notification preferences" ON "public"."notification_preferences" AS PERMISSIVE FOR ALL TO "authenticated" USING (((user_id = auth.uid()) AND (network_id = current_network_id()))) WITH CHECK (((user_id = auth.uid()) AND (network_id = current_network_id())));
CREATE POLICY "tenant isolation notifications" ON "public"."notifications" AS RESTRICTIVE FOR ALL TO "authenticated" USING ((network_id = current_network_id())) WITH CHECK ((network_id = current_network_id()));
