import {test} from "node:test";
import {strict as assert} from "node:assert";
import {networkSurfaceHref,parseNetworkRoute} from "../../lib/network-routes";
import {buildNotificationDeepLink,readNotificationDeepLink,resolveNotificationDeepLink} from "../../lib/notification-routing";
import {getVerticalAppComposition} from "../../app-shell/vertical-runtime";
import {VERTICAL_REGISTRY} from "../../app-shell/vertical-registry";
import {authorizeNetworkSurface} from "../../lib/network-route-access";
import type {NetworkMembership} from "../../core/network/contracts";

const id="12345678-1234-4123-8123-123456789abc";

test("a renamed network retains its opaque canonical URL and all representative vertical surfaces are registered",()=>{
 const examples=[{kind:"family",surface:"tree"},{kind:"family-association",surface:"community"},{kind:"housing-society",surface:"complaints"}] as const;
 for(const {kind,surface} of examples){
  const composition=getVerticalAppComposition(kind);
  assert.ok([...composition.primaryNavigation,...composition.mobileMoreNavigation].some(row=>row.viewId===surface));
  assert.deepEqual(parseNetworkRoute(networkSurfaceHref(id,surface)),{networkId:id,surface});
 }
 assert.deepEqual(parseNetworkRoute(`/network/${id}`),{networkId:id,surface:"home"});
});

test("every registered navigation destination fits the canonical addressable route contract",()=>{
 for(const kind of Object.keys(VERTICAL_REGISTRY) as Array<keyof typeof VERTICAL_REGISTRY>){
  const composition=getVerticalAppComposition(kind);
  for(const surface of [...composition.primaryNavigation,...composition.mobileMoreNavigation]){
   assert.deepEqual(parseNetworkRoute(networkSurfaceHref(id,surface.viewId)),{networkId:id,surface:surface.viewId});
  }
 }
});

test("route grammar rejects extra segments, untrusted identifiers and private data in the path",()=>{
 assert.equal(parseNetworkRoute("/"),null);
 assert.equal(parseNetworkRoute(`/network/${id}/tree/member`),"invalid");
 assert.equal(parseNetworkRoute(`/network/user@example.com/tree`),"invalid");
 assert.equal(parseNetworkRoute(`/network/${id}/%2Fsecrets`),"invalid");
 assert.throws(()=>networkSurfaceHref("someone@example.com","directory"));
});

test("notifications use canonical surfaces, tolerate legacy links and never follow an off-site href",()=>{
 assert.equal(buildNotificationDeepLink({networkId:id,surface:"complaints",itemId:"email@example.com"}),`/network/${id}/complaints`);
 assert.deepEqual(readNotificationDeepLink(`?twNetwork=${id}&twSurface=community`),{networkId:id,surface:"community",itemId:undefined});
 const notification={network_id:id,href:"https://untrusted.example/private",type:"complaint_created",entity_type:"complaint",entity_id:null,metadata:{}};
 assert.equal(resolveNotificationDeepLink(notification),`/network/${id}/complaints`);
 assert.equal(resolveNotificationDeepLink({...notification,href:`/?twNetwork=${id}`}),`/network/${id}/complaints`);
});

test("direct entry fails closed for another tenant, inactive members, unknown surfaces and private administration",()=>{
 const member={network:{id,name:"Renamed chapter",slug:"old-name",verticalKind:"family-association"},role:"member",status:"active",isActive:false,resources:{storageLimitBytes:0,photoUploadEnabled:false,photoMaxBytes:0}} satisfies NetworkMembership;
 assert.equal(authorizeNetworkSurface({networkId:id,surface:"community"},[member]),member);
 assert.throws(()=>authorizeNetworkSurface({networkId:"aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa",surface:"community"},[member]));
 assert.throws(()=>authorizeNetworkSurface({networkId:id,surface:"admin"},[member]));
 assert.throws(()=>authorizeNetworkSurface({networkId:id,surface:"school-register"},[member]));
 assert.throws(()=>authorizeNetworkSurface({networkId:id,surface:"community"},[{...member,status:"suspended"} as NetworkMembership]));
});
