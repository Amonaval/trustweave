-- TRUSTWEAVE D12 CANONICAL CURRENT-STATE BASELINE.
-- Materialized after fresh-project structural/security/API/behavior/product parity on 2026-09-20.
-- DO NOT apply these files to the historical golden project as an upgrade sequence.
-- Historical supabase/migrations/001..123 remain immutable upgrade history.

CREATE TABLE IF NOT EXISTS "public"."audit_log" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "actor_id" uuid,
  "action" character varying(80) NOT NULL,
  "details" jsonb DEFAULT '{}'::jsonb,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "network_id" uuid DEFAULT current_network_id() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."launch_demo_seed_authorizations" (
  "network_id" uuid NOT NULL,
  "dataset_version" character varying(120) NOT NULL,
  "synthetic" boolean DEFAULT true NOT NULL,
  "allow_real_network" boolean DEFAULT false NOT NULL,
  "confirmed_network_name" text NOT NULL,
  "authorized_by" uuid NOT NULL,
  "authorized_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."launch_demo_seed_issues" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "run_id" uuid NOT NULL,
  "network_id" uuid NOT NULL,
  "dataset_version" character varying(120) NOT NULL,
  "severity" character varying(12) NOT NULL,
  "section_key" character varying(140) NOT NULL,
  "row_ref" character varying(180) NOT NULL,
  "operation" character varying(120) NOT NULL,
  "error_code" character varying(60),
  "message" text NOT NULL,
  "details" text,
  "hint" text,
  "retryable" boolean DEFAULT false NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."launch_demo_seed_lineage" (
  "network_id" uuid NOT NULL,
  "dataset_version" character varying(120) NOT NULL,
  "section_key" character varying(120) NOT NULL,
  "row_ref" character varying(160) NOT NULL,
  "payload_hash" character varying(80) NOT NULL,
  "remote_id" text,
  "status" character varying(20) DEFAULT 'committed'::character varying NOT NULL,
  "last_message" text,
  "created_by" uuid NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."launch_demo_seed_runs" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "network_id" uuid NOT NULL,
  "dataset_version" character varying(120) NOT NULL,
  "vertical_kind" character varying(50) NOT NULL,
  "status" character varying(30) DEFAULT 'running'::character varying NOT NULL,
  "total_rows" integer DEFAULT 0 NOT NULL,
  "created_count" integer DEFAULT 0 NOT NULL,
  "updated_count" integer DEFAULT 0 NOT NULL,
  "skipped_count" integer DEFAULT 0 NOT NULL,
  "error_count" integer DEFAULT 0 NOT NULL,
  "warning_count" integer DEFAULT 0 NOT NULL,
  "created_by" uuid NOT NULL,
  "started_at" timestamp with time zone DEFAULT now() NOT NULL,
  "completed_at" timestamp with time zone
);

CREATE TABLE IF NOT EXISTS "public"."network_archive_membership_state" (
  "network_id" uuid NOT NULL,
  "user_id" uuid NOT NULL,
  "previous_status" character varying(20) NOT NULL,
  "archived_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."network_assertion_decisions" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "network_id" uuid NOT NULL,
  "assertion_id" uuid NOT NULL,
  "action" text NOT NULL,
  "actor_user_id" uuid NOT NULL,
  "reason" text,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."network_bridge_codes" (
  "network_id" uuid NOT NULL,
  "code" text NOT NULL,
  "created_by" uuid NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "rotated_at" timestamp with time zone
);

CREATE TABLE IF NOT EXISTS "public"."network_candidate_assertions" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "network_id" uuid NOT NULL,
  "subject" jsonb NOT NULL,
  "predicate" text NOT NULL,
  "object" jsonb NOT NULL,
  "evidence_ids" uuid[] DEFAULT '{}'::uuid[] NOT NULL,
  "confidence" numeric(5,4) NOT NULL,
  "extraction_method" text NOT NULL,
  "extractor_version" text,
  "status" text DEFAULT 'candidate'::text NOT NULL,
  "supersedes_assertion_id" uuid,
  "reviewed_by" uuid,
  "reviewed_at" timestamp with time zone,
  "metadata" jsonb DEFAULT '{}'::jsonb NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."network_contribution_audit" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "network_id" uuid NOT NULL,
  "contribution_id" uuid NOT NULL,
  "from_status" character varying(20),
  "to_status" character varying(20) NOT NULL,
  "actor_user_id" uuid,
  "at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."network_contributions" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "network_id" uuid NOT NULL,
  "entity_id" uuid,
  "message" text NOT NULL,
  "payload" jsonb DEFAULT '{}'::jsonb NOT NULL,
  "status" character varying(20) DEFAULT 'open'::character varying NOT NULL,
  "created_by" uuid,
  "reviewed_by" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "reviewed_at" timestamp with time zone
);

CREATE TABLE IF NOT EXISTS "public"."network_dimension_values" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "network_id" uuid NOT NULL,
  "dimension_id" uuid NOT NULL,
  "value_key" character varying(220) NOT NULL,
  "label" character varying(220) NOT NULL,
  "metadata" jsonb DEFAULT '{}'::jsonb NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."network_dimensions" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "network_id" uuid NOT NULL,
  "dimension_key" character varying(80) NOT NULL,
  "label" character varying(160) NOT NULL,
  "entity_kind" character varying(50),
  "sort_order" integer DEFAULT 0 NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."network_entities" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "network_id" uuid NOT NULL,
  "kind" character varying(50) NOT NULL,
  "external_ref" uuid,
  "owner_user_id" uuid,
  "label" character varying(220) NOT NULL,
  "metadata" jsonb DEFAULT '{}'::jsonb NOT NULL,
  "visibility" character varying(20) DEFAULT 'members'::character varying NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."network_entity_affiliations" (
  "network_id" uuid NOT NULL,
  "entity_id" uuid NOT NULL,
  "dimension_id" uuid NOT NULL,
  "value_id" uuid NOT NULL,
  "source" character varying(30) DEFAULT 'vertical_adapter'::character varying NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."network_entity_relationships" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "network_id" uuid NOT NULL,
  "from_entity_id" uuid NOT NULL,
  "to_entity_id" uuid NOT NULL,
  "relationship_type" character varying(80) NOT NULL,
  "metadata" jsonb DEFAULT '{}'::jsonb NOT NULL,
  "created_by" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."network_evidence_records" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "network_id" uuid NOT NULL,
  "source_id" uuid NOT NULL,
  "document_external_id" text,
  "chunk_id" text NOT NULL,
  "title" text,
  "uri" text,
  "section" text,
  "breadcrumb" jsonb DEFAULT '[]'::jsonb NOT NULL,
  "content_hash" text NOT NULL,
  "excerpt" text,
  "source_updated_at" timestamp with time zone,
  "captured_at" timestamp with time zone DEFAULT now() NOT NULL,
  "visibility" text DEFAULT 'network'::text NOT NULL,
  "authorization_refs" text[] DEFAULT '{}'::text[] NOT NULL,
  "extraction_version" text,
  "metadata" jsonb DEFAULT '{}'::jsonb NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."network_feature_settings" (
  "network_id" uuid NOT NULL,
  "feature_key" character varying(80) NOT NULL,
  "enabled" boolean DEFAULT true NOT NULL,
  "updated_by" uuid,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."network_group_memberships" (
  "group_id" uuid NOT NULL,
  "network_id" uuid NOT NULL,
  "user_id" uuid NOT NULL,
  "role" character varying(20) DEFAULT 'member'::character varying NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."network_groups" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "network_id" uuid NOT NULL,
  "name" character varying(180) NOT NULL,
  "group_type" character varying(50) DEFAULT 'group'::character varying NOT NULL,
  "description" text,
  "dimension_value_id" uuid,
  "created_by" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."network_join_codes" (
  "network_id" uuid NOT NULL,
  "code" character varying(16) NOT NULL,
  "created_by" uuid,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."network_knowledge_sources" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "network_id" uuid NOT NULL,
  "source_type" text NOT NULL,
  "external_id" text,
  "title" text NOT NULL,
  "uri" text,
  "connector_id" text,
  "visibility" text DEFAULT 'network'::text NOT NULL,
  "authorization_refs" text[] DEFAULT '{}'::text[] NOT NULL,
  "content_hash" text,
  "source_updated_at" timestamp with time zone,
  "last_observed_at" timestamp with time zone DEFAULT now() NOT NULL,
  "metadata" jsonb DEFAULT '{}'::jsonb NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."network_projections" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "network_id" uuid NOT NULL,
  "projection_key" character varying(100) NOT NULL,
  "label" character varying(180) NOT NULL,
  "levels" text[] NOT NULL,
  "is_default" boolean DEFAULT false NOT NULL,
  "sort_order" integer DEFAULT 0 NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."network_purge_receipts" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "purged_network_id" uuid NOT NULL,
  "purged_by" uuid,
  "purged_at" timestamp with time zone DEFAULT now() NOT NULL,
  "relational_residue" bigint DEFAULT 0 NOT NULL,
  "storage_residue" bigint DEFAULT 0 NOT NULL,
  "verifier_version" character varying(20) DEFAULT 'xp0-v1'::character varying NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."network_quick_start_state" (
  "network_id" uuid NOT NULL,
  "user_id" uuid NOT NULL,
  "dismissed" boolean DEFAULT false NOT NULL,
  "completed_step_ids" text[] DEFAULT '{}'::text[] NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."network_settings" (
  "id" text NOT NULL,
  "name" character varying(180) NOT NULL,
  "description" text DEFAULT ''::text,
  "initialized_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  "entity_label" text DEFAULT 'Member'::text NOT NULL,
  "entity_label_plural" text DEFAULT 'Members'::text NOT NULL,
  "level_label" text DEFAULT 'Generation'::text NOT NULL,
  "level_label_plural" text DEFAULT 'Generations'::text NOT NULL,
  "parent_label" text DEFAULT 'Parent'::text NOT NULL,
  "child_label" text DEFAULT 'Child'::text NOT NULL,
  "peer_label" text DEFAULT 'Spouse'::text NOT NULL,
  "network_template" text DEFAULT 'family'::text NOT NULL,
  "self_edit_mode" character varying(30) DEFAULT 'review'::character varying NOT NULL,
  "family_milestones_enabled" boolean DEFAULT true NOT NULL,
  "photo_upload_enabled" boolean DEFAULT false NOT NULL,
  "network_id" uuid DEFAULT current_network_id() NOT NULL,
  "vertical_kind" character varying(20) DEFAULT 'family'::character varying NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."networks" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "name" character varying(180) NOT NULL,
  "slug" character varying(80) NOT NULL,
  "status" character varying(20) DEFAULT 'active'::character varying NOT NULL,
  "storage_limit_bytes" bigint DEFAULT 104857600 NOT NULL,
  "photo_upload_enabled" boolean DEFAULT false NOT NULL,
  "photo_max_bytes" integer DEFAULT 102400 NOT NULL,
  "created_by" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  "media_usage_bytes" bigint DEFAULT 0 NOT NULL,
  "vertical_kind" character varying(20) DEFAULT 'family'::character varying NOT NULL,
  "approval_status" character varying(20) DEFAULT 'approved'::character varying NOT NULL,
  "approval_requested_at" timestamp with time zone,
  "approval_reviewed_at" timestamp with time zone,
  "approval_reviewed_by" uuid,
  "approval_note" text
);

CREATE TABLE IF NOT EXISTS "public"."pilot_feedback" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "user_id" uuid NOT NULL,
  "network_id" uuid NOT NULL,
  "moment_type" character varying(32) NOT NULL,
  "outcome" character varying(16) NOT NULL,
  "friction_code" character varying(24) DEFAULT 'none'::character varying NOT NULL,
  "note" character varying(600),
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."pilot_product_decisions" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "network_id" uuid,
  "decided_by" uuid NOT NULL,
  "moment_type" character varying(32) NOT NULL,
  "disposition" character varying(12) NOT NULL,
  "evidence_days" integer NOT NULL,
  "evidence_snapshot" jsonb DEFAULT '{}'::jsonb NOT NULL,
  "rationale" character varying(800) NOT NULL,
  "next_action" character varying(300),
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."platform_feature_flags" (
  "feature_key" character varying(80) NOT NULL,
  "bundle_key" character varying(40) NOT NULL,
  "rollout_state" character varying(20) DEFAULT 'hidden'::character varying NOT NULL,
  "pilot_network_ids" uuid[] DEFAULT '{}'::uuid[] NOT NULL,
  "updated_by" uuid,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  "announcement_version" integer DEFAULT 0 NOT NULL,
  "vertical_kind" character varying(20) DEFAULT 'family'::character varying NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."platform_feature_rollout_audit" (
  "id" bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  "feature_key" character varying(80) NOT NULL,
  "bundle_key" character varying(40) NOT NULL,
  "previous_state" character varying(20) NOT NULL,
  "new_state" character varying(20) NOT NULL,
  "pilot_network_ids" uuid[] DEFAULT '{}'::uuid[] NOT NULL,
  "announced" boolean DEFAULT false NOT NULL,
  "changed_by" uuid,
  "changed_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."platform_onboarding_settings" (
  "id" text DEFAULT 'default'::text NOT NULL,
  "family_creation_approval_required" boolean DEFAULT false NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_by" uuid,
  "network_creation_approval_required" boolean DEFAULT false NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."platform_owner_audit" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "actor_user_id" uuid,
  "target_user_id" uuid,
  "action" character varying(20) NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."platform_owners" (
  "user_id" uuid NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."platform_playground_features" (
  "feature_key" character varying(80) NOT NULL,
  "enabled" boolean DEFAULT true NOT NULL,
  "updated_by" uuid,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."platform_showcase_verticals" (
  "vertical_kind" character varying NOT NULL,
  "create_enabled" boolean DEFAULT true NOT NULL,
  "playground_enabled" boolean DEFAULT true NOT NULL,
  "featured" boolean DEFAULT false NOT NULL,
  "palette_key" character varying DEFAULT 'signature'::character varying NOT NULL,
  "updated_by" uuid,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."productized_network_settings" (
  "network_id" uuid NOT NULL,
  "template_id" character varying(40) NOT NULL,
  "context_label" character varying(120) NOT NULL,
  "context_value" character varying(240) NOT NULL,
  "description" text,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."user_feature_discoveries" (
  "user_id" uuid NOT NULL,
  "feature_key" character varying(80) NOT NULL,
  "announcement_version" integer NOT NULL,
  "seen_at" timestamp with time zone DEFAULT now() NOT NULL
);
