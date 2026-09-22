import {executeQuery} from "../../../../../server/shared/query-runtime";
import {fetchNetworkRelationshipPage} from "../../../../../server/network/scale-service";
import {boundedPageSize} from "../../../../../core/scale/contracts";
export const runtime="nodejs";
export async function GET(request:Request){
 const q=new URL(request.url).searchParams;
 const input={afterId:q.get("afterId"),limit:boundedPageSize(q.get("limit"),100)};
 return executeQuery({request,queryName:"network.relationships.page",rateLimit:{limit:90,networkLimit:900},execute:ctx=>fetchNetworkRelationshipPage(ctx,input)});
}
