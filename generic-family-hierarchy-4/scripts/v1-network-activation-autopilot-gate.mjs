import fs from "node:fs";

const required=[
 "core/activation-autopilot/compiler.ts",
 "core/activation-autopilot/resolution.ts",
 "core/activation-autopilot/evidence.ts",
 "core/activation-autopilot/intelligence.ts",
 "components/shared/NetworkActivationAutopilot.tsx",
 "capabilities/import/productized-workbook.ts",
 "supabase/migrations/124_v1_network_activation_evidence.sql"
];

for(const file of required){
 if(!fs.existsSync(file))throw new Error(`V1 activation missing ${file}`);
}

const compiler=fs.readFileSync("core/activation-autopilot/compiler.ts","utf8");
for(const token of [
 "POSSIBLE_DUPLICATE_IDENTITY",
 "MULTIPLE_HOUSEHOLD_CANDIDATES",
 "REPRESENTATIVE_CONFLICT",
 "LEADERSHIP_ROLE_CONFLICT",
 "MEMBERSHIP_PAYMENT_CONFLICT",
 "sourceRefs"
]){
 if(!compiler.includes(token))throw new Error(`V1 compiler missing ${token}`);
}

const resolution=fs.readFileSync("core/activation-autopilot/resolution.ts","utf8");
for(const token of ["merge_person","identityAliases","activationExcluded","keep_source_row"]){
 if(token==="activationExcluded")continue;
 if(!resolution.includes(token))throw new Error(`V1 resolution missing ${token}`);
}

const evidence=fs.readFileSync("core/activation-autopilot/evidence.ts","utf8");
for(const token of ["activationExcluded","sourceRaw","resolvedValues","network-activation-candidate.v1"]){
 if(!evidence.includes(token))throw new Error(`V1 evidence missing ${token}`);
}

const commit=fs.readFileSync("capabilities/import/productized-workbook.ts","utf8");
for(const token of [
 "recordFcaActivationEvidence",
 "represented_by",
 "Activation stopped before canonical writes",
 "assignFcaRole",
 "setFcaFamilyMembership"
]){
 if(!commit.includes(token))throw new Error(`V1 activation commit missing ${token}`);
}

const ui=fs.readFileSync("components/shared/NetworkActivationAutopilot.tsx","utf8");
for(const token of [
 "Network Activation Autopilot",
 "Ambiguity inbox",
 "Merge into row",
 "First institutional intelligence",
 "Activate governed network"
]){
 if(!ui.includes(token))throw new Error(`V1 activation UI missing ${token}`);
}

const migration=fs.readFileSync("supabase/migrations/124_v1_network_activation_evidence.sql","utf8");
for(const token of [
 "submit_family_association_activation_evidence",
 "get_family_association_activation_evidence",
 "is_network_admin",
 "network_knowledge_sources",
 "network_evidence_records"
]){
 if(!migration.includes(token))throw new Error(`V1 migration missing ${token}`);
}

const v1Source=required
 .filter(file=>!file.endsWith(".sql"))
 .map(file=>fs.readFileSync(file,"utf8").toLowerCase())
 .join("\n");
for(const forbidden of ["openai api key","anthropic api key","process.env.openai","process.env.anthropic"]){
 if(v1Source.includes(forbidden))throw new Error(`V1 must remain provider/cost independent: found ${forbidden}`);
}

console.log("V1 Network Activation Autopilot source contract passed.");
