-- TRUSTWEAVE D12 CANONICAL CURRENT-STATE BASELINE.
-- Materialized after fresh-project structural/security/API/behavior/product parity on 2026-09-20.
-- DO NOT apply these files to the historical golden project as an upgrade sequence.
-- Historical supabase/migrations/001..123 remain immutable upgrade history.

CREATE TABLE IF NOT EXISTS "public"."cross_network_discovery_candidates" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "requester_user_id" uuid NOT NULL,
  "source_network_id" uuid NOT NULL,
  "bridge_id" uuid NOT NULL,
  "target_network_id" uuid NOT NULL,
  "target_entity_id" uuid,
  "target_user_id" uuid NOT NULL,
  "query_text" character varying(120) NOT NULL,
  "match_hint" character varying(180) DEFAULT 'Relevant member found through a trusted network bridge.'::character varying NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "expires_at" timestamp with time zone DEFAULT (now() + '00:30:00'::interval) NOT NULL,
  "path_depth" smallint DEFAULT 1 NOT NULL,
  "path_bridge_ids" uuid[] DEFAULT '{}'::uuid[] NOT NULL,
  "path_network_ids" uuid[] DEFAULT '{}'::uuid[] NOT NULL,
  "path_summary" character varying(260) DEFAULT 'Direct trusted bridge'::character varying NOT NULL,
  "target_subject_kind" character varying(20) DEFAULT 'entity'::character varying NOT NULL,
  "target_ref_id" uuid
);

