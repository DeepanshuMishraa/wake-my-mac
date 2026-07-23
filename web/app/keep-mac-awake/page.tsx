import type { Metadata } from "next";
import { GuideShell } from "../guide-shell";
import { siteUrl } from "../site";

const pageUrl = `${siteUrl}/keep-mac-awake`;

const faqs = [
  {
    question: "How do I keep my Mac awake temporarily?",
    answer:
      "For a quick built-in option, open Terminal and run caffeinate. It keeps the Mac awake until you stop the command with Control-C or close that Terminal session.",
  },
  {
    question: "Can my display turn off while the Mac stays awake?",
    answer:
      "Yes. Display sleep and system sleep are separate. A keep-awake utility can let the display turn off while preventing the Mac itself from sleeping.",
  },
  {
    question: "How do I keep a Mac awake for one hour?",
    answer:
      "Run caffeinate -t 3600 in Terminal. The number is the duration in seconds. A graphical utility is easier when you need this repeatedly.",
  },
  {
    question: "Can Wake My Mac keep working with the lid closed?",
    answer:
      "Wake My Mac includes a closed-lid mode for downloads, builds, backups, SSH, and remote-access workflows, with battery guardrails you control.",
  },
];

export const metadata: Metadata = {
  title: "How to Keep Your Mac Awake",
  description:
    "Keep your Mac awake with macOS settings, Terminal's caffeinate command, or a free native app. Includes timed, display-off, and closed-lid options.",
  alternates: { canonical: "/keep-mac-awake" },
  openGraph: {
    title: "How to Keep Your Mac Awake",
    description:
      "Built-in commands, settings, and a native app for keeping a Mac awake during downloads, builds, backups, SSH, and remote access.",
    url: "/keep-mac-awake",
    type: "article",
  },
};

export default function KeepMacAwakeGuide() {
  const jsonLd = {
    "@context": "https://schema.org",
    "@graph": [
      {
        "@type": "Article",
        "@id": `${pageUrl}/#article`,
        headline: "How to Keep Your Mac Awake",
        description:
          "A practical guide to macOS settings, the caffeinate command, and Wake My Mac.",
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
          name: "Wake My Mac",
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
            name: "Wake My Mac",
            item: siteUrl,
          },
          {
            "@type": "ListItem",
            position: 2,
            name: "How to keep your Mac awake",
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
        <p className="guide-kicker">macOS practical guide</p>
        <h1>How to keep your Mac awake</h1>
        <p className="guide-summary">
          Use macOS settings for everyday behavior, Terminal’s{" "}
          <code>caffeinate</code> command for a quick session, or Wake My Mac
          when you need repeatable rules, battery limits, and closed-lid work.
        </p>
        <p className="guide-byline">
          Written by{" "}
          <a href="https://linkedin.com/in/deepanshum">Deepanshu Mishra</a>,
          creator of Wake My Mac · Updated July 24, 2026
        </p>
      </header>

      <section className="guide-answer" aria-labelledby="short-answer">
        <h2 id="short-answer">The short answer</h2>
        <p>
          To keep a Mac awake right now, open Terminal and run{" "}
          <code>caffeinate</code>. For a visual control you can reuse without
          remembering commands, use a native keep-awake app. Your display can
          still turn off while the Mac continues downloads, builds, backups,
          SSH sessions, or remote access.
        </p>
      </section>

      <section aria-labelledby="mac-settings">
        <p className="guide-step">Option 01</p>
        <h2 id="mac-settings">Adjust macOS sleep settings</h2>
        <p>
          macOS includes separate controls for display sleep and automatic
          system sleep. The exact choices depend on whether you use a MacBook or
          desktop Mac and which macOS version is installed.
        </p>
        <p>
          Start in System Settings under Lock Screen, Battery, or Energy. Apple
          documents the current controls in its{" "}
          <a href="https://support.apple.com/guide/mac-help/set-sleep-and-wake-settings-mchle41a6ccd/mac">
            sleep and wake settings guide
          </a>.
        </p>
      </section>

      <section aria-labelledby="caffeinate-command">
        <p className="guide-step">Option 02</p>
        <h2 id="caffeinate-command">Use the caffeinate command</h2>
        <p>
          The built-in <code>caffeinate</code> command is ideal for a one-off
          session. It needs no installation and stops when you end the command.
        </p>
        <div className="command-list" aria-label="caffeinate command examples">
          <div><code>caffeinate</code><span>Stay awake until stopped</span></div>
          <div><code>caffeinate -t 3600</code><span>Stay awake for one hour</span></div>
          <div><code>caffeinate -i command</code><span>Stay awake while a command runs</span></div>
        </div>
      </section>

      <section aria-labelledby="wake-my-mac-option">
        <p className="guide-step">Option 03</p>
        <h2 id="wake-my-mac-option">Use Wake My Mac for repeatable work</h2>
        <p>
          Wake My Mac packages the same job into a native interface with
          one-click control, activity rules, battery guardrails, closed-lid
          mode, and local history. It is designed for work you repeat: long
          downloads, builds, backups, renders, SSH, and remote sessions.
        </p>
        <a className="guide-cta" href="/">See Wake My Mac and download it free <span>→</span></a>
      </section>

      <section className="guide-faq" aria-labelledby="keep-awake-faq">
        <p className="guide-step">Common questions</p>
        <h2 id="keep-awake-faq">Keeping a Mac awake</h2>
        {faqs.map(({ question, answer }) => (
          <article key={question}>
            <h3>{question}</h3>
            <p>{answer}</p>
          </article>
        ))}
      </section>

      <footer className="guide-sources">
        <h2>Sources and further reading</h2>
        <ul>
          <li><a href="https://support.apple.com/guide/mac-help/set-sleep-and-wake-settings-mchle41a6ccd/mac">Apple: Set sleep and wake settings for your Mac</a></li>
          <li><a href="https://github.com/DeepanshuMishraa/wake-my-mac">Wake My Mac source code and releases</a></li>
          <li><a href="/keepingyouawake-alternative">Compare Wake My Mac with KeepingYouAwake</a></li>
        </ul>
      </footer>
    </GuideShell>
  );
}
