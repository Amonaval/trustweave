-- TRUSTWEAVE D12 CANONICAL CURRENT-STATE BASELINE.
-- Materialized after fresh-project structural/security/API/behavior/product parity on 2026-09-20.
-- DO NOT apply these files to the historical golden project as an upgrade sequence.
-- Historical supabase/migrations/001..123 remain immutable upgrade history.

CREATE TABLE IF NOT EXISTS "public"."hs_amenities" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "network_id" uuid NOT NULL,
  "name" character varying(180) NOT NULL,
  "description" text,
  "location" character varying(220),
  "capacity" integer,
  "booking_mode" character varying(20) DEFAULT 'approval'::character varying NOT NULL,
  "status" character varying(20) DEFAULT 'active'::character varying NOT NULL,
  "rules" jsonb DEFAULT '{}'::jsonb NOT NULL,
  "created_by" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."hs_amenity_bookings" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "network_id" uuid NOT NULL,
  "amenity_id" uuid NOT NULL,
  "unit_entity_id" uuid,
  "starts_at" timestamp with time zone NOT NULL,
  "ends_at" timestamp with time zone NOT NULL,
  "purpose" character varying(300),
  "status" character varying(20) DEFAULT 'pending'::character varying NOT NULL,
  "created_by" uuid,
  "reviewed_by" uuid,
  "reviewed_at" timestamp with time zone,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."hs_asset_service_records" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "network_id" uuid NOT NULL,
  "asset_id" uuid NOT NULL,
  "service_type" character varying(80) NOT NULL,
  "serviced_on" date DEFAULT CURRENT_DATE NOT NULL,
  "next_due_on" date,
  "vendor_id" uuid,
  "notes" text,
  "cost" numeric(14,2),
  "created_by" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."hs_assets" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "network_id" uuid NOT NULL,
  "asset_code" character varying(80) NOT NULL,
  "name" character varying(180) NOT NULL,
  "category" character varying(60) NOT NULL,
  "location" character varying(180),
  "status" character varying(20) DEFAULT 'active'::character varying NOT NULL,
  "commissioned_on" date,
  "warranty_until" date,
  "vendor_id" uuid,
  "metadata" jsonb DEFAULT '{}'::jsonb NOT NULL,
  "created_by" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."hs_bill_adjustments" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "network_id" uuid NOT NULL,
  "bill_id" uuid NOT NULL,
  "adjustment_type" character varying(20) NOT NULL,
  "amount" numeric(14,2) NOT NULL,
  "reason" text NOT NULL,
  "created_by" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."hs_bill_line_items" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "network_id" uuid NOT NULL,
  "bill_id" uuid NOT NULL,
  "charge_head_id" uuid,
  "label" character varying(180) NOT NULL,
  "amount" numeric(14,2) NOT NULL,
  "metadata" jsonb DEFAULT '{}'::jsonb NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."hs_billing_cycles" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "network_id" uuid NOT NULL,
  "label" character varying(180) NOT NULL,
  "period_start" date NOT NULL,
  "period_end" date NOT NULL,
  "due_on" date NOT NULL,
  "status" character varying(20) DEFAULT 'draft'::character varying NOT NULL,
  "grace_days" integer DEFAULT 0 NOT NULL,
  "penalty_rate_monthly" numeric(7,4) DEFAULT 0 NOT NULL,
  "issued_at" timestamp with time zone,
  "closed_at" timestamp with time zone,
  "created_by" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."hs_budget_lines" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "network_id" uuid NOT NULL,
  "financial_year" character varying(12) NOT NULL,
  "category" character varying(100) NOT NULL,
  "label" character varying(180) NOT NULL,
  "budget_amount" numeric(16,2) DEFAULT 0 NOT NULL,
  "visibility" character varying(20) DEFAULT 'members'::character varying NOT NULL,
  "created_by" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."hs_charge_heads" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "network_id" uuid NOT NULL,
  "code" character varying(60) NOT NULL,
  "label" character varying(180) NOT NULL,
  "category" character varying(40) DEFAULT 'maintenance'::character varying NOT NULL,
  "calculation_mode" character varying(24) DEFAULT 'fixed_per_unit'::character varying NOT NULL,
  "default_amount" numeric(14,2) DEFAULT 0 NOT NULL,
  "taxable" boolean DEFAULT false NOT NULL,
  "active" boolean DEFAULT true NOT NULL,
  "metadata" jsonb DEFAULT '{}'::jsonb NOT NULL,
  "created_by" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."hs_committee_assignments" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "network_id" uuid NOT NULL,
  "term_id" uuid NOT NULL,
  "person_entity_id" uuid NOT NULL,
  "role_key" character varying(40) NOT NULL,
  "role_label" character varying(120),
  "starts_on" date NOT NULL,
  "ends_on" date,
  "notes" text,
  "created_by" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."hs_committee_terms" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "network_id" uuid NOT NULL,
  "label" character varying(180) NOT NULL,
  "starts_on" date NOT NULL,
  "ends_on" date,
  "status" character varying(20) DEFAULT 'active'::character varying NOT NULL,
  "notes" text,
  "created_by" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."hs_complaint_comments" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "network_id" uuid NOT NULL,
  "complaint_id" uuid NOT NULL,
  "body" text NOT NULL,
  "created_by" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."hs_complaint_routes" (
  "network_id" uuid NOT NULL,
  "category_key" character varying(80) NOT NULL,
  "role_key" character varying(60) NOT NULL,
  "updated_by" uuid,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."hs_complaints" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "network_id" uuid NOT NULL,
  "unit_entity_id" uuid,
  "category" character varying(100) NOT NULL,
  "title" character varying(220) NOT NULL,
  "description" text,
  "attachments" jsonb DEFAULT '[]'::jsonb NOT NULL,
  "priority" character varying(20) DEFAULT 'normal'::character varying NOT NULL,
  "status" character varying(20) DEFAULT 'open'::character varying NOT NULL,
  "assigned_to" uuid,
  "assigned_vendor_id" uuid,
  "sla_due_at" timestamp with time zone,
  "resolution_note" text,
  "resolved_at" timestamp with time zone,
  "created_by" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."hs_compliance_items" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "network_id" uuid NOT NULL,
  "category" character varying(80) NOT NULL,
  "title" character varying(220) NOT NULL,
  "due_on" date,
  "status" character varying(20) DEFAULT 'open'::character varying NOT NULL,
  "owner_label" character varying(160),
  "document_url" text,
  "visibility" character varying(20) DEFAULT 'members'::character varying NOT NULL,
  "notes" text,
  "created_by" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."hs_domestic_staff" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "network_id" uuid NOT NULL,
  "name" character varying(180) NOT NULL,
  "staff_type" character varying(24) DEFAULT 'other'::character varying NOT NULL,
  "phone" character varying(40),
  "identity_last4" character varying(8),
  "verification_status" character varying(20) DEFAULT 'pending'::character varying NOT NULL,
  "active" boolean DEFAULT true NOT NULL,
  "created_by" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."hs_emergency_contacts" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "network_id" uuid NOT NULL,
  "category" character varying(60) NOT NULL,
  "label" character varying(180) NOT NULL,
  "phone" character varying(60) NOT NULL,
  "notes" character varying(240),
  "priority" integer DEFAULT 100 NOT NULL,
  "active" boolean DEFAULT true NOT NULL,
  "created_by" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."hs_expenses" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "network_id" uuid NOT NULL,
  "fund_id" uuid,
  "vendor_id" uuid,
  "category" character varying(100) NOT NULL,
  "description" character varying(260) NOT NULL,
  "amount" numeric(16,2) NOT NULL,
  "incurred_on" date DEFAULT CURRENT_DATE NOT NULL,
  "payment_reference" character varying(180),
  "visibility" character varying(20) DEFAULT 'members'::character varying NOT NULL,
  "created_by" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."hs_funds" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "network_id" uuid NOT NULL,
  "code" character varying(60) NOT NULL,
  "label" character varying(180) NOT NULL,
  "opening_balance" numeric(16,2) DEFAULT 0 NOT NULL,
  "current_balance" numeric(16,2) DEFAULT 0 NOT NULL,
  "visibility" character varying(20) DEFAULT 'members'::character varying NOT NULL,
  "active" boolean DEFAULT true NOT NULL,
  "created_by" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."hs_governance_action_items" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "network_id" uuid NOT NULL,
  "meeting_id" uuid,
  "agenda_item_id" uuid,
  "title" character varying(220) NOT NULL,
  "owner_user_id" uuid,
  "owner_label" character varying(160),
  "due_on" date,
  "status" character varying(20) DEFAULT 'open'::character varying NOT NULL,
  "completion_note" text,
  "created_by" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  "completed_at" timestamp with time zone
);

