'use client';

import {useEffect,useState,type ReactNode} from 'react';
import type {RuntimeSource} from 'runtime-intelligence/react';
import {
  RuntimeIntelligenceProfiler,
  RuntimeIntelligenceProvider,
} from 'runtime-intelligence/react';

const KEY='trustweave-runtime-observability';
const DEV_ONLY=process.env.NODE_ENV==='development';
const ROOT_SOURCE=Object.freeze({file:'app/layout.tsx',functionName:'RootLayout'});

function resolveEnabled(){
  if(!DEV_ONLY||typeof window==='undefined')return false;
  const params=new URLSearchParams(window.location.search);
  const value=params.get('twdebug');
  if(value==='1')sessionStorage.setItem(KEY,'1');
  if(value==='0')sessionStorage.setItem(KEY,'0');
  return sessionStorage.getItem(KEY)!=='0';
}

export function TrustWeaveRuntimeProfiler({children,name,source}:{children:ReactNode;name:string;source?:RuntimeSource}){
  if(!DEV_ONLY)return <>{children}</>;
  return <RuntimeIntelligenceProfiler name={name} source={source}>{children}</RuntimeIntelligenceProfiler>;
}

export default function TrustWeaveRuntime({children}:{children:ReactNode}){
  const[enabled,setEnabled]=useState(false);
  useEffect(()=>setEnabled(resolveEnabled()),[]);

  if(!DEV_ONLY)return <>{children}</>;

  return <RuntimeIntelligenceProvider
    name="TrustWeave.Root"
    source={ROOT_SOURCE}
    enabled={enabled}
    profilingEnabled
  >
    {children}
  </RuntimeIntelligenceProvider>;
}
