"use client";

import {useMemo,useState,type ReactNode} from "react";
import {
  ArrowRight,
  BookOpen,
  Building2,
  CalendarDays,
  CheckCircle2,
  ChevronRight,
  CircleDollarSign,
  HeartHandshake,
  History,
  Home,
  Layers3,
  LockKeyhole,
  MessageSquareText,
  PlayCircle,
  ShieldCheck,
  Sparkles,
  UsersRound,
  Vote,
  Wrench,
} from "lucide-react";
import type {NetworkVerticalKind} from "../core/verticals/contracts";
import {useLanguage} from "../lib/i18n";
import LanguageSwitcher from "./LanguageSwitcher";

type ExploreKey="overview"|"housing"|"community"|"member"|"guide";
type LocalCopy={
  privateOs:string;hero:string;lead:string;exploreHousing:string;exploreCommunity:string;tryPlayground:string;productGuide:string;signIn:string;
  proof:string;housingTitle:string;housingLead:string;communityTitle:string;communityLead:string;memberTitle:string;memberLead:string;
  choose:string;how:string;simple:string;detailed:string;deep:string;startHere:string;privacy:string;gettingStarted:string;evolution:string;
};

const copy:Record<"en"|"hi"|"mr",LocalCopy>={
  en:{privateOs:"Private multi-network operating system",hero:"Your communities, families and residential life — connected without becoming public.",lead:"TrustWeave replaces fragmented Excel sheets, WhatsApp threads and disconnected tools with private networks that keep people, operations, money, decisions and community history in context.",exploreHousing:"Explore Housing Society",exploreCommunity:"Explore Family Community",tryPlayground:"Try Playground",productGuide:"Product Guide",signIn:"Sign in",proof:"Understand the product before you create anything.",housingTitle:"I manage a Housing Society",housingLead:"Residents, complaints, notices, maintenance, visitors, amenities, committee work, elections, finances and community communication — together in one private society system.",communityTitle:"I lead a Community / Association",communityLead:"Families, annual membership, renewals, events, funds, committees, elections, professional connections, posts, memories and history — together instead of fragmented Excel + WhatsApp workflows.",memberTitle:"I am a member / resident",memberLead:"See what matters to you today without learning admin terminology: your home or family, dues, notices, events, requests, community posts, voting and trusted people.",choose:"Choose my situation",how:"See how the pieces connect",simple:"Simple",detailed:"Detailed",deep:"Deep",startHere:"Start Here",privacy:"Privacy & Trust",gettingStarted:"Getting Started",evolution:"Product Evolution"},
  hi:{privateOs:"निजी मल्टी-नेटवर्क ऑपरेटिंग सिस्टम",hero:"आपका समुदाय, परिवार और आवासीय जीवन — जुड़ा हुआ, पर सार्वजनिक नहीं।",lead:"TrustWeave बिखरी Excel शीट, WhatsApp थ्रेड और अलग-अलग टूल की जगह निजी नेटवर्क देता है जहाँ लोग, संचालन, पैसे, निर्णय और इतिहास संदर्भ सहित जुड़े रहते हैं।",exploreHousing:"हाउसिंग सोसायटी देखें",exploreCommunity:"फैमिली कम्युनिटी देखें",tryPlayground:"Playground आज़माएँ",productGuide:"प्रोडक्ट गाइड",signIn:"साइन इन",proof:"कुछ बनाए बिना पहले प्रोडक्ट समझें।",housingTitle:"मैं हाउसिंग सोसायटी चलाता/चलाती हूँ",housingLead:"निवासी, शिकायतें, सूचनाएँ, मेंटेनेंस, विज़िटर, सुविधाएँ, समिति, चुनाव, वित्त और कम्युनिटी संवाद — एक निजी सोसायटी सिस्टम में।",communityTitle:"मैं कम्युनिटी / एसोसिएशन का नेतृत्व करता/करती हूँ",communityLead:"परिवार, वार्षिक सदस्यता, नवीनीकरण, कार्यक्रम, फंड, समिति, चुनाव, पेशेवर संपर्क, पोस्ट, यादें और इतिहास — Excel + WhatsApp के बजाय एक साथ।",memberTitle:"मैं सदस्य / निवासी हूँ",memberLead:"एडमिन शब्दावली सीखे बिना रोज़ की जरूरी बातें देखें: मेरा घर या परिवार, बकाया, नोटिस, कार्यक्रम, अनुरोध, पोस्ट, मतदान और भरोसेमंद लोग।",choose:"अपनी स्थिति चुनें",how:"देखें चीज़ें कैसे जुड़ती हैं",simple:"सरल",detailed:"विस्तृत",deep:"गहरा",startHere:"यहाँ से शुरू करें",privacy:"गोपनीयता और भरोसा",gettingStarted:"शुरुआत",evolution:"प्रोडक्ट विकास"},
  mr:{privateOs:"खाजगी मल्टी-नेटवर्क ऑपरेटिंग सिस्टम",hero:"तुमचा समुदाय, कुटुंब आणि निवासी जीवन — जोडलेले, पण सार्वजनिक नाही.",lead:"TrustWeave विखुरलेल्या Excel शीट्स, WhatsApp थ्रेड्स आणि वेगवेगळ्या साधनांऐवजी खाजगी नेटवर्क देते, जिथे लोक, कामकाज, पैसे, निर्णय आणि इतिहास संदर्भासह जोडलेले राहतात.",exploreHousing:"हाउसिंग सोसायटी पाहा",exploreCommunity:"फॅमिली कम्युनिटी पाहा",tryPlayground:"Playground वापरून पाहा",productGuide:"प्रॉडक्ट गाइड",signIn:"साइन इन",proof:"काहीही तयार करण्यापूर्वी प्रॉडक्ट समजून घ्या.",housingTitle:"मी हाउसिंग सोसायटी व्यवस्थापित करतो/करते",housingLead:"रहिवासी, तक्रारी, सूचना, मेंटेनन्स, पाहुणे, सुविधा, समिती, निवडणुका, वित्त आणि कम्युनिटी संवाद — एका खाजगी सोसायटी सिस्टममध्ये.",communityTitle:"मी कम्युनिटी / असोसिएशनचे नेतृत्व करतो/करते",communityLead:"कुटुंबे, वार्षिक सदस्यत्व, नूतनीकरण, कार्यक्रम, निधी, समित्या, निवडणुका, व्यावसायिक संपर्क, पोस्ट, आठवणी आणि इतिहास — Excel + WhatsApp ऐवजी एकत्र.",memberTitle:"मी सदस्य / रहिवासी आहे",memberLead:"अॅडमिन शब्द शिकण्याची गरज नाही: माझे घर किंवा कुटुंब, देयके, सूचना, कार्यक्रम, विनंत्या, पोस्ट, मतदान आणि विश्वासार्ह लोक एका ठिकाणी.",choose:"तुमची परिस्थिती निवडा",how:"सगळे कसे जोडते ते पाहा",simple:"सोपे",detailed:"सविस्तर",deep:"सखोल",startHere:"इथून सुरू करा",privacy:"गोपनीयता आणि विश्वास",gettingStarted:"सुरुवात",evolution:"प्रॉडक्ट प्रवास"},
};

