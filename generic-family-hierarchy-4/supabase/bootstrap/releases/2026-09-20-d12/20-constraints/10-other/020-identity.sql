-- TRUSTWEAVE D12 CANONICAL CURRENT-STATE BASELINE.
-- Materialized after fresh-project structural/security/API/behavior/product parity on 2026-09-20.
-- DO NOT apply these files to the historical golden project as an upgrade sequence.
-- Historical supabase/migrations/001..123 remain immutable upgrade history.

ALTER TABLE "public"."family_members" ADD CONSTRAINT "family_members_a4_social_urls" CHECK (a4_safe_external_url(facebook_url, 'facebook'::text) AND a4_safe_external_url(instagram_url, 'instagram'::text) AND a4_safe_external_url(other_social_url, 'other'::text) AND (facebook_url IS NOT NULL OR facebook_public = false) AND (instagram_url IS NOT NULL OR instagram_public = false) AND (other_social_url IS NOT NULL OR other_social_public = false));
ALTER TABLE "public"."family_members" ADD CONSTRAINT "family_members_avatar_style_check" CHECK (avatar_style::text = ANY (ARRAY['initials'::character varying, 'leaf'::character varying, 'sun'::character varying, 'sparkles'::character varying, 'heart'::character varying, 'person'::character varying]::text[]));
ALTER TABLE "public"."family_members" ADD CONSTRAINT "family_members_contact_visibility_check" CHECK (contact_visibility::text = ANY (ARRAY['member'::character varying, 'admin'::character varying]::text[]));
ALTER TABLE "public"."family_members" ADD CONSTRAINT "family_members_gender_check" CHECK (gender IS NULL OR (gender::text = ANY (ARRAY['Male'::character varying, 'Female'::character varying, 'Other'::character varying]::text[])));
ALTER TABLE "public"."family_members" ADD CONSTRAINT "family_members_generation_level_check" CHECK (generation_level >= 1);
ALTER TABLE "public"."family_members" ADD CONSTRAINT "family_members_network_id_fkey" FOREIGN KEY (network_id) REFERENCES networks(id) ON DELETE CASCADE;
ALTER TABLE "public"."family_members" ADD CONSTRAINT "family_members_profile_status_check" CHECK (profile_status::text = ANY (ARRAY['approved'::character varying, 'pending'::character varying, 'disabled'::character varying]::text[]));
ALTER TABLE "public"."family_members" ADD CONSTRAINT "family_members_profile_visibility_check" CHECK (profile_visibility::text = ANY (ARRAY['public'::character varying, 'member'::character varying, 'admin'::character varying]::text[]));
ALTER TABLE "public"."member_invitations" ADD CONSTRAINT "member_invitations_accepted_by_fkey" FOREIGN KEY (accepted_by) REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE "public"."member_invitations" ADD CONSTRAINT "member_invitations_created_by_fkey" FOREIGN KEY (created_by) REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE "public"."member_invitations" ADD CONSTRAINT "member_invitations_delivery_channel_check" CHECK (delivery_channel::text = ANY (ARRAY['link'::character varying, 'email'::character varying, 'whatsapp'::character varying, 'sms'::character varying, 'print'::character varying, 'other'::character varying]::text[]));
ALTER TABLE "public"."member_invitations" ADD CONSTRAINT "member_invitations_member_id_fkey" FOREIGN KEY (member_id) REFERENCES family_members(id) ON DELETE CASCADE;
ALTER TABLE "public"."member_invitations" ADD CONSTRAINT "member_invitations_network_id_fkey" FOREIGN KEY (network_id) REFERENCES networks(id) ON DELETE CASCADE;
ALTER TABLE "public"."member_invitations" ADD CONSTRAINT "member_invitations_resend_of_fkey" FOREIGN KEY (resend_of) REFERENCES member_invitations(id) ON DELETE SET NULL;
ALTER TABLE "public"."member_invitations" ADD CONSTRAINT "member_invitations_revoked_by_fkey" FOREIGN KEY (revoked_by) REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE "public"."network_memberships" ADD CONSTRAINT "network_memberships_member_id_fkey" FOREIGN KEY (member_id) REFERENCES family_members(id) ON DELETE SET NULL;
ALTER TABLE "public"."network_memberships" ADD CONSTRAINT "network_memberships_network_id_fkey" FOREIGN KEY (network_id) REFERENCES networks(id) ON DELETE CASCADE;
ALTER TABLE "public"."network_memberships" ADD CONSTRAINT "network_memberships_role_check" CHECK (role::text = ANY (ARRAY['owner'::character varying, 'admin'::character varying, 'member'::character varying]::text[]));
ALTER TABLE "public"."network_memberships" ADD CONSTRAINT "network_memberships_status_check" CHECK (status::text = ANY (ARRAY['active'::character varying, 'invited'::character varying, 'suspended'::character varying, 'left'::character varying]::text[]));
ALTER TABLE "public"."network_memberships" ADD CONSTRAINT "network_memberships_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE "public"."network_participation_invitations" ADD CONSTRAINT "network_participation_invitations_accepted_by_fkey" FOREIGN KEY (accepted_by) REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE "public"."network_participation_invitations" ADD CONSTRAINT "network_participation_invitations_created_by_fkey" FOREIGN KEY (created_by) REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE "public"."network_participation_invitations" ADD CONSTRAINT "network_participation_invitations_invited_role_check" CHECK (invited_role::text = ANY (ARRAY['admin'::character varying, 'member'::character varying]::text[]));
ALTER TABLE "public"."network_participation_invitations" ADD CONSTRAINT "network_participation_invitations_network_id_fkey" FOREIGN KEY (network_id) REFERENCES networks(id) ON DELETE CASCADE;
ALTER TABLE "public"."network_participation_invitations" ADD CONSTRAINT "network_participation_invitations_status_check" CHECK (status::text = ANY (ARRAY['pending'::character varying, 'accepted'::character varying, 'revoked'::character varying, 'expired'::character varying]::text[]));
ALTER TABLE "public"."network_role_capabilities" ADD CONSTRAINT "network_role_capabilities_role_check" CHECK (role::text = ANY (ARRAY['member'::character varying, 'admin'::character varying]::text[]));
ALTER TABLE "public"."profiles" ADD CONSTRAINT "profiles_active_network_id_fkey" FOREIGN KEY (active_network_id) REFERENCES networks(id) ON DELETE SET NULL;
ALTER TABLE "public"."profiles" ADD CONSTRAINT "profiles_experience_level_check" CHECK (experience_level::text = ANY (ARRAY['simple'::character varying, 'connected'::character varying, 'explorer'::character varying]::text[]));
ALTER TABLE "public"."profiles" ADD CONSTRAINT "profiles_id_fkey" FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE "public"."profiles" ADD CONSTRAINT "profiles_member_id_fkey" FOREIGN KEY (member_id) REFERENCES family_members(id) ON DELETE SET NULL;
ALTER TABLE "public"."profiles" ADD CONSTRAINT "profiles_role_check" CHECK (role::text = ANY (ARRAY['member'::character varying, 'admin'::character varying]::text[]));
