-- TRUSTWEAVE D12 CANONICAL CURRENT-STATE BASELINE.
-- Materialized after fresh-project structural/security/API/behavior/product parity on 2026-09-20.
-- DO NOT apply these files to the historical golden project as an upgrade sequence.
-- Historical supabase/migrations/001..123 remain immutable upgrade history.

CREATE TABLE IF NOT EXISTS "public"."family_members" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "full_name" character varying(150) NOT NULL,
  "date_of_birth" date,
  "date_of_death" date,
  "generation_level" integer NOT NULL,
  "profession" character varying(100),
  "city" character varying(100),
  "country" character varying(100) DEFAULT 'India'::character varying,
  "photo_url" text DEFAULT ''::text,
  "bio" text DEFAULT ''::text,
  "phone" character varying(30),
  "email" character varying(255),
  "profile_status" character varying(20) DEFAULT 'approved'::character varying NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  "latitude" numeric(10,7),
  "longitude" numeric(10,7),
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
  "other_social_public" boolean DEFAULT false NOT NULL,
  "gender" character varying(10)
);

CREATE TABLE IF NOT EXISTS "public"."member_invitations" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "member_id" uuid NOT NULL,
  "token_hash" text NOT NULL,
  "created_by" uuid,
  "expires_at" timestamp with time zone NOT NULL,
  "used_at" timestamp with time zone,
  "accepted_by" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "revoked_at" timestamp with time zone,
  "revoked_by" uuid,
  "first_opened_at" timestamp with time zone,
  "last_sent_at" timestamp with time zone,
  "delivery_channel" character varying(20) DEFAULT 'link'::character varying NOT NULL,
  "recipient_hint" character varying(160),
  "resend_of" uuid,
  "network_id" uuid DEFAULT current_network_id() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."network_memberships" (
  "network_id" uuid NOT NULL,
  "user_id" uuid NOT NULL,
  "role" character varying(20) DEFAULT 'member'::character varying NOT NULL,
  "status" character varying(20) DEFAULT 'active'::character varying NOT NULL,
  "joined_at" timestamp with time zone DEFAULT now() NOT NULL,
  "member_id" uuid
);

CREATE TABLE IF NOT EXISTS "public"."network_participation_invitations" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "network_id" uuid NOT NULL,
  "email" text NOT NULL,
  "target_ref" uuid,
  "target_kind" character varying(40),
  "invited_role" character varying(20) DEFAULT 'member'::character varying NOT NULL,
  "token" uuid DEFAULT gen_random_uuid() NOT NULL,
  "status" character varying(20) DEFAULT 'pending'::character varying NOT NULL,
  "expires_at" timestamp with time zone DEFAULT (now() + '14 days'::interval) NOT NULL,
  "created_by" uuid,
  "accepted_by" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  "accepted_at" timestamp with time zone,
  "resend_count" integer DEFAULT 0 NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."network_role_capabilities" (
  "role" character varying(20) NOT NULL,
  "capability" character varying(60) NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."profiles" (
  "id" uuid NOT NULL,
  "full_name" character varying(150),
  "role" character varying(20) DEFAULT 'member'::character varying NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  "member_id" uuid,
  "active_network_id" uuid,
  "experience_level" character varying(20) DEFAULT 'simple'::character varying NOT NULL,
  "family_lobby_mode" boolean DEFAULT false NOT NULL
);
