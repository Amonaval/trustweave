import {test} from "node:test";
import {strict as assert} from "node:assert";
import {NETWORK_VERTICAL_KINDS,isNetworkVerticalKind} from "../../core/verticals/kinds";
import {VERTICAL_MANIFEST,getVerticalManifest} from "../../app-shell/vertical-manifest";
import {VERTICAL_REGISTRY,getVerticalDefinition} from "../../app-shell/vertical-registry";
import {getVerticalAppComposition,getRenderableVerticalRuntime} from "../../app-shell/vertical-runtime";
import {getVerticalCapabilityRuntime} from "../../app-shell/vertical-capabilities";
import {PRODUCTIZED_NETWORK_CONFIGS} from "../../templates/productized/config";

test("the type vocabulary, feature projection, route composition and capability runtime resolve the same nine verticals",()=>{
 assert.deepEqual(new Set(Object.keys(VERTICAL_MANIFEST)),new Set(NETWORK_VERTICAL_KINDS));
 assert.deepEqual(new Set(Object.keys(VERTICAL_REGISTRY)),new Set(NETWORK_VERTICAL_KINDS));
 for(const kind of NETWORK_VERTICAL_KINDS){
  const manifest=getVerticalManifest(kind);
  assert.equal(getVerticalDefinition(kind),manifest.definition);
  assert.equal(getVerticalAppComposition(kind),manifest.app);
  assert.equal(getRenderableVerticalRuntime(kind).capabilities,getVerticalCapabilityRuntime(kind));
  assert.equal(manifest.app.featureCatalogId,manifest.definition.featureCatalog.catalogId);
  if(manifest.runtimeMode==="productized-template")assert.equal(manifest.productizedConfig,PRODUCTIZED_NETWORK_CONFIGS[kind as keyof typeof PRODUCTIZED_NETWORK_CONFIGS]);
  else assert.equal(manifest.productizedConfig,null);
 }
});

test("unregistered verticals fail closed at transport, manifest and runtime boundaries",()=>{
 assert.equal(isNetworkVerticalKind("school"),false);
 for(const invalid of ["school","__proto__","constructor",""]){
  assert.throws(()=>getVerticalManifest(invalid));
  assert.throws(()=>getVerticalAppComposition(invalid as typeof NETWORK_VERTICAL_KINDS[number]));
  assert.throws(()=>getVerticalCapabilityRuntime(invalid as typeof NETWORK_VERTICAL_KINDS[number]));
 }
});
