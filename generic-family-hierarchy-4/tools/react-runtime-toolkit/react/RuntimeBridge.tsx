'use client';
import {useEffect,useState,type ReactNode} from 'react';
import {runtimeStore} from '../core/store';
import type {RuntimeConfig} from '../core/types';
import {startBrowserObservers} from '../browser/observers';
import {startReactFiberObserver} from './fiber';
import RuntimePanel from './RuntimePanel';
export default function RuntimeBridge({children,enabled,config={},showPanel=true}:{children:ReactNode;enabled:boolean;config?:RuntimeConfig;showPanel?:boolean}){const[active,setActive]=useState(false);useEffect(()=>{runtimeStore.configure(config);setActive(enabled)},[enabled,config]);useEffect(()=>{if(!active)return;const a=startBrowserObservers(),b=startReactFiberObserver();return()=>{a();b()}},[active]);return <>{children}{active&&showPanel?<RuntimePanel/>:null}</>}
