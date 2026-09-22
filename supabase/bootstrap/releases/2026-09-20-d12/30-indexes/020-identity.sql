-- TRUSTWEAVE D12 CANONICAL CURRENT-STATE BASELINE.
-- Materialized after fresh-project structural/security/API/behavior/product parity on 2026-09-20.
-- DO NOT apply these files to the historical golden project as an upgrade sequence.
-- Historical supabase/migrations/001..123 remain immutable upgrade history.

CREATE INDEX idx_family_members_city ON public.family_members USING btree (city);
CREATE INDEX idx_family_members_coordinates ON public.family_members USING btree (latitude, longitude);
CREATE INDEX idx_family_members_country ON public.family_members USING btree (country);
CREATE INDEX idx_family_members_generation ON public.family_members USING btree (generation_level);
CREATE INDEX idx_family_members_network ON public.family_members USING btree (network_id);
CREATE INDEX idx_family_members_profession ON public.family_members USING btree (profession);
CREATE INDEX idx_family_members_profile_visibility ON public.family_members USING btree (profile_visibility);
CREATE INDEX idx_member_invitations_expires ON public.member_invitations USING btree (expires_at);
CREATE INDEX idx_member_invitations_member ON public.member_invitations USING btree (member_id);
CREATE INDEX idx_member_invitations_network ON public.member_invitations USING btree (network_id);
CREATE INDEX idx_member_invitations_status ON public.member_invitations USING btree (revoked_at, used_at, expires_at, created_at DESC);
CREATE INDEX idx_network_memberships_network_status_joined ON public.network_memberships USING btree (network_id, status, joined_at DESC, user_id);
CREATE INDEX idx_network_memberships_user ON public.network_memberships USING btree (user_id, status, network_id);
CREATE UNIQUE INDEX uq_network_memberships_claim ON public.network_memberships USING btree (network_id, member_id) WHERE (member_id IS NOT NULL);
CREATE INDEX idx_network_participation_email ON public.network_participation_invitations USING btree (network_id, lower(email));
CREATE INDEX idx_network_participation_invites ON public.network_participation_invitations USING btree (network_id, status, created_at DESC);
CREATE UNIQUE INDEX uq_profiles_member_id ON public.profiles USING btree (member_id) WHERE (member_id IS NOT NULL);
