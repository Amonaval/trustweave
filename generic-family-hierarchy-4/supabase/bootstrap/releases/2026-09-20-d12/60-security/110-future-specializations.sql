-- TRUSTWEAVE D12 CANONICAL CURRENT-STATE BASELINE.
-- Materialized after fresh-project structural/security/API/behavior/product parity on 2026-09-20.
-- DO NOT apply these files to the historical golden project as an upgrade sequence.
-- Historical supabase/migrations/001..123 remain immutable upgrade history.

ALTER TABLE "public"."alumni_connections" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."alumni_invitations" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."alumni_network_settings" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."alumni_profiles" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."organization_intelligence_query_signals" ENABLE ROW LEVEL SECURITY;
