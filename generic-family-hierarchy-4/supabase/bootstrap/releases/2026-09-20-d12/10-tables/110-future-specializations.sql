-- TRUSTWEAVE D12 CANONICAL CURRENT-STATE BASELINE.
-- Materialized after fresh-project structural/security/API/behavior/product parity on 2026-09-20.
-- DO NOT apply these files to the historical golden project as an upgrade sequence.
-- Historical supabase/migrations/001..123 remain immutable upgrade history.

CREATE TABLE IF NOT EXISTS "public"."alumni_connections" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "network_id" uuid NOT NULL,
  "person_id" uuid NOT NULL,
  "related_person_id" uuid NOT NULL,
  "relation_kind" character varying(40) NOT NULL,
  "created_by" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."alumni_invitations" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "network_id" uuid NOT NULL,
  "profile_id" uuid NOT NULL,
  "token" uuid DEFAULT gen_random_uuid() NOT NULL,
  "recipient_hint" text,
  "status" character varying(20) DEFAULT 'active'::character varying NOT NULL,
  "expires_at" timestamp with time zone DEFAULT (now() + '30 days'::interval) NOT NULL,
  "created_by" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "accepted_at" timestamp with time zone
);

CREATE TABLE IF NOT EXISTS "public"."alumni_network_settings" (
  "network_id" uuid NOT NULL,
  "institution_name" character varying(220) NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."alumni_profiles" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "network_id" uuid NOT NULL,
  "full_name" character varying(180) NOT NULL,
  "email" text,
  "graduation_year" integer,
  "program" character varying(160),
  "department" character varying(160),
  "city" character varying(120),
  "company" character varying(180),
  "job_title" character varying(180),
  "bio" text,
  "visibility" character varying(20) DEFAULT 'members'::character varying NOT NULL,
  "claimed_by" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."organization_intelligence_query_signals" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "network_id" uuid NOT NULL,
  "user_id" uuid NOT NULL,
  "question" text NOT NULL,
  "intent" text NOT NULL,
  "confidence" text NOT NULL,
  "evidence_count" integer DEFAULT 0 NOT NULL,
  "matched_entity_ids" uuid[] DEFAULT '{}'::uuid[] NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);
