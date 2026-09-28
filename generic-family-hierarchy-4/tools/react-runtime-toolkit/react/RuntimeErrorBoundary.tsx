'use client';
import React,{type ReactNode,type ErrorInfo} from 'react';
import {runtimeStore} from '../core/store';
type Props={children:ReactNode;fallback?:ReactNode;onError?:(error:Error,componentStack:string)=>void};type State={error:Error|null};
export class RuntimeErrorBoundary extends React.Component<Props,State>{state:State={error:null};static getDerivedStateFromError(error:Error){return{error}}componentDidCatch(error:Error,info:ErrorInfo){runtimeStore.recordError({kind:'react-boundary',message:error.message,stack:error.stack,componentStack:info.componentStack||undefined,at:Date.now()});this.props.onError?.(error,info.componentStack||'')}render(){if(this.state.error)return this.props.fallback??<div role="alert" style={{padding:16,fontFamily:'system-ui'}}><b>UI error captured</b><div>{this.state.error.message}</div></div>;return this.props.children}}