CREATE TABLE IF NOT EXISTS "public"."hs_governance_documents" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "network_id" uuid NOT NULL,
  "meeting_id" uuid,
  "resolution_id" uuid,
  "document_type" character varying(40) DEFAULT 'minutes'::character varying NOT NULL,
  "title" character varying(220) NOT NULL,
  "version_label" character varying(80),
  "document_url" text,
  "visibility" character varying(20) DEFAULT 'members'::character varying NOT NULL,
  "created_by" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."hs_governance_meetings" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "network_id" uuid NOT NULL,
  "meeting_type" character varying(24) DEFAULT 'committee'::character varying NOT NULL,
  "title" character varying(220) NOT NULL,
  "scheduled_at" timestamp with time zone NOT NULL,
  "location" character varying(220),
  "status" character varying(20) DEFAULT 'scheduled'::character varying NOT NULL,
  "quorum_required" integer,
  "attendee_count" integer,
  "minutes_text" text,
  "minutes_published_at" timestamp with time zone,
  "created_by" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."hs_import_batches" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "network_id" uuid NOT NULL,
  "file_name" text,
  "column_mapping" jsonb DEFAULT '{}'::jsonb NOT NULL,
  "row_count" integer DEFAULT 0 NOT NULL,
  "inserted_count" integer DEFAULT 0 NOT NULL,
  "updated_count" integer DEFAULT 0 NOT NULL,
  "skipped_count" integer DEFAULT 0 NOT NULL,
  "status" character varying(20) DEFAULT 'preview'::character varying NOT NULL,
  "created_by" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "committed_at" timestamp with time zone
);

