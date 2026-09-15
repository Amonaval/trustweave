import {VERTICALS} from './catalog.mjs';

export const MISSION2_VERTICAL_KINDS=['housing-society','family-association'];
export const MISSION2_VERTICALS=VERTICALS.filter(v=>MISSION2_VERTICAL_KINDS.includes(v.kind));
