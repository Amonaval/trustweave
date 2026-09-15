import type {NetworkVerticalKind} from "../verticals/contracts";

export type LaunchSeedKind="housing-society"|"family-association";
export type LaunchDataset={version:string;synthetic:true;network_settings?:Record<string,unknown>[];[key:string]:unknown};
export type LaunchSeedLineageRow={sectionKey:string;rowRef:string;payloadHash:string;remoteId?:string|null;status:string;lastMessage?:string|null;updatedAt?:string};
export type LaunchSeedContext={networkId?:string;networkName?:string;verticalKind?:NetworkVerticalKind;datasetVersion?:string;authorized:boolean;allowRealNetwork?:boolean;isPlatformOwner?:boolean;isAdmin?:boolean};
export type LaunchSeedIssue={severity:"error"|"warning";section?:string;rowRef?:string;message:string};
export type LaunchSeedSectionSummary={section:string;rows:number;create:number;update:number;skip:number;errors:number};
export type LaunchSeedDryRun={datasetVersion:string;kind:LaunchSeedKind;synthetic:boolean;valid:boolean;issues:LaunchSeedIssue[];sections:LaunchSeedSectionSummary[];totals:{rows:number;create:number;update:number;skip:number;errors:number}};
export type LaunchSeedProgress={phase:string;section?:string;current:number;total:number;message:string};
export type LaunchSeedCommitResult={datasetVersion:string;kind:LaunchSeedKind;created:number;updated:number;skipped:number;errors:number;warnings:string[];completedSections:string[];message:string};
export type LaunchSeedOptions={onProgress?:(progress:LaunchSeedProgress)=>void};