CREATE TABLE IF NOT EXISTS "public"."federated_introduction_outcomes" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "introduction_id" uuid NOT NULL,
  "receipt_id" uuid NOT NULL,
  "actor_user_id" uuid NOT NULL,
  "actor_role" character varying(20) NOT NULL,
  "outcome_code" character varying(30) NOT NULL,
  "note" character varying(800),
  "recorded_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."federated_introductions" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "request_id" uuid NOT NULL,
  "route_id" uuid NOT NULL,
  "target_scope_profile_id" uuid NOT NULL,
  "requester_user_id" uuid NOT NULL,
  "target_user_id" uuid NOT NULL,
  "requester_alias" character varying(180) NOT NULL,
  "message" character varying(800) NOT NULL,
  "requester_contact_note" character varying(320) NOT NULL,
  "target_response_note" character varying(800),
  "target_contact_note" character varying(320),
  "trust_path_snapshot" text NOT NULL,
  "status" character varying(20) DEFAULT 'pending'::character varying NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "responded_at" timestamp with time zone,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."federated_request_routes" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "request_id" uuid NOT NULL,
  "target_scope_profile_id" uuid NOT NULL,
  "score" integer NOT NULL,
  "reasons" text[] DEFAULT '{}'::text[] NOT NULL,
  "trust_path_label" text NOT NULL,
  "status" character varying(20) DEFAULT 'suggested'::character varying NOT NULL,
  "generated_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."federated_requests" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "requester_user_id" uuid NOT NULL,
  "source_network_id" uuid NOT NULL,
  "umbrella_id" uuid NOT NULL,
  "scope_key" character varying(48) NOT NULL,
  "title" character varying(180) NOT NULL,
  "description" character varying(1200),
  "location_label" character varying(160),
  "tags" text[] DEFAULT '{}'::text[] NOT NULL,
  "status" character varying(20) DEFAULT 'open'::character varying NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."federated_scope_profiles" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "owner_user_id" uuid NOT NULL,
  "network_id" uuid NOT NULL,
  "umbrella_id" uuid NOT NULL,
  "scope_key" character varying(48) NOT NULL,
  "display_name" character varying(180) NOT NULL,
  "headline" character varying(180),
  "summary" character varying(800),
  "location_label" character varying(160),
  "tags" text[] DEFAULT '{}'::text[] NOT NULL,
  "contact_mode" character varying(24) DEFAULT 'introduction_only'::character varying NOT NULL,
  "active" boolean DEFAULT true NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."federated_trust_receipts" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "introduction_id" uuid NOT NULL,
  "request_id" uuid NOT NULL,
  "route_id" uuid NOT NULL,
  "scope_key" character varying(80) NOT NULL,
  "request_title" character varying(220) NOT NULL,
  "source_network_name" character varying(180) NOT NULL,
  "target_network_name" character varying(180) NOT NULL,
  "umbrella_name" character varying(180) NOT NULL,
  "trust_path_snapshot" text NOT NULL,
  "routed_at" timestamp with time zone,
  "introduction_requested_at" timestamp with time zone NOT NULL,
  "accepted_at" timestamp with time zone NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."federation_umbrella_admins" (
  "umbrella_id" uuid NOT NULL,
  "user_id" uuid NOT NULL,
  "role" character varying(20) DEFAULT 'admin'::character varying NOT NULL,
  "status" character varying(20) DEFAULT 'active'::character varying NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."federation_umbrellas" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "name" character varying(160) NOT NULL,
  "slug" character varying(180) NOT NULL,
  "umbrella_type" character varying(32) DEFAULT 'community'::character varying NOT NULL,
  "summary" character varying(600) DEFAULT ''::character varying NOT NULL,
  "location_label" character varying(120) DEFAULT ''::character varying NOT NULL,
  "status" character varying(20) DEFAULT 'active'::character varying NOT NULL,
  "created_by" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."network_effect_events" (
  "id" bigint DEFAULT nextval('network_effect_events_id_seq'::regclass) NOT NULL,
  "actor_user_id" uuid NOT NULL,
  "source_network_id" uuid,
  "bridge_id" uuid,
  "event_type" character varying(48) NOT NULL,
  "event_count" integer DEFAULT 1 NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."network_passports" (
  "network_id" uuid NOT NULL,
  "public_slug" character varying(80) NOT NULL,
  "tagline" character varying(120) DEFAULT ''::character varying NOT NULL,
  "summary" character varying(800) DEFAULT ''::character varying NOT NULL,
  "location_label" character varying(120) DEFAULT ''::character varying NOT NULL,
  "established_label" character varying(80) DEFAULT ''::character varying NOT NULL,
  "external_url" character varying(300) DEFAULT ''::character varying NOT NULL,
  "capabilities" text[] DEFAULT '{}'::text[] NOT NULL,
  "participation_scopes" text[] DEFAULT '{}'::text[] NOT NULL,
  "visibility" character varying(20) DEFAULT 'private'::character varying NOT NULL,
  "directory_discoverable" boolean DEFAULT false NOT NULL,
  "verification_state" character varying(30) DEFAULT 'self_declared'::character varying NOT NULL,
  "created_by" uuid,
  "updated_by" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."network_trust_bridges" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "requester_network_id" uuid NOT NULL,
  "recipient_network_id" uuid NOT NULL,
  "relationship_type" character varying(40) NOT NULL,
  "status" character varying(20) DEFAULT 'pending'::character varying NOT NULL,
  "context_label" character varying(200),
  "capabilities" jsonb DEFAULT '{"discovery": false, "introductions": false}'::jsonb NOT NULL,
  "requested_by" uuid NOT NULL,
  "reviewed_by" uuid,
  "reviewed_at" timestamp with time zone,
  "revoked_by" uuid,
  "revoked_at" timestamp with time zone,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."network_umbrella_affiliations" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "network_id" uuid NOT NULL,
  "umbrella_id" uuid NOT NULL,
  "relationship_type" character varying(32) DEFAULT 'member'::character varying NOT NULL,
  "status" character varying(20) DEFAULT 'requested'::character varying NOT NULL,
  "context_label" character varying(160) DEFAULT ''::character varying NOT NULL,
  "requested_by" uuid,
  "reviewed_by" uuid,
  "reviewed_at" timestamp with time zone,
  "suspended_by" uuid,
  "suspended_at" timestamp with time zone,
  "revoked_by" uuid,
  "revoked_at" timestamp with time zone,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."trusted_introduction_requests" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "candidate_id" uuid NOT NULL,
  "bridge_id" uuid NOT NULL,
  "source_network_id" uuid NOT NULL,
  "target_network_id" uuid NOT NULL,
  "requester_user_id" uuid NOT NULL,
  "target_user_id" uuid NOT NULL,
  "target_entity_id" uuid,
  "message" character varying(500) NOT NULL,
  "status" character varying(20) DEFAULT 'pending'::character varying NOT NULL,
  "reviewed_at" timestamp with time zone,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  "path_depth" smallint DEFAULT 1 NOT NULL,
  "path_bridge_ids" uuid[] DEFAULT '{}'::uuid[] NOT NULL,
  "path_summary" character varying(260) DEFAULT 'Direct trusted bridge'::character varying NOT NULL,
  "target_subject_kind" character varying(20) DEFAULT 'entity'::character varying NOT NULL,
  "target_ref_id" uuid
);
