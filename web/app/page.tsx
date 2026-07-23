import Image from "next/image";
import {
  AppleIcon,
  Brand,
  DownloadLink,
  GitHubIcon,
  SocialLinks,
  downloadUrl,
} from "./site-ui";
import { siteUrl } from "./site";

type FeatureIconName =
  | "lid"
  | "rules"
  | "battery"
  | "remote"
  | "history"
  | "control"
  | "privacy"
  | "speed";

const features: ReadonlyArray<{
  icon: FeatureIconName;
  title: string;
}> = [
  { icon: "lid", title: "Closed-lid mode" },
  { icon: "rules", title: "Activity rules" },
  { icon: "battery", title: "Battery guardrails" },
  { icon: "remote", title: "Remote ready" },
  { icon: "history", title: "Clear history" },
  { icon: "control", title: "One-click control" },
  { icon: "privacy", title: "Private by default" },
  { icon: "speed", title: "Lightweight native app" },
];

function FeatureIcon({ name }: { name: FeatureIconName }) {
  const sharedProps = {
    viewBox: "0 0 48 48",
    "aria-hidden": true,
    fill: "none",
    stroke: "currentColor",
    strokeWidth: 3.8,
    strokeLinecap: "round",
    strokeLinejoin: "round",
  } as const;

  switch (name) {
    case "lid":
      return <svg {...sharedProps}><rect x="7" y="8" width="34" height="26" rx="4" /><path d="M4 39h40M18 39h12" /><path d="M20 21h8" /></svg>;
    case "rules":
      return <svg {...sharedProps}><path d="M8 13h19M35 13h5M8 24h5M21 24h19M8 35h15M31 35h9" /><circle cx="31" cy="13" r="4" /><circle cx="17" cy="24" r="4" /><circle cx="27" cy="35" r="4" /></svg>;
    case "battery":
      return <svg {...sharedProps}><rect x="5" y="13" width="35" height="22" rx="5" /><path d="M40 20h3v8h-3M11 19h16v10H11z" /></svg>;
    case "remote":
      return <svg {...sharedProps}><rect x="7" y="12" width="34" height="24" rx="4" /><path d="M3 41h42M18 41h12M18 25a9 9 0 0 1 12 0M21 28a5 5 0 0 1 6 0M24 32h.01" /></svg>;
    case "history":
      return <svg {...sharedProps}><path d="M10 14v9h9" /><path d="M11 22a15 15 0 1 1 2 13" /><path d="M25 16v9l6 4" /></svg>;
    case "control":
      return <svg {...sharedProps}><rect x="5" y="14" width="38" height="20" rx="10" /><circle cx="33" cy="24" r="6" /></svg>;
    case "privacy":
      return <svg {...sharedProps}><path d="M24 5 40 11v11c0 10-6.5 17-16 21-9.5-4-16-11-16-21V11l16-6Z" /><path d="m17 24 5 5 10-11" /></svg>;
    case "speed":
      return <svg {...sharedProps}><path d="M28 4 11 27h13l-4 17 17-24H24l4-16Z" /></svg>;
  }
}

export default function Home() {
  const jsonLd = {
    "@context": "https://schema.org",
    "@graph": [
      {
        "@type": "WebSite",
        "@id": `${siteUrl}/#website`,
        url: siteUrl,
        name: "Wake My Mac",
        description: "A free macOS utility that keeps your Mac awake.",
        inLanguage: "en-US",
      },
      {
        "@type": "SoftwareApplication",
        "@id": `${siteUrl}/#software`,
        name: "Wake My Mac",
        alternateName: "Hold My Lid",
        url: siteUrl,
        image: `${siteUrl}/og-image.png`,
        downloadUrl,
        softwareVersion: "0.0.3",
        operatingSystem: "macOS 14 Sonoma and later",
        applicationCategory: "UtilitiesApplication",
        applicationSubCategory: "Keep-awake utility",
        isAccessibleForFree: true,
        description:
          "A free, native macOS utility that keeps your Mac awake during downloads, builds, backups, SSH sessions, remote access, and closed-lid work.",
        featureList: [
          "Prevent Mac sleep",
          "Closed-lid mode",
          "Activity rules",
          "Battery guardrails",
          "Remote access support",
          "Local activity history",
        ],
        sameAs: [
          "https://github.com/DeepanshuMishraa/wake-my-mac",
          "https://x.com/dipxsyy",
          "https://linkedin.com/in/deepanshum",
        ],
        offers: {
          "@type": "Offer",
          price: "0",
          priceCurrency: "USD",
          availability: "https://schema.org/InStock",
        },
      },
    ],
  };

  return (
    <main className="page-shell">
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }}
      />

      <section className="hero">
        <nav className="nav" aria-label="Main navigation">
          <Brand iconAction="privacy" />

          <div className="nav-side">
            <a
              className="nav-link"
              href="https://github.com/DeepanshuMishraa/wake-my-mac"
            >
              <GitHubIcon />
              GitHub
            </a>
            <DownloadLink className="nav-download" />
          </div>
        </nav>

        <div className="hero-copy">
          <h1>
            Keep your <span className="hero-mac"><AppleIcon />Mac</span> awake.
            <br />
            Even with the <span className="hero-highlight">lid closed.</span>
          </h1>

          <p className="lede">
            Downloads finish. Builds keep building. Your Mac stays reachable.
          </p>

          <div className="actions">
            <DownloadLink className="download-button" />
            <a
              className="source-button"
              href="https://github.com/DeepanshuMishraa/wake-my-mac"
            >
              <GitHubIcon />
              View source
            </a>
          </div>
        </div>

        <div className="product-stage">
          <Image
            src="/dashboard-preview.png"
            alt="Wake My Mac dashboard showing the Mac is currently being kept awake"
            width={2428}
            height={1762}
            priority
            sizes="(max-width: 767px) 100vw, (max-width: 1279px) 92vw, 1400px"
          />
        </div>
      </section>

      <section className="features" aria-label="Wake My Mac features">
        {features.map((feature) => (
          <article className="feature" key={feature.title}>
            <FeatureIcon name={feature.icon} />
            <h2>{feature.title}</h2>
          </article>
        ))}
      </section>

      <section className="search-intent" aria-labelledby="keep-awake-heading">
        <div>
          <p>KeepingYouAwake alternative for Mac</p>
          <h2 id="keep-awake-heading">A simpler way to keep your Mac awake.</h2>
        </div>
        <div className="search-intent-copy">
          <p>
            Wake My Mac is a free, native macOS keep-awake app for long
            downloads, builds, backups, SSH sessions, and remote access.
          </p>
          <p>
            If you are comparing KeepingYouAwake, Caffeine, or Amphetamine,
            Wake My Mac adds closed-lid support, battery guardrails, activity
            rules, and local history without requiring an account.
          </p>
        </div>
      </section>

      <section className="closing">
        <p>Let your Mac finish downloading, building, and backing up.</p>
        <DownloadLink className="download-button" />
        <SocialLinks />
      </section>

      <footer className="footer">
        <span>Wake My Mac</span>
      </footer>
    </main>
  );
}
