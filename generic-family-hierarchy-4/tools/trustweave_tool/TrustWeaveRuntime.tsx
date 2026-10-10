'use client';
import {useEffect,useMemo,useState,type ReactNode} from 'react';
import RuntimeBridge from '../react-runtime-toolkit/react/RuntimeBridge';
import {registerTrustWeavePlugins} from './registerTrustWeavePlugins';

const KEY='trustweave-runtime-observability';
const DEV_ONLY=process.env.NODE_ENV==='development';

function resolveEnabled(){
  if(!DEV_ONLY||typeof window==='undefined')return false;
  const p=new URLSearchParams(window.location.search),v=p.get('twdebug');
  if(v==='1')sessionStorage.setItem(KEY,'1');
  if(v==='0')sessionStorage.setItem(KEY,'0');
  const stored=sessionStorage.getItem(KEY);
  return stored!=='0';
}

export default function TrustWeaveRuntime({children}:{children:ReactNode}){
  const[enabled,setEnabled]=useState(false);
  useEffect(()=>{
    const active=resolveEnabled();
    if(active)registerTrustWeavePlugins();
    setEnabled(active);
  },[]);
  const config=useMemo(()=>({brand:'TrustWeave Runtime Intelligence',trackTimers:true,captureStacks:true,highlightRenders:false}),[]);
  if(!DEV_ONLY)return <>{children}</>;
  return <RuntimeBridge enabled={enabled} config={config}>{children}</RuntimeBridge>;
}
