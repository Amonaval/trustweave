-- TRUSTWEAVE D12 CANONICAL CURRENT-STATE BASELINE.
-- Materialized after fresh-project structural/security/API/behavior/product parity on 2026-09-20.
-- DO NOT apply these files to the historical golden project as an upgrade sequence.
-- Historical supabase/migrations/001..123 remain immutable upgrade history.

ALTER TABLE "public"."hs_amenities" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."hs_amenity_bookings" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."hs_asset_service_records" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."hs_assets" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."hs_bill_adjustments" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."hs_bill_line_items" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."hs_billing_cycles" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."hs_budget_lines" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."hs_charge_heads" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."hs_committee_assignments" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."hs_committee_terms" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."hs_complaint_comments" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."hs_complaint_routes" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."hs_complaints" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."hs_compliance_items" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."hs_domestic_staff" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."hs_emergency_contacts" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."hs_expenses" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."hs_funds" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."hs_governance_action_items" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."hs_governance_documents" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."hs_governance_meetings" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."hs_import_batches" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."hs_meeting_agenda_items" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."hs_move_requests" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."hs_notice_reads" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."hs_notices" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."hs_parking_allocations" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."hs_parking_slots" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."hs_payments" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."hs_pilot_checkpoints" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."hs_pilot_pricing_experiments" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."hs_pilot_runs" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."hs_pilot_usage_events" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."hs_renovation_requests" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."hs_resident_invitations" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."hs_resolution_votes" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."hs_resolutions" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."hs_security_operator_grants" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."hs_staff_unit_permissions" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."hs_unit_bills" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."hs_unit_occupancy_history" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."hs_vehicles" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."hs_vendor_contracts" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."hs_vendors" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."hs_visitors" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "hs_amenities_member_read" ON "public"."hs_amenities" AS PERMISSIVE FOR SELECT TO PUBLIC USING (is_network_member(network_id));
CREATE POLICY "hs_bookings_member_read" ON "public"."hs_amenity_bookings" AS PERMISSIVE FOR SELECT TO PUBLIC USING ((is_network_member(network_id) AND ((created_by = auth.uid()) OR is_network_admin(network_id))));
CREATE POLICY "hs_asset_service_member_read" ON "public"."hs_asset_service_records" AS PERMISSIVE FOR SELECT TO PUBLIC USING (is_network_member(network_id));
CREATE POLICY "hs_assets_member_read" ON "public"."hs_assets" AS PERMISSIVE FOR SELECT TO PUBLIC USING (is_network_member(network_id));
CREATE POLICY "hs_bill_adjustments_scoped_read" ON "public"."hs_bill_adjustments" AS PERMISSIVE FOR SELECT TO PUBLIC USING ((EXISTS ( SELECT 1
   FROM hs_unit_bills b
  WHERE ((b.id = hs_bill_adjustments.bill_id) AND (b.network_id = b.network_id) AND (is_network_admin(b.network_id) OR (EXISTS ( SELECT 1
           FROM (hs_unit_occupancy_history o
             JOIN network_entities p ON ((p.id = o.subject_entity_id)))
          WHERE ((o.network_id = b.network_id) AND (o.unit_entity_id = b.unit_entity_id) AND (o.ends_on IS NULL) AND (p.owner_user_id = auth.uid())))))))));
CREATE POLICY "hs_bill_line_items_scoped_read" ON "public"."hs_bill_line_items" AS PERMISSIVE FOR SELECT TO PUBLIC USING ((EXISTS ( SELECT 1
   FROM hs_unit_bills b
  WHERE ((b.id = hs_bill_line_items.bill_id) AND (b.network_id = b.network_id) AND (is_network_admin(b.network_id) OR (EXISTS ( SELECT 1
           FROM (hs_unit_occupancy_history o
             JOIN network_entities p ON ((p.id = o.subject_entity_id)))
          WHERE ((o.network_id = b.network_id) AND (o.unit_entity_id = b.unit_entity_id) AND (o.ends_on IS NULL) AND (p.owner_user_id = auth.uid())))))))));