CREATE TABLE IF NOT EXISTS "public"."hs_meeting_agenda_items" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "network_id" uuid NOT NULL,
  "meeting_id" uuid NOT NULL,
  "item_order" integer DEFAULT 1 NOT NULL,
  "title" character varying(220) NOT NULL,
  "description" text,
  "outcome_text" text,
  "created_by" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."hs_move_requests" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "network_id" uuid NOT NULL,
  "unit_entity_id" uuid NOT NULL,
  "move_type" character varying(16) NOT NULL,
  "scheduled_on" date NOT NULL,
  "contact_name" character varying(180),
  "notes" text,
  "status" character varying(20) DEFAULT 'requested'::character varying NOT NULL,
  "review_note" text,
  "created_by" uuid,
  "reviewed_by" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."hs_notice_reads" (
  "network_id" uuid NOT NULL,
  "notice_id" uuid NOT NULL,
  "user_id" uuid NOT NULL,
  "read_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."hs_notices" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "network_id" uuid NOT NULL,
  "title" character varying(220) NOT NULL,
  "body" text,
  "notice_type" character varying(20) DEFAULT 'general'::character varying NOT NULL,
  "audience" jsonb DEFAULT '{}'::jsonb NOT NULL,
  "pinned" boolean DEFAULT false NOT NULL,
  "expires_at" timestamp with time zone,
  "attachments" jsonb DEFAULT '[]'::jsonb NOT NULL,
  "created_by" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."hs_parking_allocations" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "network_id" uuid NOT NULL,
  "parking_slot_id" uuid NOT NULL,
  "vehicle_id" uuid,
  "unit_entity_id" uuid NOT NULL,
  "starts_on" date DEFAULT CURRENT_DATE NOT NULL,
  "ends_on" date,
  "allocation_type" character varying(20) DEFAULT 'assigned'::character varying NOT NULL,
  "notes" text,
  "created_by" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."hs_parking_slots" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "network_id" uuid NOT NULL,
  "slot_code" character varying(80) NOT NULL,
  "zone" character varying(120),
  "slot_type" character varying(30) DEFAULT 'car'::character varying NOT NULL,
  "status" character varying(20) DEFAULT 'available'::character varying NOT NULL,
  "metadata" jsonb DEFAULT '{}'::jsonb NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."hs_payments" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "network_id" uuid NOT NULL,
  "bill_id" uuid NOT NULL,
  "unit_entity_id" uuid NOT NULL,
  "amount" numeric(14,2) NOT NULL,
  "paid_on" date DEFAULT CURRENT_DATE NOT NULL,
  "payment_mode" character varying(30) DEFAULT 'manual'::character varying NOT NULL,
  "payment_reference" character varying(180),
  "receipt_number" character varying(120),
  "notes" text,
  "status" character varying(20) DEFAULT 'recorded'::character varying NOT NULL,
  "created_by" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "reversed_at" timestamp with time zone
);

