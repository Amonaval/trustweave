import {NextResponse} from "next/server";
import {operationalHealthSnapshot} from "../../../server/observability/health";
export const runtime="nodejs";export const dynamic="force-dynamic";
export async function GET(){
 const snapshot=operationalHealthSnapshot();
 return NextResponse.json({ok:true,service:"network-os",status:snapshot.readiness,timestamp:new Date().toISOString(),...snapshot},{headers:{"cache-control":"no-store"}});
}
