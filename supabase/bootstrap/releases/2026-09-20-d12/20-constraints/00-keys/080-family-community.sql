-- TRUSTWEAVE D12 CANONICAL CURRENT-STATE BASELINE.
-- Materialized after fresh-project structural/security/API/behavior/product parity on 2026-09-20.
-- DO NOT apply these files to the historical golden project as an upgrade sequence.
-- Historical supabase/migrations/001..123 remain immutable upgrade history.

ALTER TABLE "public"."association_household_admins" ADD CONSTRAINT "association_household_admins_pkey" PRIMARY KEY (network_id, household_entity_id, user_id);
ALTER TABLE "public"."family_association_awards" ADD CONSTRAINT "family_association_awards_pkey" PRIMARY KEY (id);
ALTER TABLE "public"."family_association_family_memberships" ADD CONSTRAINT "family_association_family_mem_network_id_membership_year_id_key" UNIQUE (network_id, membership_year_id, family_entity_id);
ALTER TABLE "public"."family_association_family_memberships" ADD CONSTRAINT "family_association_family_memberships_pkey" PRIMARY KEY (id);
ALTER TABLE "public"."family_association_finance_ledger" ADD CONSTRAINT "family_association_finance_ledger_pkey" PRIMARY KEY (id);
ALTER TABLE "public"."family_association_membership_years" ADD CONSTRAINT "family_association_membership_years_network_id_label_key" UNIQUE (network_id, label);
ALTER TABLE "public"."family_association_membership_years" ADD CONSTRAINT "family_association_membership_years_pkey" PRIMARY KEY (id);
ALTER TABLE "public"."family_association_role_catalog" ADD CONSTRAINT "family_association_role_catalog_network_id_role_key_key" UNIQUE (network_id, role_key);
ALTER TABLE "public"."family_association_role_catalog" ADD CONSTRAINT "family_association_role_catalog_pkey" PRIMARY KEY (id);
ALTER TABLE "public"."family_association_role_history" ADD CONSTRAINT "family_association_role_history_pkey" PRIMARY KEY (id);
ALTER TABLE "public"."family_association_settings" ADD CONSTRAINT "family_association_settings_pkey" PRIMARY KEY (network_id);