CREATE POLICY "hs_billing_cycles_member_read" ON "public"."hs_billing_cycles" AS PERMISSIVE FOR SELECT TO PUBLIC USING (is_network_member(network_id));
CREATE POLICY "hs_budget_visibility_read" ON "public"."hs_budget_lines" AS PERMISSIVE FOR SELECT TO PUBLIC USING ((is_network_admin(network_id) OR (((visibility)::text = 'members'::text) AND is_network_member(network_id))));
CREATE POLICY "hs_charge_heads_member_read" ON "public"."hs_charge_heads" AS PERMISSIVE FOR SELECT TO PUBLIC USING (is_network_member(network_id));
CREATE POLICY "hs_committee_assignments_member_read" ON "public"."hs_committee_assignments" AS PERMISSIVE FOR SELECT TO PUBLIC USING (is_network_member(network_id));
CREATE POLICY "hs_committee_terms_member_read" ON "public"."hs_committee_terms" AS PERMISSIVE FOR SELECT TO PUBLIC USING (is_network_member(network_id));
CREATE POLICY "hs_comments_member_read" ON "public"."hs_complaint_comments" AS PERMISSIVE FOR SELECT TO PUBLIC USING ((is_network_member(network_id) AND (EXISTS ( SELECT 1
   FROM hs_complaints c
  WHERE ((c.id = hs_complaint_comments.complaint_id) AND (c.network_id = c.network_id) AND ((c.created_by = auth.uid()) OR is_network_admin(c.network_id)))))));
CREATE POLICY "hs_complaints_member_read" ON "public"."hs_complaints" AS PERMISSIVE FOR SELECT TO PUBLIC USING ((is_network_member(network_id) AND ((created_by = auth.uid()) OR is_network_admin(network_id))));
CREATE POLICY "hs_compliance_visibility_read" ON "public"."hs_compliance_items" AS PERMISSIVE FOR SELECT TO PUBLIC USING ((is_network_admin(network_id) OR (((visibility)::text = 'members'::text) AND is_network_member(network_id))));
CREATE POLICY "hs_staff_operator_read" ON "public"."hs_domestic_staff" AS PERMISSIVE FOR SELECT TO PUBLIC USING (hs5_is_operator(network_id, 'security'::text));
CREATE POLICY "hs_emergency_member_read" ON "public"."hs_emergency_contacts" AS PERMISSIVE FOR SELECT TO PUBLIC USING (is_network_member(network_id));
CREATE POLICY "hs_expenses_visibility_read" ON "public"."hs_expenses" AS PERMISSIVE FOR SELECT TO PUBLIC USING ((is_network_admin(network_id) OR (((visibility)::text = 'members'::text) AND is_network_member(network_id))));
CREATE POLICY "hs_funds_visibility_read" ON "public"."hs_funds" AS PERMISSIVE FOR SELECT TO PUBLIC USING ((is_network_admin(network_id) OR (((visibility)::text = 'members'::text) AND is_network_member(network_id))));
CREATE POLICY "hs_governance_actions_member_read" ON "public"."hs_governance_action_items" AS PERMISSIVE FOR SELECT TO PUBLIC USING (is_network_member(network_id));
CREATE POLICY "hs_governance_documents_visibility_read" ON "public"."hs_governance_documents" AS PERMISSIVE FOR SELECT TO PUBLIC USING ((is_network_admin(network_id) OR (((visibility)::text = 'members'::text) AND is_network_member(network_id))));
CREATE POLICY "hs_governance_meetings_member_read" ON "public"."hs_governance_meetings" AS PERMISSIVE FOR SELECT TO PUBLIC USING (is_network_member(network_id));
CREATE POLICY "hs_meeting_agenda_member_read" ON "public"."hs_meeting_agenda_items" AS PERMISSIVE FOR SELECT TO PUBLIC USING (is_network_member(network_id));
CREATE POLICY "hs_move_requests_scoped_read" ON "public"."hs_move_requests" AS PERMISSIVE FOR SELECT TO PUBLIC USING ((is_network_admin(network_id) OR (EXISTS ( SELECT 1
   FROM (hs_unit_occupancy_history o
     JOIN network_entities p ON ((p.id = o.subject_entity_id)))
  WHERE ((o.network_id = hs_move_requests.network_id) AND (o.unit_entity_id = hs_move_requests.unit_entity_id) AND (o.ends_on IS NULL) AND (p.owner_user_id = auth.uid()))))));
