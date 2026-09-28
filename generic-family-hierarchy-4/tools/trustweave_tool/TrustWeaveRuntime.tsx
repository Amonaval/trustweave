'use client';
import {useEffect,useMemo,useState,type ReactNode} from 'react';
import RuntimeBridge from '../react-runtime-toolkit/react/RuntimeBridge';
import {registerTrustWeavePlugins} from './registerTrustWeavePlugins';
const KEY='trustweave-runtime-observability';
export default function TrustWeaveRuntime({children}:{children:ReactNode}){const[enabled,setEnabled]=useState(false);useEffect(()=>{const p=new URLSearchParams(location.search),v=p.get('twdebug');if(v==='1')sessionStorage.setItem(KEY,'1');if(v==='0')sessionStorage.removeItem(KEY);registerTrustWeavePlugins();setEnabled(sessionStorage.getItem(KEY)==='1')},[]);const config=useMemo(()=>({brand:'TrustWeave Runtime Intelligence',trackTimers:true,captureStacks:true,highlightRenders:false}),[]);return <RuntimeBridge enabled={enabled} config={config}>{children}</RuntimeBridge>}