import type {RuntimeConfig} from './types';
export const DEFAULT_CONFIG: Required<RuntimeConfig> = {
  brand:'React Runtime Toolkit', slowNetworkMs:1000, slowCommitMs:50, largeResourceKB:500,
  commitBurstCount:5, commitBurstWindowMs:700, highlightRenders:false, captureConsole:true,
  captureStacks:true, trackTimers:false, maxEntries:500,
};
export function normalizeConfig(config:RuntimeConfig={}):Required<RuntimeConfig>{ return {...DEFAULT_CONFIG,...config}; }
