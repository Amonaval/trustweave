-- TRUSTWEAVE D12 CANONICAL CURRENT-STATE BASELINE.
-- Materialized after fresh-project structural/security/API/behavior/product parity on 2026-09-20.
-- DO NOT apply these files to the historical golden project as an upgrade sequence.
-- Historical supabase/migrations/001..123 remain immutable upgrade history.

CREATE INDEX idx_hs_amenity_bookings_network_time ON public.hs_amenity_bookings USING btree (network_id, amenity_id, starts_at, status);
CREATE INDEX idx_hs_asset_service_due ON public.hs_asset_service_records USING btree (network_id, next_due_on);
CREATE INDEX idx_hs_bill_line_items_bill ON public.hs_bill_line_items USING btree (network_id, bill_id);
CREATE INDEX idx_hs_committee_assignments_term ON public.hs_committee_assignments USING btree (network_id, term_id, starts_on DESC);
CREATE INDEX idx_hs_complaint_comments_complaint ON public.hs_complaint_comments USING btree (network_id, complaint_id, created_at);
CREATE INDEX idx_hs_complaints_network_status ON public.hs_complaints USING btree (network_id, status, priority, created_at DESC);
CREATE INDEX idx_hs_compliance_due ON public.hs_compliance_items USING btree (network_id, status, due_on);
CREATE INDEX idx_hs_expenses_network_date ON public.hs_expenses USING btree (network_id, incurred_on DESC, category);
CREATE INDEX idx_hs_governance_actions ON public.hs_governance_action_items USING btree (network_id, status, due_on);
CREATE INDEX idx_hs_governance_meetings_network_date ON public.hs_governance_meetings USING btree (network_id, scheduled_at DESC);
CREATE INDEX idx_hs_notice_reads_network_time ON public.hs_notice_reads USING btree (network_id, read_at DESC);
CREATE INDEX idx_hs_notices_network_active ON public.hs_notices USING btree (network_id, pinned DESC, created_at DESC);
CREATE UNIQUE INDEX uq_hs_active_parking_slot ON public.hs_parking_allocations USING btree (network_id, parking_slot_id) WHERE (ends_on IS NULL);
CREATE INDEX idx_hs_payments_network_unit ON public.hs_payments USING btree (network_id, unit_entity_id, paid_on DESC);
CREATE INDEX idx_hs_pilot_checkpoints_run ON public.hs_pilot_checkpoints USING btree (pilot_run_id, checkpoint_on DESC, created_at DESC);
CREATE INDEX idx_hs_pilot_pricing_network ON public.hs_pilot_pricing_experiments USING btree (network_id, tested_on DESC);
CREATE INDEX idx_hs_pilot_runs_network ON public.hs_pilot_runs USING btree (network_id, created_at DESC);
CREATE UNIQUE INDEX uq_hs_pilot_one_active ON public.hs_pilot_runs USING btree (network_id) WHERE ((status)::text = 'active'::text);
CREATE INDEX idx_hs_pilot_usage_network_time ON public.hs_pilot_usage_events USING btree (network_id, created_at DESC, event_key);
CREATE INDEX idx_hs_pilot_usage_unit_time ON public.hs_pilot_usage_events USING btree (network_id, unit_entity_id, created_at DESC);
CREATE INDEX idx_hs_invites_email ON public.hs_resident_invitations USING btree (network_id, lower(email), status);
CREATE INDEX idx_hs_resolutions_network_status ON public.hs_resolutions USING btree (network_id, status, created_at DESC);
CREATE INDEX idx_hs_staff_permissions ON public.hs_staff_unit_permissions USING btree (network_id, unit_entity_id, status);
CREATE INDEX idx_hs_unit_bills_network_unit ON public.hs_unit_bills USING btree (network_id, unit_entity_id, due_on DESC, status);
CREATE INDEX idx_hs_unit_occupancy_network_unit ON public.hs_unit_occupancy_history USING btree (network_id, unit_entity_id, starts_on DESC);
CREATE INDEX idx_hs_unit_occupancy_subject ON public.hs_unit_occupancy_history USING btree (network_id, subject_entity_id, starts_on DESC);
CREATE UNIQUE INDEX uq_hs_current_primary_role ON public.hs_unit_occupancy_history USING btree (network_id, unit_entity_id, occupancy_role) WHERE ((ends_on IS NULL) AND is_primary);
CREATE INDEX idx_hs_vendor_contracts_network_vendor ON public.hs_vendor_contracts USING btree (network_id, vendor_id, ends_on);
CREATE INDEX idx_hs_visitors_network_status ON public.hs_visitors USING btree (network_id, status, COALESCE(expected_at, created_at) DESC);