const housingFlow:[ReactNode,string,string][]= [
  [<Home key="h"/>,"Resident / Unit","A home is the operating anchor, while every resident keeps an independent identity."],
  [<MessageSquareText key="n"/>,"Notice → Complaint + photo","Communicate first, then capture service issues with evidence and exact deep links."],
  [<Wrench key="w"/>,"Assign → Resolve","Route work to committee responsibility or vendors, track SLA and keep the resident informed."],
  [<CircleDollarSign key="m"/>,"Maintenance → Payment","Bills, adjustments, receipts, funds, budget and expenses stay tied to the same society."],
  [<UsersRound key="c"/>,"Committee → Resolution","Meetings, agenda, minutes and actions create institutional memory instead of chat archaeology."],
  [<Vote key="v"/>,"Election / Poll","Run governed participation with eligibility and result controls."],
  [<ShieldCheck key="s"/>,"Visitor / Security","Visitors, staff access, move requests, assets and compliance remain society-scoped."],
];
const communityFlow:[ReactNode,string,string][]= [
  [<UsersRound key="f"/>,"Family → People","A paid household can contain representative, spouse and children without flattening people into one record."],
  [<CalendarDays key="y"/>,"Annual membership → Renewal","Keep each year, payment state and grace period as history rather than overwriting the past."],
  [<Sparkles key="e"/>,"Event → RSVP","Community life, announcements and participation are connected to the same trusted membership."],
  [<CircleDollarSign key="fd"/>,"Fund / Collection","Track membership and community collections with receipts and visibility rules."],
  [<Vote key="el"/>,"Committee → Election / Poll","Roles and decisions are governed instead of living only in WhatsApp messages."],
  [<MessageSquareText key="p"/>,"Post / Mention","Broadcasts and conversations create real notifications and exact return paths."],
  [<History key="m"/>,"Memories / History","Preserve events, service and shared community history beyond the current committee."],
];

