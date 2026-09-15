import type {LaunchDataset,LaunchSeedCommitResult,LaunchSeedContext,LaunchSeedDryRun,LaunchSeedKind,LaunchSeedOptions} from "../../core/launch-seed/contracts";
import {BUNDLED_LAUNCH_DATASETS,buildLaunchDryRun,loadBundledLaunchDataset,parseLaunchDatasetFile,validateDatasetShape} from "./dataset";
import {authorizeLaunchDemoSeed,fetchLaunchSeedContext,fetchLaunchSeedLineage} from "./remote";
import {seedHousingLaunchDataset} from "./housing";
import {seedFamilyCommunityLaunchDataset} from "./family-community";

export {BUNDLED_LAUNCH_DATASETS,loadBundledLaunchDataset,parseLaunchDatasetFile};
export type {LaunchDataset,LaunchSeedCommitResult,LaunchSeedContext,LaunchSeedDryRun,LaunchSeedKind};

export async function inspectLaunchDataset(data:LaunchDataset,kind:LaunchSeedKind):Promise<{context:LaunchSeedContext;dryRun:LaunchSeedDryRun}>{
 validateDatasetShape(data,kind);
 const context=await fetchLaunchSeedContext(data.version);
 const lineage=context.authorized?await fetchLaunchSeedLineage(data.version):[];
 return {context,dryRun:buildLaunchDryRun(data,kind,lineage)};
}

export async function authorizeAndInspectLaunchDataset(data:LaunchDataset,kind:LaunchSeedKind,networkName:string,allowRealNetwork=false){
 validateDatasetShape(data,kind);
 await authorizeLaunchDemoSeed(data.version,networkName,allowRealNetwork);
 return inspectLaunchDataset(data,kind);
}

export async function commitLaunchDataset(data:LaunchDataset,kind:LaunchSeedKind,networkId:string,options:LaunchSeedOptions={}):Promise<LaunchSeedCommitResult>{
 validateDatasetShape(data,kind);
 const context=await fetchLaunchSeedContext(data.version);
 if(!context.authorized)throw new Error("Authorize this synthetic launch dataset for the active network before committing it.");
 if(context.networkId!==networkId)throw new Error("The active network changed after launch-data authorization. Re-open the loader and authorize the intended network.");
 if(context.verticalKind!==kind)throw new Error(`Dataset ${data.version} cannot seed active vertical ${context.verticalKind||"unknown"}.`);
 const lineage=await fetchLaunchSeedLineage(data.version);
 const dryRun=buildLaunchDryRun(data,kind,lineage);
 if(!dryRun.valid)throw new Error(`Launch dataset validation failed with ${dryRun.totals.errors} reference error${dryRun.totals.errors===1?"":"s"}.`);
 return kind==="housing-society"?seedHousingLaunchDataset(data,lineage,options):seedFamilyCommunityLaunchDataset(data,lineage,networkId,options);
}
