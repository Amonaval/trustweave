import {executeQuery} from "../../../../../server/shared/query-runtime";
import {fetchHousingOperations} from "../../../../../server/housing/operations-service";
export const runtime="nodejs";
export async function GET(request:Request){
 const view=new URL(request.url).searchParams.get("view")==="complaint-routes"?"complaint-routes":"snapshot";
 return executeQuery({request,queryName:`housingOperations.${view}`,rateLimit:{limit:90},execute:ctx=>fetchHousingOperations(ctx,view)});
}
