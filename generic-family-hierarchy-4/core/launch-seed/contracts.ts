import type {NetworkVerticalKind} from "../verticals/contracts";

export type LaunchSeedKind="housing-society"|"family-association";
export type LaunchDataset={version:string;synthetic:true;network_settings?:Record<string,unknown>[];[key:string]:unknown};
export type LaunchSeedLineageStatus="committed"|"skipped"|"warning"|"partial"|"error";
export type LaunchSeedLineageRow={sectionKey:string;rowRef:string;payloadHash:string;remoteId?:string|null;status:LaunchSeedLineageStatus;lastMessage?:string|null;updatedAt?:string};
export type LaunchSeedContext={networkId?:string;networkName?:string;verticalKind?:NetworkVerticalKind;datasetVersion?:string;authorized:boolean;allowRealNetwork?:boolean;isPlatformOwner?:boolean;isAdmin?:boolean};
export type LaunchSeedIssue={severity:"error"|"warning";section?:string;rowRef?:string;message:string};
export type LaunchSeedDiagnostic={severity:"error"|"warning";section:string;rowRef:string;operation:string;code?:string|null;message:string;details?:string|null;hint?:string|null;retryable?:boolean;occurredAt:string};
export type LaunchSeedSectionSummary={section:string;rows:number;create:number;update:number;skip:number;errors:number};
export type LaunchSeedDryRun={datasetVersion:string;kind:LaunchSeedKind;synthetic:boolean;valid:boolean;issues:LaunchSeedIssue[];sections:LaunchSeedSectionSummary[];totals:{rows:number;create:number;update:number;skip:number;errors:number}};
export type LaunchSeedProgress={phase:string;section?:string;current:number;total:number;message:string};
export type LaunchSeedCommitResult={runId?:string;datasetVersion:string;kind:LaunchSeedKind;created:number;updated:number;skipped:number;errors:number;warnings:string[];diagnostics:LaunchSeedDiagnostic[];completedSections:string[];message:string;report?:unknown};
export type LaunchSeedOptions={runId?:string;paceMs?:number;onProgress?:(progress:LaunchSeedProgress)=>void;onDiagnostic?:(diagnostic:LaunchSeedDiagnostic)=>void};
