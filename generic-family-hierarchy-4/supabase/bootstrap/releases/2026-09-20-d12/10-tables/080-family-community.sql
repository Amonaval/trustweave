-- TRUSTWEAVE D12 CANONICAL CURRENT-STATE BASELINE.
-- Materialized after fresh-project structural/security/API/behavior/product parity on 2026-09-20.
-- DO NOT apply these files to the historical golden project as an upgrade sequence.
-- Historical supabase/migrations/001..123 remain immutable upgrade history.

CREATE TABLE IF NOT EXISTS "public"."association_household_admins" (
  "network_id" uuid NOT NULL,
  "household_entity_id" uuid NOT NULL,
  "user_id" uuid NOT NULL,
  "granted_by" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."family_association_awards" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "network_id" uuid NOT NULL,
  "person_entity_id" uuid NOT NULL,
  "award_key" character varying(80) NOT NULL,
  "award_label" character varying(160) NOT NULL,
  "membership_year_id" uuid,
  "awarded_on" date,
  "event_activity_id" uuid,
  "description" text,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."family_association_family_memberships" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "network_id" uuid NOT NULL,
  "membership_year_id" uuid NOT NULL,
  "family_entity_id" uuid NOT NULL,
  "representative_entity_id" uuid,
  "status" character varying(24) DEFAULT 'active'::character varying NOT NULL,
  "payment_status" character varying(20) DEFAULT 'unpaid'::character varying NOT NULL,
  "amount_due" numeric(12,2) DEFAULT 0 NOT NULL,
  "amount_paid" numeric(12,2) DEFAULT 0 NOT NULL,
  "payment_reference" character varying(120),
  "joined_on" date,
  "renewed_on" date,
  "inactive_on" date,
  "transfer_to_network_id" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."family_association_finance_ledger" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "network_id" uuid NOT NULL,
  "membership_year_id" uuid NOT NULL,
  "entry_type" character varying(28) NOT NULL,
  "amount" numeric(14,2) NOT NULL,
  "activity_id" uuid,
  "description" text,
  "visibility" character varying(16) DEFAULT 'admins'::character varying NOT NULL,
  "created_by" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."family_association_membership_years" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "network_id" uuid NOT NULL,
  "label" character varying(20) NOT NULL,
  "start_date" date NOT NULL,
  "end_date" date NOT NULL,
  "family_fee" numeric(12,2) DEFAULT 0 NOT NULL,
  "grace_period_days" smallint DEFAULT 30 NOT NULL,
  "status" character varying(16) DEFAULT 'planned'::character varying NOT NULL,
  "created_by" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."family_association_role_catalog" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "network_id" uuid NOT NULL,
  "role_key" character varying(80) NOT NULL,
  "label" character varying(120) NOT NULL,
  "role_type" character varying(24) NOT NULL,
  "portfolio" character varying(120),
  "active" boolean DEFAULT true NOT NULL,
  "sort_order" integer DEFAULT 100 NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."family_association_role_history" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "network_id" uuid NOT NULL,
  "membership_year_id" uuid,
  "person_entity_id" uuid NOT NULL,
  "role_catalog_id" uuid NOT NULL,
  "starts_on" date,
  "ends_on" date,
  "notes" text,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."family_association_settings" (
  "network_id" uuid NOT NULL,
  "membership_cycle_start_month" smallint DEFAULT 4 NOT NULL,
  "dependent_age_limit" smallint DEFAULT 22 NOT NULL,
  "grace_period_days" smallint DEFAULT 30 NOT NULL,
  "max_auto_children" smallint DEFAULT 2 NOT NULL,
  "onboarding_policy" character varying(24) DEFAULT 'join_review_later'::character varying NOT NULL,
  "voting_eligibility" character varying(32) DEFAULT 'representative_spouse'::character varying NOT NULL,
  "default_profile_visibility" character varying(16) DEFAULT 'members'::character varying NOT NULL,
  "default_contact_visibility" character varying(16) DEFAULT 'members'::character varying NOT NULL,
  "finance_visibility" character varying(16) DEFAULT 'admins'::character varying NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
