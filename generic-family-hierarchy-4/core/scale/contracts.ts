export const SCALE_BUDGETS=Object.freeze({
 pageDefault:50,
 pageMax:200,
 graphMaxDepth:4,
 graphMaxVisitedNodes:5_000,
 graphMaxExaminedEdges:20_000,
 bootstrapRows:500,
 syncExportStorageObjects:10_000,
 syncExportDirectories:2_000,
 queryActorPerMinute:60,
 queryNetworkPerMinute:1_200,
 commandActorPerMinute:30,
 commandNetworkPerMinute:600,
 backgroundChunkItems:250,
 inlineBackgroundItems:500,
});

export function boundedPageSize(value:unknown,defaultSize=SCALE_BUDGETS.pageDefault){
 const parsed=typeof value==="number"?value:Number(value);
 if(!Number.isFinite(parsed))return defaultSize;
 return Math.max(1,Math.min(SCALE_BUDGETS.pageMax,Math.floor(parsed)));
}

export type ScaleSignals={
 tenantTableRows:number;
 tenantQueryP95Ms:number;
 dbPoolUtilization:number;
 noisyTenantWorkloadShare:number;
 appInstanceCount:number;
 regionalIsolationRequired?:boolean;
};

export function evaluateScaleEscalation(s:ScaleSignals){
 return {
  partitioningReview:s.tenantTableRows>=25_000_000&&s.tenantQueryP95Ms>=250,
  deploymentStampReview:Boolean(s.regionalIsolationRequired)||(s.dbPoolUtilization>=0.70&&s.noisyTenantWorkloadShare>=0.15),
  sharedRateLimiterRequired:s.appInstanceCount>1,
 };
}

export const SCALE_ESCALATION_NOTES=Object.freeze({
 partitioningReview:"Review partitioning only after a tenant-scoped relation is >=25M rows and representative indexed tenant queries remain >=250ms p95 after query/index tuning.",
 deploymentStampReview:"Review deployment stamps for explicit regional isolation or sustained >=70% pool utilization combined with a tenant contributing >=15% of workload and causing contention.",
 sharedRateLimiterRequired:"The in-process burst guard is defense-in-depth only. More than one application instance requires a shared/distributed limiter for enforceable global quotas.",
});
