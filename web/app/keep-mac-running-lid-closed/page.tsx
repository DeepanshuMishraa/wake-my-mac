import type { Metadata } from "next";
import { GuideShell } from "../guide-shell";
import { siteUrl } from "../site";

const pageUrl = `${siteUrl}/keep-mac-running-lid-closed`;

const faqs = [
  {
    question: "How do I keep my Mac running with the lid closed?",
    answer:
      "StayRunning provides a closed-lid mode for downloads, builds, backups, SSH sessions, remote access, and coding agents. Enable the mode, confirm its reliable-wake helper is active, and keep the Mac on a ventilated surface.",
  },
  {
    question: "Can the display turn off while my Mac keeps running?",
    answer:
      "Yes. StayRunning can let the display turn off while it prevents system sleep, so background work continues without leaving the screen on.",
  },
  {
    question: "Will closed-lid mode drain the battery?",
    answer:
      "Yes. A Mac that remains active uses more power than a sleeping Mac. StayRunning includes configurable battery guardrails and an option to hold only while connected to power.",
  },
  {
    question: "Is it safe to put an awake MacBook in a bag?",
    answer:
      "No. Keep an active MacBook on a firm, ventilated surface. Do not place it in a bag or another enclosed space while closed-lid mode is active.",
  },
];

export const metadata: Metadata = {
  title: "Keep Mac Running With the Lid Closed",
  description:
    "Keep your Mac running with the lid closed during downloads, builds, backups, SSH, remote access, and coding agents—with battery guardrails.",
  alternates: { canonical: "/keep-mac-running-lid-closed" },
  openGraph: {
    title: "Keep Mac Running With the Lid Closed",
    description:
      "A practical closed-lid workflow for downloads, builds, backups, SSH, remote access, and coding agents.",
    url: "/keep-mac-running-lid-closed",
    type: "article",
  },
};

export default function KeepMacRunningWithLidClosed() {
  const jsonLd = {
    "@context": "https://schema.org",
    "@graph": [
      {
        "@type": "Article",
        "@id": `${pageUrl}/#article`,
        headline: "How to Keep Your Mac Running With the Lid Closed",
        description:
          "A practical guide to keeping downloads, builds, backups, SSH sessions, remote access, and coding agents running after a MacBook lid is closed.",
        url: pageUrl,
        mainEntityOfPage: pageUrl,
        datePublished: "2026-07-24",
        dateModified: "2026-07-24",
        author: {
          "@type": "Person",
          name: "Deepanshu Mishra",
          url: "https://linkedin.com/in/deepanshum",
          sameAs: [
            "https://github.com/DeepanshuMishraa",
            "https://x.com/dipxsyy",
          ],
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
            name: "Keep Mac running with lid closed",
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
        <p className="guide-kicker">macOS closed-lid guide</p>
        <h1>Keep your Mac running with the lid closed</h1>
        <p className="guide-summary">
          StayRunning keeps downloads, builds, backups, SSH sessions, remote
          access, and coding agents active after you close your MacBook.
        </p>
        <p className="guide-byline">
          Written by{" "}
          <a href="https://linkedin.com/in/deepanshum">Deepanshu Mishra</a>,
          creator of StayRunning · Updated July 24, 2026
        </p>
      </header>

      <section className="guide-answer" aria-labelledby="short-answer">
        <h2 id="short-answer">The short answer</h2>
        <p>
          A MacBook normally sleeps when its lid closes. StayRunning provides a
          dedicated closed-lid mode and reliable-wake helper so selected work
          can continue, while battery limits and power rules control when that
          behavior is allowed.
        </p>
      </section>

      <section aria-labelledby="when-to-use">
        <p className="guide-step">Use cases</p>
        <h2 id="when-to-use">When should your Mac keep running?</h2>
        <ul>
          <li>Long downloads, uploads, exports, renders, and backups</li>
          <li>Local builds, tests, containers, and model workloads</li>
          <li>Claude Code, Codex, and other coding-agent sessions</li>
          <li>SSH and remote-access sessions that must remain reachable</li>
        </ul>
      </section>

      <section aria-labelledby="safe-setup">
        <p className="guide-step">Safe setup</p>
        <h2 id="safe-setup">Use closed-lid mode safely</h2>
        <p>
          Keep the Mac on a hard, ventilated surface and connect it to power for
          long sessions when practical. Configure a battery cutoff, and never
          leave an awake MacBook inside a bag or another enclosed space.
        </p>
        <a className="guide-cta" href="/">
          Download StayRunning free <span>→</span>
        </a>
      </section>

      <section className="guide-faq" aria-labelledby="closed-lid-faq">
        <p className="guide-step">Common questions</p>
        <h2 id="closed-lid-faq">Mac closed-lid mode</h2>
        {faqs.map(({ question, answer }) => (
          <article key={question}>
            <h3>{question}</h3>
            <p>{answer}</p>
          </article>
        ))}
      </section>

      <footer className="guide-sources">
        <h2>Related guides and source</h2>
        <ul>
          <li><a href="/keep-mac-awake">How to keep your Mac awake</a></li>
          <li><a href="/keepingyouawake-alternative">KeepingYouAwake alternative for Mac</a></li>
          <li><a href="https://github.com/DeepanshuMishraa/stayrunning">StayRunning source code and releases</a></li>
        </ul>
      </footer>
    </GuideShell>
  );
}
