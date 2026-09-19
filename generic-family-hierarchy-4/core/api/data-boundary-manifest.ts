export type DataBoundaryContract=Readonly<{
 capability:"domain.housing-society"|"domain.family-association";
 owner:string;
 clientAdapter:string;
 serverService:string;
 queryRoute:string;
 commandRoute:string;
 rpcs:readonly string[];
 persistenceNamespace:readonly string[];
 idempotency:"required";
 privacy:"authenticated-network-context-rpc-rls";
}>;

export const DATA_BOUNDARY_MANIFEST={
 "housing.operations":{
  capability:"domain.housing-society",owner:"housing-society",
  clientAdapter:"verticals/housing-society/runtime/operations-remote.ts",
  serverService:"server/housing/operations-service.ts",
  queryRoute:"app/api/v1/housing/operations/route.ts",
  commandRoute:"app/api/v1/housing/operations/command/route.ts",
  rpcs:["hs4_get_operations_snapshot","hs4_get_complaint_routes","hs2_create_notice","hs4_create_complaint","hs4_update_complaint","hs4_add_complaint_comment","hs2_upsert_vendor","hs2_create_vendor_contract","hs2_upsert_amenity","hs2_create_amenity_booking","hs2_review_amenity_booking","hs4_set_complaint_route"],
  persistenceNamespace:["public.hs_notices","public.hs_vendors","public.hs_vendor_contracts","public.hs_complaints","public.hs_complaint_comments","public.hs_amenities","public.hs_amenity_bookings","public.hs_complaint_routes"],
  idempotency:"required",privacy:"authenticated-network-context-rpc-rls",
 },
 "family-association.admin":{
  capability:"domain.family-association",owner:"family-association",
  clientAdapter:"verticals/family-association/runtime/admin-remote.ts",
  serverService:"server/family-association/admin-service.ts",
  queryRoute:"app/api/v1/family-association/admin/route.ts",
  commandRoute:"app/api/v1/family-association/admin/command/route.ts",
  rpcs:["get_fca_admin_snapshot","update_fca_settings","upsert_fca_membership_year","set_fca_family_membership","assign_fca_role","add_fca_finance_entry"],
  persistenceNamespace:["public.family_association_settings","public.family_association_membership_years","public.family_association_family_memberships","public.family_association_role_catalog","public.family_association_role_history","public.family_association_finance_ledger"],
  idempotency:"required",privacy:"authenticated-network-context-rpc-rls",
 },
} as const satisfies Record<string,DataBoundaryContract>;

export const LEGACY_DATA_BOUNDARY_HOTSPOTS=[
 {source:"lib/remote.ts",scope:"legacy family and cross-cutting facade"},
 {source:"capabilities/template-product/remote.ts",scope:"remaining generic productized capabilities"},
 {source:"verticals/housing-society/runtime/governance-remote.ts",scope:"Housing governance"},
 {source:"verticals/housing-society/runtime/finance-remote.ts",scope:"Housing finance"},
 {source:"verticals/housing-society/runtime/security-remote.ts",scope:"Housing security"},
 {source:"verticals/housing-society/runtime/pilot-remote.ts",scope:"Housing pilot/read-state"},
] as const;
