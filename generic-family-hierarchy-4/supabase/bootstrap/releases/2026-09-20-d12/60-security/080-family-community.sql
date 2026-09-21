-- TRUSTWEAVE D12 CANONICAL CURRENT-STATE BASELINE.
-- Materialized after fresh-project structural/security/API/behavior/product parity on 2026-09-20.
-- DO NOT apply these files to the historical golden project as an upgrade sequence.
-- Historical supabase/migrations/001..123 remain immutable upgrade history.

ALTER TABLE "public"."association_household_admins" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."family_association_awards" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."family_association_family_memberships" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."family_association_finance_ledger" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."family_association_membership_years" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."family_association_role_catalog" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."family_association_role_history" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."family_association_settings" ENABLE ROW LEVEL SECURITY;
