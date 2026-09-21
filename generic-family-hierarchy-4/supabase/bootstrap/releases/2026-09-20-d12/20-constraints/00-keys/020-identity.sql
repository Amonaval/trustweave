-- TRUSTWEAVE D12 CANONICAL CURRENT-STATE BASELINE.
-- Materialized after fresh-project structural/security/API/behavior/product parity on 2026-09-20.
-- DO NOT apply these files to the historical golden project as an upgrade sequence.
-- Historical supabase/migrations/001..123 remain immutable upgrade history.

ALTER TABLE "public"."family_members" ADD CONSTRAINT "family_members_pkey" PRIMARY KEY (id);
ALTER TABLE "public"."member_invitations" ADD CONSTRAINT "member_invitations_pkey" PRIMARY KEY (id);
ALTER TABLE "public"."member_invitations" ADD CONSTRAINT "member_invitations_token_hash_key" UNIQUE (token_hash);
ALTER TABLE "public"."network_memberships" ADD CONSTRAINT "network_memberships_pkey" PRIMARY KEY (network_id, user_id);
ALTER TABLE "public"."network_participation_invitations" ADD CONSTRAINT "network_participation_invitations_pkey" PRIMARY KEY (id);
ALTER TABLE "public"."network_participation_invitations" ADD CONSTRAINT "network_participation_invitations_token_key" UNIQUE (token);
ALTER TABLE "public"."network_role_capabilities" ADD CONSTRAINT "network_role_capabilities_pkey" PRIMARY KEY (role, capability);
ALTER TABLE "public"."profiles" ADD CONSTRAINT "profiles_pkey" PRIMARY KEY (id);
