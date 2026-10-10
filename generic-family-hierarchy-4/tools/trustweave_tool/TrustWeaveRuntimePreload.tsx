import {getReactRuntimePreloadScript} from '../react-runtime-toolkit/react/preload';

const KEY='trustweave-runtime-observability';

export default function TrustWeaveRuntimePreload(){
  if(process.env.NODE_ENV!=='development')return null;
  const base=getReactRuntimePreloadScript();
  const script=`(function(){try{var p=new URLSearchParams(location.search),v=p.get('twdebug');if(v==='1')sessionStorage.setItem('${KEY}','1');if(v==='0')sessionStorage.setItem('${KEY}','0');if(sessionStorage.getItem('${KEY}')==='0')return;${base}}catch(e){}})();`;
  return <script suppressHydrationWarning dangerouslySetInnerHTML={{__html:script}}/>;
}
