import styles from './artifacts.module.css';

const artifacts=[
  {title:'Public Product Profile',description:'The concise public explanation of TrustWeave, its users, value and trust model.',href:'/artifacts/TRUSTWEAVE-PUBLIC-PRODUCT-PROFILE.html',tag:'Start here'},
  {title:'Product Evolution Journey',description:'How TrustWeave evolved from a family network into a governed private Network OS.',href:'/artifacts/TRUSTWEAVE-PRODUCT-EVOLUTION-JOURNEY.html',tag:'Journey'},
  {title:'Product Feature Handbook',description:'A product-management view of released capabilities, verticals and operating surfaces.',href:'/artifacts/TRUSTWEAVE-PRODUCT-FEATURE-HANDBOOK.html',tag:'Capabilities'},
  {title:'Generic Network OS Vision',description:'The long-term product thesis for trusted, isolated networks and governed bridges.',href:'/artifacts/GENERIC-NETWORK-OS-VISION.html',tag:'Vision'},
  {title:'Founder Autonomous Working Model',description:'What changed in Mission 3 and how the Founder, autonomous company and engineering system now work together.',href:'/artifacts/TRUSTWEAVE-FOUNDER-AUTONOMOUS-WORKING-MODEL.html',tag:'Operating model'}
];

export const metadata={title:'TrustWeave Product Artifacts',description:'Product journey, capability and autonomous-company artifacts for TrustWeave.'};

export default function ProductArtifacts(){return <main className={styles.shell} data-testid="product-artifact-library"><header className={styles.hero}><p className={styles.eyebrow}>TrustWeave product knowledge</p><h1>Explore the product journey</h1><p>Open the current narrative, capability and operating-model artifacts used to explain what TrustWeave is, how it evolved and how the company now builds it.</p><nav><a href="/">Back to product</a><a href="/company">Founder cockpit</a></nav></header><section className={styles.grid} aria-label="Product artifacts">{artifacts.map(item=><article key={item.href}><span>{item.tag}</span><h2>{item.title}</h2><p>{item.description}</p><a href={item.href} target="_blank" rel="noreferrer">Open artifact <b aria-hidden="true">↗</b></a></article>)}</section><footer>These deployed pages are synchronized from the repository’s canonical product artifacts during release validation.</footer></main>}