CREATE TABLE IF NOT EXISTS "public"."hs_pilot_checkpoints" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "network_id" uuid NOT NULL,
  "pilot_run_id" uuid NOT NULL,
  "checkpoint_on" date DEFAULT CURRENT_DATE NOT NULL,
  "admin_hours_saved" numeric(8,2),
  "offline_operations_remaining" integer,
  "willingness_to_pay" character varying(20) DEFAULT 'unknown'::character varying NOT NULL,
  "renewal_intent" character varying(20) DEFAULT 'unknown'::character varying NOT NULL,
  "repeatable_onboarding_confirmed" boolean DEFAULT false NOT NULL,
  "founder_specific_code_required" boolean DEFAULT false NOT NULL,
  "committee_note" text,
  "created_by" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."hs_pilot_pricing_experiments" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "network_id" uuid NOT NULL,
  "pilot_run_id" uuid,
  "pricing_model" character varying(30) NOT NULL,
  "amount" numeric(14,2),
  "currency" character varying(8) DEFAULT 'INR'::character varying NOT NULL,
  "response" character varying(20) DEFAULT 'untested'::character varying NOT NULL,
  "notes" text,
  "tested_on" date DEFAULT CURRENT_DATE NOT NULL,
  "created_by" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."hs_pilot_runs" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "network_id" uuid NOT NULL,
  "phase" character varying(8) DEFAULT 'B'::character varying NOT NULL,
  "status" character varying(20) DEFAULT 'planning'::character varying NOT NULL,
  "cohort_label" character varying(180),
  "target_units" integer DEFAULT 20 NOT NULL,
  "started_on" date,
  "ended_on" date,
  "notes" text,
  "created_by" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."hs_pilot_usage_events" (
  "id" bigint GENERATED BY DEFAULT AS IDENTITY NOT NULL,
  "network_id" uuid NOT NULL,
  "user_id" uuid,
  "unit_entity_id" uuid,
  "event_key" character varying(40) NOT NULL,
  "metadata" jsonb DEFAULT '{}'::jsonb NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."hs_renovation_requests" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "network_id" uuid NOT NULL,
  "unit_entity_id" uuid NOT NULL,
  "title" character varying(220) NOT NULL,
  "description" text,
  "contractor_name" character varying(180),
  "starts_on" date,
  "ends_on" date,
  "status" character varying(20) DEFAULT 'requested'::character varying NOT NULL,
  "noc_reference" character varying(120),
  "conditions" text,
  "created_by" uuid,
  "reviewed_by" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."hs_resident_invitations" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "network_id" uuid NOT NULL,
  "person_entity_id" uuid NOT NULL,
  "unit_entity_id" uuid,
  "email" text NOT NULL,
  "token" uuid DEFAULT gen_random_uuid() NOT NULL,
  "status" character varying(20) DEFAULT 'pending'::character varying NOT NULL,
  "expires_at" timestamp with time zone DEFAULT (now() + '14 days'::interval) NOT NULL,
  "created_by" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "claimed_at" timestamp with time zone
);

CREATE TABLE IF NOT EXISTS "public"."hs_resolution_votes" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "network_id" uuid NOT NULL,
  "resolution_id" uuid NOT NULL,
  "voter_user_id" uuid NOT NULL,
  "choice" character varying(12) NOT NULL,
  "cast_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."hs_resolutions" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "network_id" uuid NOT NULL,
  "meeting_id" uuid,
  "resolution_number" character varying(80),
  "title" character varying(240) NOT NULL,
  "body" text NOT NULL,
  "vote_mode" character varying(20) DEFAULT 'approval'::character varying NOT NULL,
  "status" character varying(20) DEFAULT 'draft'::character varying NOT NULL,
  "opens_at" timestamp with time zone,
  "closes_at" timestamp with time zone,
  "quorum_percent" numeric(5,2) DEFAULT 0 NOT NULL,
  "result_note" text,
  "created_by" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  "closed_at" timestamp with time zone
);

