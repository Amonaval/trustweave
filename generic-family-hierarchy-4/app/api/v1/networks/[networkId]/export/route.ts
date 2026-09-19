import {buildNetworkExport} from "../../../../../../server/network/export-service";
import {executeQuery} from "../../../../../../server/shared/query-runtime";
export const runtime="nodejs";
export async function GET(request:Request,{params}:{params:{networkId:string}}){
 return executeQuery({request,queryName:"network.export",rateLimit:{limit:3,networkLimit:20,windowMs:60_000},execute:ctx=>buildNetworkExport(ctx,params.networkId),networkId:()=>params.networkId});
}
