import config from '../../qa.config.mjs';
import {VERTICALS} from './catalog.mjs';

const catalogKinds=VERTICALS.map(vertical=>vertical.kind);
const unique=(values)=>[...new Set(values)];

export const QA_VERTICAL_KINDS=unique(config.verticals);
export const QA_ROLES=unique(config.roles);

const unknownVerticals=QA_VERTICAL_KINDS.filter(kind=>!catalogKinds.includes(kind));
const unknownRoles=QA_ROLES.filter(role=>!['owner','admin','member'].includes(role));
if(!QA_VERTICAL_KINDS.length)throw new Error('qa.config.mjs must select at least one vertical.');
if(!QA_ROLES.length)throw new Error('qa.config.mjs must select at least one role.');
if(unknownVerticals.length)throw new Error(`qa.config.mjs contains unknown verticals: ${unknownVerticals.join(', ')}`);
if(unknownRoles.length)throw new Error(`qa.config.mjs contains unknown roles: ${unknownRoles.join(', ')}`);
if(QA_VERTICAL_KINDS.length!==config.verticals.length)throw new Error('qa.config.mjs contains duplicate verticals.');
if(QA_ROLES.length!==config.roles.length)throw new Error('qa.config.mjs contains duplicate roles.');

export const QA_VERTICALS=VERTICALS.filter(vertical=>QA_VERTICAL_KINDS.includes(vertical.kind));
