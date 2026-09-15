import fs from 'node:fs';
import path from 'node:path';

const sleep=(ms:number)=>new Promise(resolve=>setTimeout(resolve,ms));

export default async function mission2GlobalSetup(){
  const warmupMs=Number(process.env.QA_M2_SERVER_WARMUP_MS||0);
  if(!Number.isFinite(warmupMs)||warmupMs<=0)return;
  const marker=path.resolve('qa-results/mission2/.server-warmed');
  if(fs.existsSync(marker))return;
  const baseURL=process.env.QA_BASE_URL||'http://127.0.0.1:3000';
  const deadline=Date.now()+180_000;
  let lastError='';
  while(Date.now()<deadline){
    try{
      const response=await fetch(baseURL,{redirect:'manual'});
      if(response.status<500)break;
      lastError=`HTTP ${response.status}`;
    }catch(error){lastError=error instanceof Error?error.message:String(error)}
    await sleep(1_000);
  }
  if(Date.now()>=deadline)throw new Error(`Mission 2 server did not become reachable at ${baseURL}. Last error: ${lastError}`);
  console.log(`Mission 2 server is reachable. Waiting ${Math.round(warmupMs/1000)}s for Next.js compilation/hydration before first Playwright test...`);
  await sleep(warmupMs);
  fs.mkdirSync(path.dirname(marker),{recursive:true});
  fs.writeFileSync(marker,new Date().toISOString());
}
