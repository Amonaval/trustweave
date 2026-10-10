'use client';

import {useEffect,useState,type ReactNode} from 'react';
import {
  RuntimeIntelligenceProfiler,
  RuntimeIntelligenceProvider,
  useRuntimeIntelligence,
} from 'runtime-intelligence/react';
import {mountRuntimeIntelligencePanel} from 'runtime-intelligence/panel';

const KEY='trustweave-runtime-observability';
const DEV_ONLY=process.env.NODE_ENV==='development';

function resolveEnabled(){
  if(!DEV_ONLY||typeof window==='undefined')return false;
  const params=new URLSearchParams(window.location.search);
  const value=params.get('twdebug');
  if(value==='1')sessionStorage.setItem(KEY,'1');
  if(value==='0')sessionStorage.setItem(KEY,'0');
  return sessionStorage.getItem(KEY)!=='0';
}

function TrustWeaveRuntimePanel(){
  const context=useRuntimeIntelligence();
  useEffect(()=>{
    if(!DEV_ONLY||!context?.enabled)return;
    const mounted=mountRuntimeIntelligencePanel({
      store:context.store,
      adapter:context.adapter,
      title:'TrustWeave Runtime Intelligence',
      collapsed:true,
    });
    return()=>mounted.destroy();
  },[context]);
  return null;
}

export function TrustWeaveRuntimeProfiler({children,name}:{children:ReactNode;name:string}){
  if(!DEV_ONLY)return <>{children}</>;
  return <RuntimeIntelligenceProfiler name={name}>{children}</RuntimeIntelligenceProfiler>;
}

export default function TrustWeaveRuntime({children}:{children:ReactNode}){
  const[enabled,setEnabled]=useState(false);
  useEffect(()=>setEnabled(resolveEnabled()),[]);

  if(!DEV_ONLY)return <>{children}</>;

  return <RuntimeIntelligenceProvider
    name="TrustWeave.Root"
    enabled={enabled}
    profilingEnabled
  >
    <TrustWeaveRuntimePanel/>
    {children}
  </RuntimeIntelligenceProvider>;
}