CREATE POLICY "hs_notices_member_read" ON "public"."hs_notices" AS PERMISSIVE FOR SELECT TO PUBLIC USING (is_network_member(network_id));
CREATE POLICY "hs_payments_scoped_read" ON "public"."hs_payments" AS PERMISSIVE FOR SELECT TO PUBLIC USING ((is_network_admin(network_id) OR (EXISTS ( SELECT 1
   FROM (hs_unit_occupancy_history o
     JOIN network_entities p ON ((p.id = o.subject_entity_id)))
  WHERE ((o.network_id = hs_payments.network_id) AND (o.unit_entity_id = hs_payments.unit_entity_id) AND (o.ends_on IS NULL) AND (p.owner_user_id = auth.uid()))))));
CREATE POLICY "hs_renovation_scoped_read" ON "public"."hs_renovation_requests" AS PERMISSIVE FOR SELECT TO PUBLIC USING ((is_network_admin(network_id) OR (EXISTS ( SELECT 1
   FROM (hs_unit_occupancy_history o
     JOIN network_entities p ON ((p.id = o.subject_entity_id)))
  WHERE ((o.network_id = hs_renovation_requests.network_id) AND (o.unit_entity_id = hs_renovation_requests.unit_entity_id) AND (o.ends_on IS NULL) AND (p.owner_user_id = auth.uid()))))));
CREATE POLICY "hs_resolution_votes_member_read" ON "public"."hs_resolution_votes" AS PERMISSIVE FOR SELECT TO PUBLIC USING (is_network_member(network_id));
CREATE POLICY "hs_resolutions_member_read" ON "public"."hs_resolutions" AS PERMISSIVE FOR SELECT TO PUBLIC USING (is_network_member(network_id));
CREATE POLICY "hs_security_grants_admin_read" ON "public"."hs_security_operator_grants" AS PERMISSIVE FOR SELECT TO PUBLIC USING (is_network_admin(network_id));
CREATE POLICY "hs_staff_permissions_scoped_read" ON "public"."hs_staff_unit_permissions" AS PERMISSIVE FOR SELECT TO PUBLIC USING ((hs5_is_operator(network_id, 'security'::text) OR (EXISTS ( SELECT 1
   FROM (hs_unit_occupancy_history o
     JOIN network_entities p ON ((p.id = o.subject_entity_id)))
  WHERE ((o.network_id = hs_staff_unit_permissions.network_id) AND (o.unit_entity_id = hs_staff_unit_permissions.unit_entity_id) AND (o.ends_on IS NULL) AND (p.owner_user_id = auth.uid()))))));
CREATE POLICY "hs_unit_bills_scoped_read" ON "public"."hs_unit_bills" AS PERMISSIVE FOR SELECT TO PUBLIC USING ((is_network_admin(network_id) OR (EXISTS ( SELECT 1
   FROM (hs_unit_occupancy_history o
     JOIN network_entities p ON ((p.id = o.subject_entity_id)))
  WHERE ((o.network_id = hs_unit_bills.network_id) AND (o.unit_entity_id = hs_unit_bills.unit_entity_id) AND (o.ends_on IS NULL) AND (p.owner_user_id = auth.uid()))))));
CREATE POLICY "hs_vendor_contracts_admin_read" ON "public"."hs_vendor_contracts" AS PERMISSIVE FOR SELECT TO PUBLIC USING (is_network_admin(network_id));
CREATE POLICY "hs_vendors_member_read" ON "public"."hs_vendors" AS PERMISSIVE FOR SELECT TO PUBLIC USING (is_network_member(network_id));
CREATE POLICY "hs_visitors_scoped_read" ON "public"."hs_visitors" AS PERMISSIVE FOR SELECT TO PUBLIC USING ((hs5_is_operator(network_id, 'security'::text) OR (EXISTS ( SELECT 1
   FROM (hs_unit_occupancy_history o
     JOIN network_entities p ON ((p.id = o.subject_entity_id)))
  WHERE ((o.network_id = hs_visitors.network_id) AND (o.unit_entity_id = hs_visitors.unit_entity_id) AND (o.ends_on IS NULL) AND (p.owner_user_id = auth.uid()))))));
