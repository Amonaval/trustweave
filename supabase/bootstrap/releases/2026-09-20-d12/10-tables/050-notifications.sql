-- TRUSTWEAVE D12 CANONICAL CURRENT-STATE BASELINE.
-- Materialized after fresh-project structural/security/API/behavior/product parity on 2026-09-20.
-- DO NOT apply these files to the historical golden project as an upgrade sequence.
-- Historical supabase/migrations/001..123 remain immutable upgrade history.

CREATE TABLE IF NOT EXISTS "public"."network_notification_roles" (
  "network_id" uuid NOT NULL,
  "role_key" character varying(60) NOT NULL,
  "user_id" uuid NOT NULL,
  "label" character varying(100) NOT NULL,
  "active" boolean DEFAULT true NOT NULL,
  "set_by" uuid,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."notification_preferences" (
  "user_id" uuid NOT NULL,
  "birthdays" boolean DEFAULT true NOT NULL,
  "anniversaries" boolean DEFAULT true NOT NULL,
  "invitations" boolean DEFAULT true NOT NULL,
  "memories" boolean DEFAULT false NOT NULL,
  "gatherings" boolean DEFAULT true NOT NULL,
  "contributions" boolean DEFAULT false NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  "network_id" uuid DEFAULT current_network_id() NOT NULL,
  "introductions" boolean DEFAULT true NOT NULL,
  "family_changes" boolean DEFAULT true NOT NULL,
  "preferred_weekday" smallint DEFAULT 0 NOT NULL,
  "push_enabled" boolean DEFAULT false NOT NULL,
  "quiet_start" time without time zone,
  "quiet_end" time without time zone,
  "timezone" character varying(80) DEFAULT 'Asia/Kolkata'::character varying NOT NULL,
  "urgent_bypass_quiet" boolean DEFAULT true NOT NULL,
  "engagement_categories" jsonb DEFAULT jsonb_build_object('posts', jsonb_build_object('inbox', true, 'push', true), 'mentions', jsonb_build_object('inbox', true, 'push', true), 'complaints', jsonb_build_object('inbox', true, 'push', true), 'funds', jsonb_build_object('inbox', true, 'push', true), 'elections', jsonb_build_object('inbox', true, 'push', true), 'events_membership', jsonb_build_object('inbox', true, 'push', true), 'general', jsonb_build_object('inbox', true, 'push', true)) NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."notifications" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "user_id" uuid NOT NULL,
  "type" character varying(50) NOT NULL,
  "title" character varying(180) NOT NULL,
  "body" text,
  "href" text,
  "read_at" timestamp with time zone,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "network_id" uuid DEFAULT current_network_id() NOT NULL,
  "actor_id" uuid,
  "entity_type" character varying(60),
  "entity_id" uuid,
  "priority" character varying(12) DEFAULT 'normal'::character varying NOT NULL,
  "metadata" jsonb DEFAULT '{}'::jsonb NOT NULL,
  "archived_at" timestamp with time zone
);

CREATE TABLE IF NOT EXISTS "public"."push_subscriptions" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "user_id" uuid NOT NULL,
  "endpoint" text NOT NULL,
  "p256dh" text NOT NULL,
  "auth_key" text NOT NULL,
  "user_agent" text,
  "active" boolean DEFAULT true NOT NULL,
  "last_seen_at" timestamp with time zone DEFAULT now() NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
