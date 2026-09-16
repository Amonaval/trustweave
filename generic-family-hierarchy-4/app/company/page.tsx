import fs from "node:fs";
import path from "node:path";
import styles from "./company.module.css";

type Cockpit = {
  generatedAt: string;
  health: { status: string; score: number; summary: string };
  autonomy: {
    score: number;
    founderInterventions: number;
    manualErrorRelays: number;
    humanRole: string;
  };
  activeMission: string;
  missions: Array<{ id: string; title: string; state: string }>;
  executiveDebate: Array<{ role: string; position: string }>;
  decisions: Array<{
    id: string;
    class: string;
    decision: string;
    basis: string;
  }>;
  risks: {
    blocking: number;
    watch: Array<{ id: string; title: string; persona: string }>;
  };
  evidence: {
    memoryRecords: number;
    approvedReviews: number;
    latestSources: string[];
  };
  interventions: string[];
  blockers: string[];
  nextMoves: string[];
};
const load = () =>
  JSON.parse(
    fs.readFileSync(
      path.join(process.cwd(), "company-state/cockpit.json"),
      "utf8",
    ),
  ) as Cockpit;
export default function CompanyCockpit() {
  const data = load();
  return (
    <main className={styles.shell} data-testid="founder-cockpit">
      <header className={styles.hero}>
        <div>
          <p className={styles.eyebrow}>TrustWeave autonomous company</p>
          <h1>Founder cockpit</h1>
          <p>{data.health.summary}</p>
        </div>
        <span className={styles.status}>{data.health.status}</span>
      </header>
      <section className={styles.metrics} aria-label="Company health metrics">
        <article>
          <span>Company health</span>
          <strong>{data.health.score}%</strong>
        </article>
        <article>
          <span>Autonomy score</span>
          <strong>{data.autonomy.score}%</strong>
        </article>
        <article>
          <span>Founder interventions</span>
          <strong>{data.autonomy.founderInterventions}</strong>
        </article>
        <article>
          <span>Blocking risks</span>
          <strong>{data.risks.blocking}</strong>
        </article>
      </section>
      <div className={styles.grid}>
        <section className={styles.panel}>
          <p className={styles.kicker}>Now</p>
          <h2>Active mission</h2>
          <strong className={styles.mission}>{data.activeMission}</strong>
          <p>{data.autonomy.humanRole}</p>
          <h3>Next moves</h3>
          <ol>
            {data.nextMoves.map((x) => (
              <li key={x}>{x}</li>
            ))}
          </ol>
        </section>
        <section className={styles.panel}>
          <p className={styles.kicker}>Leadership</p>
          <h2>Executive debate</h2>
          {data.executiveDebate.map((x) => (
            <div className={styles.debate} key={x.role}>
              <strong>{x.role}</strong>
              <p>{x.position}</p>
            </div>
          ))}
        </section>
        <section className={styles.panel}>
          <p className={styles.kicker}>Control</p>
          <h2>Decisions & risks</h2>
          {data.decisions.map((x) => (
            <article key={x.id}>
              <span className={styles.tag}>{x.class}</span>
              <strong>{x.decision}</strong>
              <p>{x.basis}</p>
            </article>
          ))}
          <p className={styles.clear}>
            {data.blockers.length
              ? data.blockers.join(" ")
              : "No blocking issue requires Founder action."}
          </p>
        </section>
        <section className={styles.panel}>
          <p className={styles.kicker}>Proof</p>
          <h2>Evidence</h2>
          <dl>
            <div>
              <dt>Memory records</dt>
              <dd>{data.evidence.memoryRecords}</dd>
            </div>
            <div>
              <dt>Approved reviews</dt>
              <dd>{data.evidence.approvedReviews}</dd>
            </div>
            <div>
              <dt>Manual error relays</dt>
              <dd>{data.autonomy.manualErrorRelays}</dd>
            </div>
          </dl>
          <details>
            <summary>Inspect source trail</summary>
            <ul>
              {data.evidence.latestSources.map((x) => (
                <li key={x}>{x}</li>
              ))}
            </ul>
          </details>
        </section>
      </div>
      <section className={styles.panel}>
        <p className={styles.kicker}>Portfolio</p>
        <h2>Mission state</h2>
        <div className={styles.missionList}>
          {data.missions.map((x) => (
            <article key={x.id}>
              <strong>{x.id}</strong>
              <span>{x.title}</span>
              <em>{x.state}</em>
            </article>
          ))}
        </div>
      </section>
      <footer>
        Snapshot {new Date(data.generatedAt).toISOString()} · No production
        control is exposed here.
      </footer>
    </main>
  );
}
