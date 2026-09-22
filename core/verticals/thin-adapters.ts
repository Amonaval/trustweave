import type {ScopedAuthorizationDecision,ScopedAuthorizationRequest,ScopedAuthorizationRequirement} from "../authorization/policy";
import type {WorkflowItem} from "../workflow/contracts";

export type ThinVerticalPolicyAdapter=Readonly<{
 capability:string;
 decide:(request:ScopedAuthorizationRequest,requirement:ScopedAuthorizationRequirement)=>ScopedAuthorizationDecision;
}>;

export type ThinVerticalWorkflowAdapter<TDomain=unknown>=Readonly<{
 project:(networkId:string,input:TDomain)=>WorkflowItem;
}>;

export type ThinVerticalQueryAdapter<TInput,TResult>=Readonly<{
 query:(input:TInput)=>Promise<TResult>;
}>;

export type ThinVerticalCommandAdapter<TCommand,TResult>=Readonly<{
 command:(input:TCommand)=>Promise<TResult>;
}>;

export type ThinVerticalDataAdapters=Readonly<{
 queries?:Readonly<Record<string,ThinVerticalQueryAdapter<any,any>>>;
 commands?:Readonly<Record<string,ThinVerticalCommandAdapter<any,any>>>;
}>;

/**
 * D10 adapter contract: vertical adapters translate domain semantics into shared platform contracts.
 * They do not bypass server/RPC/RLS authorization and they must not become alternate persistence owners.
 */
export type ThinVerticalAdapters<TDomain=unknown>=Readonly<{
 policy?:ThinVerticalPolicyAdapter;
 workflow?:ThinVerticalWorkflowAdapter<TDomain>;
 data?:ThinVerticalDataAdapters;
}>;