CREATE TABLE IF NOT EXISTS "public"."hs_security_operator_grants" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "network_id" uuid NOT NULL,
  "user_id" uuid NOT NULL,
  "scope" character varying(30) DEFAULT 'security'::character varying NOT NULL,
  "active" boolean DEFAULT true NOT NULL,
  "created_by" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."hs_staff_unit_permissions" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "network_id" uuid NOT NULL,
  "staff_id" uuid NOT NULL,
  "unit_entity_id" uuid NOT NULL,
  "starts_on" date DEFAULT CURRENT_DATE NOT NULL,
  "ends_on" date,
  "status" character varying(20) DEFAULT 'active'::character varying NOT NULL,
  "created_by" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."hs_unit_bills" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "network_id" uuid NOT NULL,
  "billing_cycle_id" uuid NOT NULL,
  "unit_entity_id" uuid NOT NULL,
  "subtotal" numeric(14,2) DEFAULT 0 NOT NULL,
  "penalty_amount" numeric(14,2) DEFAULT 0 NOT NULL,
  "adjustment_amount" numeric(14,2) DEFAULT 0 NOT NULL,
  "total_amount" numeric(14,2) DEFAULT 0 NOT NULL,
  "paid_amount" numeric(14,2) DEFAULT 0 NOT NULL,
  "balance_amount" numeric(14,2) DEFAULT 0 NOT NULL,
  "status" character varying(20) DEFAULT 'unpaid'::character varying NOT NULL,
  "issued_at" timestamp with time zone,
  "due_on" date NOT NULL,
  "created_by" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."hs_unit_occupancy_history" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "network_id" uuid NOT NULL,
  "unit_entity_id" uuid NOT NULL,
  "subject_entity_id" uuid NOT NULL,
  "occupancy_role" character varying(30) NOT NULL,
  "starts_on" date DEFAULT CURRENT_DATE NOT NULL,
  "ends_on" date,
  "is_primary" boolean DEFAULT false NOT NULL,
  "notes" text,
  "created_by" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."hs_vehicles" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "network_id" uuid NOT NULL,
  "unit_entity_id" uuid NOT NULL,
  "owner_entity_id" uuid,
  "registration_no" character varying(32) NOT NULL,
  "vehicle_type" character varying(24) DEFAULT 'car'::character varying NOT NULL,
  "make_model" character varying(160),
  "color" character varying(80),
  "is_ev" boolean DEFAULT false NOT NULL,
  "status" character varying(20) DEFAULT 'active'::character varying NOT NULL,
  "created_by" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."hs_vendor_contracts" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "network_id" uuid NOT NULL,
  "vendor_id" uuid NOT NULL,
  "title" character varying(220) NOT NULL,
  "starts_on" date,
  "ends_on" date,
  "sla" text,
  "amount" numeric(14,2),
  "status" character varying(20) DEFAULT 'active'::character varying NOT NULL,
  "documents" jsonb DEFAULT '[]'::jsonb NOT NULL,
  "created_by" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."hs_vendors" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "network_id" uuid NOT NULL,
  "name" character varying(220) NOT NULL,
  "category" character varying(100) NOT NULL,
  "contact_name" character varying(160),
  "phone" character varying(60),
  "email" character varying(320),
  "status" character varying(20) DEFAULT 'active'::character varying NOT NULL,
  "metadata" jsonb DEFAULT '{}'::jsonb NOT NULL,
  "created_by" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."hs_visitors" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "network_id" uuid NOT NULL,
  "unit_entity_id" uuid NOT NULL,
  "visitor_name" character varying(180) NOT NULL,
  "phone" character varying(40),
  "visit_type" character varying(24) DEFAULT 'guest'::character varying NOT NULL,
  "purpose" character varying(220),
  "vehicle_number" character varying(40),
  "expected_at" timestamp with time zone,
  "entered_at" timestamp with time zone,
  "exited_at" timestamp with time zone,
  "status" character varying(20) DEFAULT 'expected'::character varying NOT NULL,
  "created_by" uuid,
  "checked_by" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