function Journey({rows}:{rows:[ReactNode,string,string][]}){return <div className="public-journey-flow">{rows.map(([icon,title,body],index)=><article key={title}><span className="public-journey-number">{index+1}</span><span className="public-journey-icon">{icon}</span><div><b>{title}</b><p>{body}</p></div>{index<rows.length-1&&<ChevronRight className="public-journey-arrow" size={17}/>}</article>)}</div>}

export default function PublicDiscoveryPortal({onSignIn,onExplore}:{onSignIn:()=>void;onExplore:(kind:NetworkVerticalKind,familyVariant?:"public"|"setup")=>Promise<boolean>|boolean}){
  const {language}=useLanguage();
  const lang=(language==="hi"||language==="mr"?language:"en") as "en"|"hi"|"mr";
  const c=copy[lang];
  const [section,setSection]=useState<ExploreKey>("overview");
  const [guideLevel,setGuideLevel]=useState<"simple"|"detailed"|"deep">("simple");
  const guideCards=useMemo(()=>guideLevel==="simple"?[
    [c.startHere,"TrustWeave is a private operating system for the networks you already belong to: family, community and residential life. Each network keeps its own membership and privacy boundary."],
    ["What TrustWeave can do","Keep people, structure, communication, money, participation, media and history connected so users do not have to reconstruct context across spreadsheets and chats."],
    ["How people use it","Start from a familiar daily outcome — a complaint, renewal, event, payment, visitor, vote or family update — and move deeper only when needed."],
    [c.privacy,"Networks are private by default. Membership, role permissions, private media and tenant isolation control who can see or change data."],
    [c.gettingStarted,"Explore a read-only Playground first. Sign in only when you want to create, join or operate a real persisted network."],
  ]:guideLevel==="detailed"?[
    ["Housing Society","Property structure, residents, notices, complaints, amenities, maintenance, governance, elections, security, assets, compliance and community life use one network context."],
    ["Family Community / Association","Families, people, annual membership, renewals, committee service, funds, events, posts, elections and memories share one community context."],
    ["Family","People, kinship, memories, places, timeline and guided contribution remain family-specific instead of being forced into an organization model."],
    ["Operational trust","Official records are role-governed; personal/member surfaces expose only the context appropriate to the current user and active network."],
    ["Launch model","Launch Control decides which verticals can be discovered, created or opened as Playground samples. It does not erase existing memberships or capabilities."],
  ]:[
    ["Capability Catalog","Shared engines provide identity, participation, notifications, media, funds, voting and activity primitives while each vertical keeps its own domain contracts and UX."],
    ["Product Journey","TrustWeave evolved from a family network into a private Network OS with specialized verticals and governed cross-network capability rather than one giant public graph."],
    ["UX Handbook","Progressive disclosure keeps daily tasks simple while admin, governance and technical depth remain available to the roles that need them."],
    ["Technical / CTO view","The product uses network-scoped contracts, tenant-aware RPCs, row-level security, private media authorization and explicit launch/runtime certification gates."],
    [c.evolution,"Release evidence, runtime gates and living product documents are maintained as part of product closure rather than separate from engineering."],
  ],[guideLevel,c]);

  return <main className="public-discovery" data-testid="qa-public-discovery">
    <header className="public-discovery-topbar">
      <button className="public-brand" onClick={()=>setSection("overview")}><span><Layers3 size={22}/></span><div><b>TrustWeave</b><small>{c.privateOs}</small></div></button>
      <nav aria-label="Product exploration">
        <button className={section==="housing"?"active":""} onClick={()=>setSection("housing")}>{c.exploreHousing}</button>
        <button className={section==="community"?"active":""} onClick={()=>setSection("community")}>{c.exploreCommunity}</button>
        <button className={section==="guide"?"active":""} onClick={()=>setSection("guide")}>{c.productGuide}</button>
      </nav>
      <div className="public-top-actions"><LanguageSwitcher compact/><button className="btn" data-testid="qa-open-auth" onClick={onSignIn}>{c.signIn}</button></div>
    </header>

    {section==="overview"&&<>
      <section className="public-hero">
        <div className="public-hero-copy"><span className="warm-kicker"><LockKeyhole size={13}/>{c.privateOs}</span><h1>{c.hero}</h1><p>{c.lead}</p><div className="public-hero-actions">
          <button className="btn primary" data-testid="qa-explore-housing" onClick={()=>setSection("housing")}><Building2 size={17}/>{c.exploreHousing}</button>
          <button className="btn" data-testid="qa-explore-community" onClick={()=>setSection("community")}><UsersRound size={17}/>{c.exploreCommunity}</button>
          <button className="btn" data-testid="qa-public-playground" onClick={()=>void onExplore("family","public")}><PlayCircle size={17}/>{c.tryPlayground}</button>
          <button className="btn ghost" data-testid="qa-product-guide" onClick={()=>setSection("guide")}><BookOpen size={17}/>{c.productGuide}</button>
        </div><div className="public-trust-note"><ShieldCheck size={17}/><span>{c.proof}</span></div></div>
        <aside className="public-hero-visual" aria-label="TrustWeave connected private networks"><div className="public-os-core"><Layers3 size={29}/><b>TrustWeave</b><small>Private Network OS</small></div><div className="public-orbit housing"><Building2/><span>Housing Society</span></div><div className="public-orbit community"><UsersRound/><span>Family Community</span></div><div className="public-orbit family"><HeartHandshake/><span>Family</span></div></aside>
      </section>
      <section className="public-role-section"><div className="public-section-head"><span>{c.choose}</span><h2>Start with the outcome you care about</h2><p>TrustWeave reveals depth progressively. You do not need to understand the whole platform to get value from one network.</p></div><div className="public-role-grid">
        <button onClick={()=>setSection("housing")}><span className="public-role-icon"><Building2/></span><div><h3>{c.housingTitle}</h3><p>{c.housingLead}</p><b>{c.how}<ArrowRight size={15}/></b></div></button>
        <button onClick={()=>setSection("community")}><span className="public-role-icon"><UsersRound/></span><div><h3>{c.communityTitle}</h3><p>{c.communityLead}</p><b>{c.how}<ArrowRight size={15}/></b></div></button>
        <button onClick={()=>setSection("member")}><span className="public-role-icon"><Home/></span><div><h3>{c.memberTitle}</h3><p>{c.memberLead}</p><b>{c.how}<ArrowRight size={15}/></b></div></button>
      </div></section>
    </>}

    {section==="housing"&&<section className="public-detail-page" data-testid="qa-public-housing"><button className="public-back" onClick={()=>setSection("overview")}>← TrustWeave</button><div className="public-detail-hero"><span className="public-role-icon"><Building2/></span><div><span className="warm-kicker">Housing Society</span><h1>{c.housingTitle}</h1><p>{c.housingLead}</p><div className="public-detail-actions"><button className="btn primary" onClick={()=>void onExplore("housing-society")}><PlayCircle size={16}/>Explore realistic society Playground</button><button className="btn" onClick={()=>setSection("guide")}><BookOpen size={16}/>{c.productGuide}</button><button className="btn ghost" onClick={onSignIn}>{c.signIn}<ArrowRight size={15}/></button></div></div></div><div className="public-section-head compact"><span>{c.how}</span><h2>One operating story instead of eight disconnected tools</h2></div><Journey rows={housingFlow}/><div className="public-safe-note"><ShieldCheck/><div><b>Private by network</b><p>Resident identity, finance, complaints, visitors and private media stay scoped to the active society and role permissions. A Playground is read-only; a real society uses persisted domain APIs.</p></div></div></section>}

    {section==="community"&&<section className="public-detail-page" data-testid="qa-public-community"><button className="public-back" onClick={()=>setSection("overview")}>← TrustWeave</button><div className="public-detail-hero"><span className="public-role-icon"><UsersRound/></span><div><span className="warm-kicker">Family Community / Association</span><h1>{c.communityTitle}</h1><p>{c.communityLead}</p><div className="public-detail-actions"><button className="btn primary" onClick={()=>void onExplore("family-association")}><PlayCircle size={16}/>Explore realistic community Playground</button><button className="btn" onClick={()=>setSection("guide")}><BookOpen size={16}/>{c.productGuide}</button><button className="btn ghost" onClick={onSignIn}>{c.signIn}<ArrowRight size={15}/></button></div></div></div><div className="public-section-head compact"><span>{c.how}</span><h2>Family membership, community life and institutional history stay connected</h2></div><Journey rows={communityFlow}/><div className="public-safe-note"><ShieldCheck/><div><b>Family-centric, not a flat member list</b><p>The family can be the annual membership unit while representative, spouse, children and committee members remain distinct people with their own profile and privacy context.</p></div></div></section>}

    {section==="member"&&<section className="public-detail-page" data-testid="qa-public-member"><button className="public-back" onClick={()=>setSection("overview")}>← TrustWeave</button><div className="public-detail-hero"><span className="public-role-icon"><Home/></span><div><span className="warm-kicker">Everyday member experience</span><h1>{c.memberTitle}</h1><p>{c.memberLead}</p><div className="public-detail-actions"><button className="btn primary" onClick={()=>void onExplore("family","public")}><PlayCircle size={16}/>{c.tryPlayground}</button><button className="btn" onClick={()=>setSection("guide")}><BookOpen size={16}/>{c.productGuide}</button></div></div></div><div className="public-member-grid">{[["Today","See current notices, upcoming events, dues, visitors, requests and activity instead of searching old chats."],["My context","Open your home, family, profile and the people immediately relevant to you."],["Participate","RSVP, comment, vote, pay, report an issue or contribute without being exposed to admin complexity."],["Return exactly","Notifications take you back to the exact complaint, post, fund or election rather than a generic dashboard."],["Stay private","Your access follows the network you are in, your role and the visibility of the underlying record."]].map(([title,body])=><article key={title}><CheckCircle2/><div><b>{title}</b><p>{body}</p></div></article>)}</div></section>}

    {section==="guide"&&<section className="public-guide-page" data-testid="qa-public-product-guide"><button className="public-back" onClick={()=>setSection("overview")}>← TrustWeave</button><div className="public-guide-head"><div><span className="warm-kicker"><BookOpen size={13}/>{c.productGuide}</span><h1>Understand TrustWeave at the depth you need</h1><p>This is a curated in-product knowledge center. It explains released product behavior without exposing founder-private strategy, confidential architecture, anti-abuse internals or unreleased IP material.</p></div><div className="public-guide-levels"><button className={guideLevel==="simple"?"active":""} onClick={()=>setGuideLevel("simple")}>{c.simple}<small>Members & residents</small></button><button className={guideLevel==="detailed"?"active":""} onClick={()=>setGuideLevel("detailed")}>{c.detailed}<small>Chairmen & Presidents</small></button><button className={guideLevel==="deep"?"active":""} onClick={()=>setGuideLevel("deep")}>{c.deep}<small>Product & technical</small></button></div></div><div className="public-guide-grid">{guideCards.map(([title,body],index)=><article key={title}><span>{index+1}</span><div><h3>{title}</h3><p>{body}</p></div></article>)}</div><section className="public-guide-next"><div><span className="warm-kicker">Next</span><h2>Explore before you commit</h2><p>Open a read-only Playground for a realistic vertical, then sign in when you are ready to create or join a persisted network.</p></div><div><button className="btn" onClick={()=>void onExplore("housing-society")}><Building2 size={16}/>Housing Society</button><button className="btn" onClick={()=>void onExplore("family-association")}><UsersRound size={16}/>Family Community</button><button className="btn primary" onClick={onSignIn}>{c.signIn}<ArrowRight size={16}/></button></div></section></section>}
  </main>;
}
