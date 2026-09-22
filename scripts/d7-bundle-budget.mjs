const ANSI=/\x1B\[[0-?]*[ -/]*[@-~]/g;

function toBytes(value,unit){
 const amount=Number(value);
 if(!Number.isFinite(amount))throw new Error("D7 could not parse bundle size.");
 if(unit==="MB")return amount*1_000_000;
 if(unit==="kB")return amount*1_000;
 return amount;
}

export function parseRootFirstLoad(buildOutput){
 const clean=String(buildOutput||"").replace(ANSI,"");
 const rootLine=clean.split(/\r?\n/).map(line=>line.trim()).find(line=>/^[┌├└]\s+[○ƒ]\s+\/\s+/.test(line));
 if(!rootLine)throw new Error("D7 could not find the root route in Next build output.");
 const match=rootLine.match(/\/\s+([0-9.]+)\s+(B|kB|MB)\s+([0-9.]+)\s+(kB|MB)\s*$/);
 if(!match)throw new Error(`D7 could not parse root route sizes: ${rootLine}`);
 return {routeLine:rootLine,routeBytes:toBytes(match[1],match[2]),firstLoadBytes:toBytes(match[3],match[4])};
}

export function assertRootFirstLoadBudget(buildOutput,budgetBytes=Number(process.env.TRUSTWEAVE_ROOT_FIRST_LOAD_BUDGET_BYTES||700_000)){
 const result=parseRootFirstLoad(buildOutput);
 console.log(`D7 root First Load JS: ${result.firstLoadBytes} bytes (budget ${budgetBytes}).`);
 if(result.firstLoadBytes>budgetBytes)throw new Error(`D7 root First Load JS budget exceeded: ${result.firstLoadBytes} > ${budgetBytes} bytes.`);
 return result;
}
