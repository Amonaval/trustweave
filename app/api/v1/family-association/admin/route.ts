import {executeQuery} from "../../../../../server/shared/query-runtime";
import {fetchFamilyAssociationAdmin} from "../../../../../server/family-association/admin-service";
export const runtime="nodejs";
export async function GET(request:Request){
 return executeQuery({request,queryName:"familyAssociationAdmin.snapshot",rateLimit:{limit:60},execute:fetchFamilyAssociationAdmin});
}
