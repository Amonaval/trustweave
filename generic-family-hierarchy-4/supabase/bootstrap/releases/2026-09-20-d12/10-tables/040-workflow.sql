-- TRUSTWEAVE D12 CANONICAL CURRENT-STATE BASELINE.
-- Materialized after fresh-project structural/security/API/behavior/product parity on 2026-09-20.
-- DO NOT apply these files to the historical golden project as an upgrade sequence.
-- Historical supabase/migrations/001..123 remain immutable upgrade history.

CREATE TABLE IF NOT EXISTS "public"."api_command_idempotency" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "user_id" uuid NOT NULL,
  "command_name" text NOT NULL,
  "idempotency_key" text NOT NULL,
  "request_hash" text NOT NULL,
  "status" text DEFAULT 'pending'::text NOT NULL,
  "response_body" jsonb,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."change_requests" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "action" character varying(40) NOT NULL,
  "target_member_id" uuid,
  "submitted_by" uuid,
  "status" character varying(20) DEFAULT 'pending'::character varying NOT NULL,
  "payload" jsonb DEFAULT '{}'::jsonb NOT NULL,
  "review_note" text,
  "reviewed_by" uuid,
  "reviewed_at" timestamp with time zone,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "network_id" uuid DEFAULT current_network_id() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."contribution_suggestions" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "signature" text NOT NULL,
  "member_id" uuid,
  "kind" character varying(40) NOT NULL,
  "title" character varying(180) NOT NULL,
  "detail" text,
  "action_payload" jsonb DEFAULT '{}'::jsonb NOT NULL,
  "priority" integer DEFAULT 50 NOT NULL,
  "status" character varying(20) DEFAULT 'open'::character varying NOT NULL,
  "acted_by" uuid,
  "acted_at" timestamp with time zone,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  "network_id" uuid DEFAULT current_network_id() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."guide_feedback" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "network_id" uuid,
  "user_id" uuid,
  "member_id" uuid,
  "guide_key" text,
  "screen" text,
  "feedback_type" text NOT NULL,
  "message" text,
  "role" text,
  "experience_mode" text,
  "app_version" text,
  "status" text DEFAULT 'new'::text NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."network_ballot_eligibility" (
  "network_id" uuid NOT NULL,
  "ballot_id" uuid NOT NULL,
  "user_id" uuid NOT NULL,
  "source" character varying(40) NOT NULL,
  "snapshotted_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."network_ballot_nominations" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "network_id" uuid NOT NULL,
  "ballot_id" uuid NOT NULL,
  "nominee_entity_id" uuid NOT NULL,
  "nominee_label" character varying(180) NOT NULL,
  "statement" text,
  "nominated_by" uuid NOT NULL,
  "status" character varying(20) DEFAULT 'pending'::character varying NOT NULL,
  "reviewed_by" uuid,
  "reviewed_at" timestamp with time zone,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."network_ballot_options" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "network_id" uuid NOT NULL,
  "ballot_id" uuid NOT NULL,
  "label" character varying(180) NOT NULL,
  "description" text,
  "candidate_entity_id" uuid,
  "sort_order" integer DEFAULT 10 NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."network_ballot_participation" (
  "network_id" uuid NOT NULL,
  "ballot_id" uuid NOT NULL,
  "user_id" uuid NOT NULL,
  "receipt_id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "choice_count" integer NOT NULL,
  "cast_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."network_ballot_votes" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "network_id" uuid NOT NULL,
  "ballot_id" uuid NOT NULL,
  "option_id" uuid NOT NULL,
  "anonymous_token" uuid NOT NULL,
  "voter_user_id" uuid,
  "cast_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."network_ballots" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "network_id" uuid NOT NULL,
  "ballot_type" character varying(20) DEFAULT 'poll'::character varying NOT NULL,
  "title" character varying(180) NOT NULL,
  "description" text,
  "status" character varying(20) DEFAULT 'draft'::character varying NOT NULL,
  "eligibility_mode" character varying(30) DEFAULT 'members'::character varying NOT NULL,
  "max_choices" integer DEFAULT 1 NOT NULL,
  "secret_ballot" boolean DEFAULT true NOT NULL,
  "allow_nominations" boolean DEFAULT false NOT NULL,
  "opens_at" timestamp with time zone,
  "closes_at" timestamp with time zone,
  "results_published_at" timestamp with time zone,
  "created_by" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."network_fund_transactions" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "network_id" uuid NOT NULL,
  "fund_id" uuid NOT NULL,
  "transaction_kind" character varying(30) NOT NULL,
  "amount" numeric(14,2) NOT NULL,
  "source_entity_id" uuid,
  "activity_id" uuid,
  "membership_year_id" uuid,
  "receipt_no" character varying(80),
  "payment_method" character varying(40),
  "reference" character varying(160),
  "note" text,
  "visibility" character varying(20) DEFAULT 'members'::character varying NOT NULL,
  "occurred_on" date DEFAULT CURRENT_DATE NOT NULL,
  "created_by" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."network_funds" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "network_id" uuid NOT NULL,
  "name" character varying(160) NOT NULL,
  "fund_kind" character varying(30) DEFAULT 'general'::character varying NOT NULL,
  "purpose" text,
  "membership_year_id" uuid,
  "activity_id" uuid,
  "target_amount" numeric(14,2),
  "opening_balance" numeric(14,2) DEFAULT 0 NOT NULL,
  "visibility" character varying(20) DEFAULT 'members'::character varying NOT NULL,
  "status" character varying(20) DEFAULT 'active'::character varying NOT NULL,
  "created_by" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
