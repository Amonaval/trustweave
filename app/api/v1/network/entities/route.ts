import {executeQuery} from "../../../../../server/shared/query-runtime";
import {fetchNetworkEntityPage} from "../../../../../server/network/scale-service";
import {boundedPageSize} from "../../../../../core/scale/contracts";
export const runtime="nodejs";
export async function GET(request:Request){
 const q=new URL(request.url).searchParams;
 const input={afterLabel:q.get("afterLabel"),afterId:q.get("afterId"),limit:boundedPageSize(q.get("limit"))};
 return executeQuery({request,queryName:"network.entities.page",rateLimit:{limit:90,networkLimit:900},execute:ctx=>fetchNetworkEntityPage(ctx,input)});
}
