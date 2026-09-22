-- TRUSTWEAVE D12 CANONICAL CURRENT-STATE BASELINE.
-- Materialized after fresh-project structural/security/API/behavior/product parity on 2026-09-20.
-- DO NOT apply these files to the historical golden project as an upgrade sequence.
-- Historical supabase/migrations/001..123 remain immutable upgrade history.

CREATE TABLE IF NOT EXISTS "public"."family_creation_requests" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "requester_user_id" uuid NOT NULL,
  "name" character varying(180) NOT NULL,
  "slug" character varying(80),
  "description" text DEFAULT ''::text NOT NULL,
  "status" character varying(20) DEFAULT 'pending'::character varying NOT NULL,
  "reviewed_by" uuid,
  "reviewed_at" timestamp with time zone,
  "network_id" uuid,
  "decision_note" text,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."family_digest_state" (
  "network_id" uuid NOT NULL,
  "user_id" uuid NOT NULL,
  "last_opened_at" timestamp with time zone,
  "last_shared_at" timestamp with time zone,
  "open_count" integer DEFAULT 0 NOT NULL,
  "share_count" integer DEFAULT 0 NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."family_engagement_events" (
  "id" bigint DEFAULT nextval('family_engagement_events_id_seq'::regclass) NOT NULL,
  "network_id" uuid NOT NULL,
  "user_id" uuid,
  "event_type" character varying(48) NOT NULL,
  "entity_type" character varying(32),
  "entity_id" uuid,
  "channel" character varying(32),
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."family_intake_access" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "session_id" uuid NOT NULL,
  "network_id" uuid NOT NULL,
  "token_hash" bytea NOT NULL,
  "representative_label" character varying(120),
  "status" character varying(20) DEFAULT 'active'::character varying NOT NULL,
  "max_submissions" integer DEFAULT 1 NOT NULL,
  "submission_count" integer DEFAULT 0 NOT NULL,
  "created_by" uuid,
  "expires_at" timestamp with time zone DEFAULT (now() + '30 days'::interval) NOT NULL,
  "last_opened_at" timestamp with time zone,
  "submitted_at" timestamp with time zone,
  "committed_at" timestamp with time zone,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."family_intake_conflicts" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "session_id" uuid NOT NULL,
  "network_id" uuid NOT NULL,
  "staged_person_id" uuid NOT NULL,
  "member_id" uuid NOT NULL,
  "field_name" character varying(50) NOT NULL,
  "existing_value" text,
  "reported_value" text,
  "status" character varying(20) DEFAULT 'open'::character varying NOT NULL,
  "resolved_by" uuid,
  "resolved_at" timestamp with time zone,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."family_intake_decisions" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "session_id" uuid NOT NULL,
  "network_id" uuid NOT NULL,
  "candidate_id" uuid,
  "staged_person_id" uuid NOT NULL,
  "decision" character varying(20) NOT NULL,
  "decision_source" character varying(30) DEFAULT 'owner'::character varying NOT NULL,
  "decided_by" uuid,
  "reason" text,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."family_intake_events" (
  "id" bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  "network_id" uuid NOT NULL,
  "session_id" uuid,
  "access_id" uuid,
  "event_name" character varying(60) NOT NULL,
  "properties" jsonb DEFAULT '{}'::jsonb NOT NULL,
  "actor_id" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."family_intake_match_candidates" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "session_id" uuid NOT NULL,
  "network_id" uuid NOT NULL,
  "staged_person_id" uuid NOT NULL,
  "candidate_member_id" uuid,
  "candidate_staged_person_id" uuid,
  "score" integer NOT NULL,
  "confidence_band" character varying(12) NOT NULL,
  "reasons" jsonb DEFAULT '{}'::jsonb NOT NULL,
  "status" character varying(20) DEFAULT 'open'::character varying NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."family_intake_people" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "session_id" uuid NOT NULL,
  "access_id" uuid NOT NULL,
  "network_id" uuid NOT NULL,
  "client_ref" character varying(80) NOT NULL,
  "full_name" character varying(150) NOT NULL,
  "normalized_name" character varying(180) NOT NULL,
  "date_of_birth" date,
  "birth_year" integer,
  "gender" character varying(10),
  "city" character varying(100),
  "role_from_anchor" character varying(60),
  "generation_offset" integer DEFAULT 0 NOT NULL,
  "status" character varying(20) DEFAULT 'staged'::character varying NOT NULL,
  "matched_member_id" uuid,
  "match_confidence" integer,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."family_intake_relationships" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "session_id" uuid NOT NULL,
  "access_id" uuid NOT NULL,
  "network_id" uuid NOT NULL,
  "from_staged_person_id" uuid NOT NULL,
  "to_staged_person_id" uuid NOT NULL,
  "relationship_type" character varying(20) NOT NULL,
  "reported_relationship" character varying(80),
  "status" character varying(20) DEFAULT 'staged'::character varying NOT NULL,
  "canonical_relationship_id" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."family_intake_sessions" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "network_id" uuid NOT NULL,
  "title" character varying(180) DEFAULT 'Build our family together'::character varying NOT NULL,
  "status" character varying(20) DEFAULT 'collecting'::character varying NOT NULL,
  "created_by" uuid,
  "expires_at" timestamp with time zone,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."family_join_codes" (
  "network_id" uuid NOT NULL,
  "code" character varying(12) NOT NULL,
  "created_by" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."family_relationships" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "person_id" uuid NOT NULL,
  "related_person_id" uuid NOT NULL,
  "relationship_type" character varying(20) NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "network_id" uuid DEFAULT current_network_id() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."member_life_events" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "member_id" uuid NOT NULL,
  "event_type" character varying(30) NOT NULL,
  "title" character varying(160) NOT NULL,
  "event_date" date,
  "location" character varying(160),
  "description" text,
  "visibility" character varying(20) DEFAULT 'member'::character varying NOT NULL,
  "created_by" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  "network_id" uuid DEFAULT current_network_id() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."memories" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "member_id" uuid,
  "title" character varying(180) NOT NULL,
  "story" text,
  "photo_url" text,
  "visibility" character varying(20) DEFAULT 'member'::character varying NOT NULL,
  "created_by" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "network_id" uuid DEFAULT current_network_id() NOT NULL,
  "event_id" uuid
);

CREATE TABLE IF NOT EXISTS "public"."memory_people" (
  "memory_id" uuid NOT NULL,
  "member_id" uuid NOT NULL,
  "network_id" uuid DEFAULT current_network_id() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."memory_reactions" (
  "network_id" uuid NOT NULL,
  "memory_id" uuid NOT NULL,
  "user_id" uuid NOT NULL,
  "reaction" character varying(16) NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."profile_submissions" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "member_id" uuid,
  "full_name" character varying(150) NOT NULL,
  "profession" character varying(100),
  "city" character varying(100),
  "country" character varying(100),
  "bio" text,
  "phone" character varying(30),
  "email" character varying(255),
  "photo_url" text,
  "status" character varying(20) DEFAULT 'pending'::character varying NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "submitted_by" uuid,
  "profile_visibility" character varying(20) DEFAULT 'member'::character varying NOT NULL,
  "contact_visibility" character varying(20) DEFAULT 'admin'::character varying NOT NULL,
  "network_id" uuid DEFAULT current_network_id() NOT NULL,
  "avatar_style" character varying(20) DEFAULT 'initials'::character varying NOT NULL,
  "facebook_url" text,
  "facebook_public" boolean DEFAULT false NOT NULL,
  "instagram_url" text,
  "instagram_public" boolean DEFAULT false NOT NULL,
  "other_social_url" text,
  "other_social_label" character varying(40),
  "other_social_public" boolean DEFAULT false NOT NULL
);
