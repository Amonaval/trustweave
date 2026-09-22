import fs from "node:fs";

if(!fs.existsSync("governance/documentation-policy.json")){
  console.error("Documentation policy not found; refusing legacy archival mutation.");
  process.exit(1);
}
console.log("M3-B3 Knowledge OS is active. Legacy automatic root-document mutation is retired; use the documentation policy/gate and explicit reviewed moves instead.");
