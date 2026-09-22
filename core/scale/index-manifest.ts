export type ScaleIndexRequirement=Readonly<{name:string;table:string;purpose:string}>;
export const SCALE_INDEX_REQUIREMENTS=[
 {name:"idx_network_entities_network_label_id",table:"public.network_entities",purpose:"tenant directory keyset pagination"},
 {name:"idx_network_activities_network_sort_id",table:"public.network_activities",purpose:"tenant activity keyset pagination"},
 {name:"idx_network_relationships_network_id",table:"public.network_entity_relationships",purpose:"bounded tenant relationship paging"},
 {name:"idx_network_memberships_network_status_joined",table:"public.network_memberships",purpose:"tenant membership administration"},
 {name:"idx_network_activity_comments_network_activity_created",table:"public.network_activity_comments",purpose:"bounded activity comment reads"},
 {name:"idx_fca_finance_network_created",table:"public.family_association_finance_ledger",purpose:"tenant finance history"},
 {name:"idx_fca_role_history_network_start",table:"public.family_association_role_history",purpose:"tenant designation history"},
] as const satisfies readonly ScaleIndexRequirement[];
