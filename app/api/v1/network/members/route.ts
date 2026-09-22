import {executeQuery} from "../../../../../server/shared/query-runtime";
import {fetchNetworkMembershipPage} from "../../../../../server/network/scale-service";
import {boundedPageSize} from "../../../../../core/scale/contracts";
export const runtime="nodejs";
export async function GET(request:Request){
 const q=new URL(request.url).searchParams;
 const input={afterJoinedAt:q.get("afterJoinedAt"),afterUserId:q.get("afterUserId"),limit:boundedPageSize(q.get("limit"),100)};
 return executeQuery({request,queryName:"network.members.page",rateLimit:{limit:60,networkLimit:600},execute:ctx=>fetchNetworkMembershipPage(ctx,input)});
}
