import {runtimeConfigStatus} from "../shared/runtime-config";
import {backgroundRuntimeHealth} from "../jobs/dispatcher";

export function operationalHealthSnapshot(){
 const config=runtimeConfigStatus();
 return {
  liveness:"healthy" as const,
  readiness:config.ok?("ready" as const):("degraded" as const),
  dependencies:{
   supabaseConfig:{status:config.ok?"configured" as const:"missing" as const,missingCount:config.missing.length},
   backgroundJobs:backgroundRuntimeHealth(),
  },
  telemetry:{mode:"structured-json-process-local",durableAggregation:false},
 };
}
