'use client';
import {Profiler,type ReactNode} from 'react';
import {runtimeStore} from '../core/store';
export default function RuntimeProfiler({name,children,enabled=true}:{name:string;children:ReactNode;enabled?:boolean}){if(!enabled)return <>{children}</>;return <Profiler id={name} onRender={(id:string,phase:'mount'|'update'|'nested-update',actualDuration:number)=>runtimeStore.recordCommit({id:`profiler-${Date.now()}-${Math.random().toString(36).slice(2,6)}`,rendererId:-1,at:Date.now(),interactionId:runtimeStore.recentInteraction()?.id,componentCount:1,changedCount:1,components:[{name:id,depth:0,reason:phase==='mount'?'mount':'unknown',props:[],hooks:[],actualDurationMs:actualDuration,referentialChurn:[]} ]})}>{children}</Profiler>}
