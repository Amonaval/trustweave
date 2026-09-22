import type {RequestContext} from "../shared/request-context";
import {boundedPageSize} from "../../core/scale/contracts";

export async function fetchNetworkEntityPage(ctx:RequestContext,input:{afterLabel?:string|null;afterId?:string|null;limit?:number}){
 const {data,error}=await ctx.supabase.rpc("get_network_affiliated_entities_page",{p_after_label:input.afterLabel||null,p_after_id:input.afterId||null,p_limit:boundedPageSize(input.limit)});
 if(error)throw error;return data||[];
}

export async function fetchNetworkRelationshipPage(ctx:RequestContext,input:{afterId?:string|null;limit?:number}){
 const {data,error}=await ctx.supabase.rpc("get_productized_network_relationships_page",{p_after_id:input.afterId||null,p_limit:boundedPageSize(input.limit,100)});
 if(error)throw error;return data||[];
}

export async function fetchNetworkMembershipPage(ctx:RequestContext,input:{afterJoinedAt?:string|null;afterUserId?:string|null;limit?:number}){
 const {data,error}=await ctx.supabase.rpc("get_productized_network_memberships_page",{p_after_joined_at:input.afterJoinedAt||null,p_after_user_id:input.afterUserId||null,p_limit:boundedPageSize(input.limit,100)});
 if(error)throw error;return data||[];
}
