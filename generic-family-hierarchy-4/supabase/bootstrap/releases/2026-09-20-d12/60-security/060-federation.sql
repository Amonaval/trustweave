-- TRUSTWEAVE D12 CANONICAL CURRENT-STATE BASELINE.
-- Materialized after fresh-project structural/security/API/behavior/product parity on 2026-09-20.
-- DO NOT apply these files to the historical golden project as an upgrade sequence.
-- Historical supabase/migrations/001..123 remain immutable upgrade history.

ALTER TABLE "public"."cross_network_discovery_candidates" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."federated_introduction_outcomes" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."federated_introductions" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."federated_request_routes" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."federated_requests" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."federated_scope_profiles" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."federated_trust_receipts" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."federation_umbrella_admins" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."federation_umbrellas" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."network_effect_events" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."network_passports" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."network_trust_bridges" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."network_umbrella_affiliations" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."trusted_introduction_requests" ENABLE ROW LEVEL SECURITY;
