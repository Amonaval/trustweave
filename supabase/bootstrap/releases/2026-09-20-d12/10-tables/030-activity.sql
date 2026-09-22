-- TRUSTWEAVE D12 CANONICAL CURRENT-STATE BASELINE.
-- Materialized after fresh-project structural/security/API/behavior/product parity on 2026-09-20.
-- DO NOT apply these files to the historical golden project as an upgrade sequence.
-- Historical supabase/migrations/001..123 remain immutable upgrade history.

CREATE TABLE IF NOT EXISTS "public"."community_event_responses" (
  "event_id" uuid NOT NULL,
  "user_id" uuid NOT NULL,
  "response" character varying(20) NOT NULL,
  "guest_count" integer DEFAULT 0 NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  "network_id" uuid DEFAULT current_network_id() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."community_events" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "group_id" uuid,
  "title" character varying(180) NOT NULL,
  "description" text,
  "event_at" timestamp with time zone,
  "location" character varying(180),
  "status" character varying(20) DEFAULT 'planning'::character varying NOT NULL,
  "created_by" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  "network_id" uuid DEFAULT current_network_id() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."community_family_links" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "space_id" uuid NOT NULL,
  "network_id" uuid NOT NULL,
  "status" character varying(20) DEFAULT 'pending'::character varying NOT NULL,
  "requested_by" uuid,
  "reviewed_by" uuid,
  "reviewed_at" timestamp with time zone,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."community_group_members" (
  "group_id" uuid NOT NULL,
  "member_id" uuid NOT NULL,
  "network_id" uuid DEFAULT current_network_id() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."community_groups" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "name" character varying(160) NOT NULL,
  "description" text,
  "group_type" character varying(20) DEFAULT 'branch'::character varying NOT NULL,
  "created_by" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "network_id" uuid DEFAULT current_network_id() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."community_introduction_requests" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "space_id" uuid NOT NULL,
  "requester_network_id" uuid NOT NULL,
  "requester_user_id" uuid NOT NULL,
  "target_card_id" uuid NOT NULL,
  "target_network_id" uuid NOT NULL,
  "target_user_id" uuid NOT NULL,
  "message" text,
  "status" character varying(24) DEFAULT 'pending'::character varying NOT NULL,
  "path_snapshot" jsonb DEFAULT '[]'::jsonb NOT NULL,
  "responded_by" uuid,
  "responded_at" timestamp with time zone,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."community_posts" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "space_id" uuid NOT NULL,
  "network_id" uuid NOT NULL,
  "author_user_id" uuid NOT NULL,
  "target_member_id" uuid,
  "category" character varying(40) NOT NULL,
  "title" character varying(220) NOT NULL,
  "body" text,
  "city" character varying(120),
  "status" character varying(20) DEFAULT 'open'::character varying NOT NULL,
  "expires_at" timestamp with time zone,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."community_profile_cards" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "space_id" uuid NOT NULL,
  "network_id" uuid NOT NULL,
  "member_id" uuid NOT NULL,
  "owner_user_id" uuid NOT NULL,
  "category" character varying(40) NOT NULL,
  "display_name" character varying(180) NOT NULL,
  "photo_url" text,
  "profession" character varying(160),
  "city" character varying(120),
  "headline" character varying(180),
  "summary" text,
  "contact_mode" character varying(24) DEFAULT 'family_intro'::character varying NOT NULL,
  "featured" boolean DEFAULT false NOT NULL,
  "featured_label" character varying(120),
  "active" boolean DEFAULT true NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."community_spaces" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "parent_id" uuid,
  "name" character varying(160) NOT NULL,
  "slug" character varying(180) NOT NULL,
  "space_type" character varying(32) DEFAULT 'community'::character varying NOT NULL,
  "city" character varying(120),
  "state" character varying(120),
  "country" character varying(120),
  "status" character varying(20) DEFAULT 'active'::character varying NOT NULL,
  "created_by" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."community_trust_edges" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "space_id" uuid NOT NULL,
  "requester_network_id" uuid NOT NULL,
  "recipient_network_id" uuid NOT NULL,
  "status" character varying(20) DEFAULT 'pending'::character varying NOT NULL,
  "context_label" character varying(180),
  "requested_by" uuid NOT NULL,
  "reviewed_by" uuid,
  "reviewed_at" timestamp with time zone,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."network_activities" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "network_id" uuid NOT NULL,
  "activity_type" character varying(30) NOT NULL,
  "title" character varying(220) NOT NULL,
  "body" text,
  "starts_at" timestamp with time zone,
  "ends_at" timestamp with time zone,
  "place" character varying(220),
  "visibility" character varying(20) DEFAULT 'members'::character varying NOT NULL,
  "metadata" jsonb DEFAULT '{}'::jsonb NOT NULL,
  "created_by" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."network_activity_comments" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "activity_id" uuid NOT NULL,
  "network_id" uuid NOT NULL,
  "user_id" uuid NOT NULL,
  "body" character varying(1000) NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."network_activity_reactions" (
  "activity_id" uuid NOT NULL,
  "network_id" uuid NOT NULL,
  "user_id" uuid NOT NULL,
  "reaction" character varying(20) DEFAULT 'like'::character varying NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."network_activity_rsvps" (
  "activity_id" uuid NOT NULL,
  "network_id" uuid NOT NULL,
  "user_id" uuid NOT NULL,
  "response" character varying(20) NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."network_media_assets" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "network_id" uuid NOT NULL,
  "owner_user_id" uuid NOT NULL,
  "bucket" character varying(40) NOT NULL,
  "object_path" text NOT NULL,
  "thumbnail_path" text,
  "media_kind" character varying(30) NOT NULL,
  "entity_type" character varying(80),
  "entity_id" text,
  "mime_type" character varying(100) DEFAULT 'image/webp'::character varying NOT NULL,
  "bytes" bigint DEFAULT 0 NOT NULL,
  "thumbnail_bytes" bigint DEFAULT 0 NOT NULL,
  "width" integer,
  "height" integer,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  "lifecycle_state" character varying(20) DEFAULT 'active'::character varying NOT NULL,
  "archived_at" timestamp with time zone,
  "archived_by" uuid,
  "delete_requested_at" timestamp with time zone,
  "delete_requested_by" uuid,
  "deleted_at" timestamp with time zone,
  "deleted_by" uuid,
  "delete_reason" text
);

CREATE TABLE IF NOT EXISTS "public"."participation_events" (
  "id" bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  "event_type" character varying(40) NOT NULL,
  "public_member_id" uuid,
  "channel" character varying(30),
  "session_hash" text,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "network_id" uuid DEFAULT current_network_id() NOT NULL
);
