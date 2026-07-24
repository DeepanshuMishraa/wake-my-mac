import type { Metadata } from "next";
import { GuideShell } from "../guide-shell";
import { siteUrl } from "../site";

const pageUrl = `${siteUrl}/keepingyouawake-alternative`;

const faqs = [
  {
    question: "Is StayRunning a KeepingYouAwake alternative?",
    answer:
      "Yes. Both prevent a Mac from sleeping. StayRunning is aimed at users who also want activity rules, closed-lid workflows, battery guardrails, and local history.",
  },
  {
    question: "Are StayRunning and KeepingYouAwake free?",
    answer:
      "StayRunning is free to download and its source is available on GitHub. KeepingYouAwake is also an open-source project with downloads available from its official site and GitHub repository.",
  },
  {
    question: "Which app is better for simple one-click use?",
    answer:
      "KeepingYouAwake focuses on a compact menu-bar workflow. StayRunning also supports one-click control, but adds a dashboard and more explicit rules and history.",
  },
];

export const metadata: Metadata = {
  title: "KeepingYouAwake Alternative for Mac",
  description:
    "Compare StayRunning and KeepingYouAwake for macOS: one-click sleep prevention, durations, battery protection, closed-lid work, rules, and history.",
  alternates: { canonical: "/keepingyouawake-alternative" },
  openGraph: {
    title: "KeepingYouAwake Alternative for Mac",
    description:
      "An honest comparison of StayRunning and KeepingYouAwake for preventing Mac sleep.",
    url: "/keepingyouawake-alternative",
    type: "article",
  },
};

export default function KeepingYouAwakeAlternative() {
  const jsonLd = {
    "@context": "https://schema.org",
    "@graph": [
      {
        "@type": "Article",
        "@id": `${pageUrl}/#article`,
        headline: "KeepingYouAwake Alternative for Mac",
        description:
          "An independent comparison of StayRunning and KeepingYouAwake.",
        url: pageUrl,
        mainEntityOfPage: pageUrl,
        datePublished: "2026-07-24",
        dateModified: "2026-07-24",
        author: {
          "@type": "Person",
          name: "Deepanshu Mishra",
          url: "https://linkedin.com/in/deepanshum",
        },
        publisher: {
          "@type": "Organization",
          name: "StayRunning",
          url: siteUrl,
        },
        image: `${siteUrl}/og-image.png`,
      },
      {
        "@type": "BreadcrumbList",
        itemListElement: [
          {
            "@type": "ListItem",
            position: 1,
            name: "StayRunning",
            item: siteUrl,
          },
          {
            "@type": "ListItem",
            position: 2,
            name: "KeepingYouAwake alternative",
            item: pageUrl,
          },
        ],
      },
      {
        "@type": "FAQPage",
        mainEntity: faqs.map(({ question, answer }) => ({
          "@type": "Question",
          name: question,
          acceptedAnswer: { "@type": "Answer", text: answer },
        })),
      },
    ],
  };

  return (
    <GuideShell>
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }}
      />

      <header className="guide-header">
        <p className="guide-kicker">macOS app comparison</p>
        <h1>KeepingYouAwake alternative for Mac</h1>
        <p className="guide-summary">
          KeepingYouAwake is excellent at one focused job. StayRunning starts
          with the same keep-awake control, then adds rules, closed-lid work,
          battery guardrails, a dashboard, and local history.
        </p>
        <p className="guide-byline">
          Written by{" "}
          <a href="https://linkedin.com/in/deepanshum">Deepanshu Mishra</a>,
          creator of StayRunning · Updated July 24, 2026
        </p>
      </header>

      <aside className="comparison-disclosure">
        This comparison is published by StayRunning. KeepingYouAwake is an
        independent open-source project; we link to its official sources so you
        can verify its current features.
      </aside>

      <section aria-labelledby="comparison-overview">
        <h2 id="comparison-overview">The practical difference</h2>
        <p>
          Choose KeepingYouAwake when you want a small menu-bar utility centered
          on one-click activation and predefined durations. Choose StayRunning
          when you want to see why the Mac is staying awake and control the
          conditions around battery, activity, lid state, and history.
        </p>
      </section>

      <section aria-labelledby="feature-comparison">
        <h2 id="feature-comparison">StayRunning vs. KeepingYouAwake</h2>
        <div className="comparison-table" role="table" aria-label="Feature comparison">
          <div className="comparison-row comparison-head" role="row">
            <span role="columnheader">Capability</span>
            <span role="columnheader">KeepingYouAwake</span>
            <span role="columnheader">StayRunning</span>
          </div>
          <div className="comparison-row" role="row">
            <strong role="cell">Core focus</strong>
            <span role="cell">One-click sleep prevention</span>
            <span role="cell">Sleep prevention plus rules and visibility</span>
          </div>
          <div className="comparison-row" role="row">
            <strong role="cell">Activation</strong>
            <span role="cell">One click and predefined durations</span>
            <span role="cell">One click and activity-based rules</span>
          </div>
          <div className="comparison-row" role="row">
            <strong role="cell">Battery protection</strong>
            <span role="cell">Low-battery deactivation</span>
            <span role="cell">Configurable battery guardrails</span>
          </div>
          <div className="comparison-row" role="row">
            <strong role="cell">Closed-lid workflows</strong>
            <span role="cell">Check the current project documentation</span>
            <span role="cell">Dedicated closed-lid mode</span>
          </div>
          <div className="comparison-row" role="row">
            <strong role="cell">Activity history</strong>
            <span role="cell">Not highlighted in its official feature list</span>
            <span role="cell">Local activity history</span>
          </div>
          <div className="comparison-row" role="row">
            <strong role="cell">Source</strong>
            <span role="cell"><a href="https://github.com/newmarcel/KeepingYouAwake">Open-source project</a></span>
            <span role="cell"><a href="https://github.com/DeepanshuMishraa/stayrunning">Open-source project</a></span>
          </div>
        </div>
      </section>

      <section aria-labelledby="who-should-choose">
        <h2 id="who-should-choose">Which should you choose?</h2>
        <p>
          There is no universal winner. KeepingYouAwake has years of history and
          a deliberately compact scope. StayRunning is a better fit when you
          want a more visual, rule-driven workflow for long-running work.
        </p>
        <a className="guide-cta" href="/">Explore StayRunning <span>→</span></a>
      </section>

      <section className="guide-faq" aria-labelledby="comparison-faq">
        <p className="guide-step">Common questions</p>
        <h2 id="comparison-faq">KeepingYouAwake alternatives</h2>
        {faqs.map(({ question, answer }) => (
          <article key={question}>
            <h3>{question}</h3>
            <p>{answer}</p>
          </article>
        ))}
      </section>

      <footer className="guide-sources">
        <h2>Primary sources</h2>
        <ul>
          <li><a href="https://keepingyouawake.app/">KeepingYouAwake official website</a></li>
          <li><a href="https://github.com/newmarcel/KeepingYouAwake">KeepingYouAwake source repository</a></li>
          <li><a href="https://github.com/DeepanshuMishraa/stayrunning">StayRunning source repository</a></li>
          <li><a href="/keep-mac-awake">Guide: how to keep your Mac awake</a></li>
        </ul>
      </footer>
    </GuideShell>
  );
}
