-- TRUSTWEAVE D12 CANONICAL CURRENT-STATE BASELINE.
-- Materialized after fresh-project structural/security/API/behavior/product parity on 2026-09-20.
-- DO NOT apply these files to the historical golden project as an upgrade sequence.
-- Historical supabase/migrations/001..123 remain immutable upgrade history.

ALTER TABLE "public"."community_event_responses" ADD CONSTRAINT "community_event_responses_pkey" PRIMARY KEY (event_id, user_id);
ALTER TABLE "public"."community_events" ADD CONSTRAINT "community_events_pkey" PRIMARY KEY (id);
ALTER TABLE "public"."community_family_links" ADD CONSTRAINT "community_family_links_pkey" PRIMARY KEY (id);
ALTER TABLE "public"."community_family_links" ADD CONSTRAINT "community_family_links_space_id_network_id_key" UNIQUE (space_id, network_id);
ALTER TABLE "public"."community_group_members" ADD CONSTRAINT "community_group_members_pkey" PRIMARY KEY (group_id, member_id);
ALTER TABLE "public"."community_groups" ADD CONSTRAINT "community_groups_pkey" PRIMARY KEY (id);
ALTER TABLE "public"."community_introduction_requests" ADD CONSTRAINT "community_introduction_requests_pkey" PRIMARY KEY (id);
ALTER TABLE "public"."community_posts" ADD CONSTRAINT "community_posts_pkey" PRIMARY KEY (id);
ALTER TABLE "public"."community_profile_cards" ADD CONSTRAINT "community_profile_cards_pkey" PRIMARY KEY (id);
ALTER TABLE "public"."community_profile_cards" ADD CONSTRAINT "community_profile_cards_space_id_member_id_category_key" UNIQUE (space_id, member_id, category);
ALTER TABLE "public"."community_spaces" ADD CONSTRAINT "community_spaces_pkey" PRIMARY KEY (id);
ALTER TABLE "public"."community_spaces" ADD CONSTRAINT "community_spaces_slug_key" UNIQUE (slug);
ALTER TABLE "public"."community_trust_edges" ADD CONSTRAINT "community_trust_edges_pkey" PRIMARY KEY (id);
ALTER TABLE "public"."network_activities" ADD CONSTRAINT "network_activities_pkey" PRIMARY KEY (id);
ALTER TABLE "public"."network_activities" ADD CONSTRAINT "uq_network_activities_id_network" UNIQUE (id, network_id);
ALTER TABLE "public"."network_activity_comments" ADD CONSTRAINT "network_activity_comments_pkey" PRIMARY KEY (id);
ALTER TABLE "public"."network_activity_reactions" ADD CONSTRAINT "network_activity_reactions_pkey" PRIMARY KEY (activity_id, user_id);
ALTER TABLE "public"."network_activity_rsvps" ADD CONSTRAINT "network_activity_rsvps_pkey" PRIMARY KEY (activity_id, user_id);
ALTER TABLE "public"."network_media_assets" ADD CONSTRAINT "network_media_assets_bucket_object_path_key" UNIQUE (bucket, object_path);
ALTER TABLE "public"."network_media_assets" ADD CONSTRAINT "network_media_assets_pkey" PRIMARY KEY (id);
ALTER TABLE "public"."participation_events" ADD CONSTRAINT "participation_events_pkey" PRIMARY KEY (id);
