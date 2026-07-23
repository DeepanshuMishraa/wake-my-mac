import Image from "next/image";

const downloadUrl =
  "https://pub-0f452c90e334438d8e4a54f9b977a5ea.r2.dev/Wake-My-Mac-0.0.3.dmg";

function AppleIcon() {
  return (
    <svg viewBox="0 0 814 1000" aria-hidden="true">
      <path d="M788.1 340.9c-5.8 4.5-108.2 62.2-108.2 190.5 0 148.4 130.3 200.9 134.2 202.2-.6 3.2-20.7 71.9-68.7 141.9-42.8 61.6-87.5 123.1-155.5 123.1s-85.5-39.5-164-39.5c-76.5 0-103.7 40.8-165.9 40.8s-105.6-57-155.5-127C46.7 790.7 0 663 0 541.8c0-194.4 126.4-297.5 250.8-297.5 66.1 0 121.2 43.4 162.7 43.4 39.5 0 101.1-46 176.3-46 28.5 0 130.9 2.6 198.3 99.2zm-234-181.5c31.1-36.9 53.1-88.1 53.1-139.3 0-7.1-.6-14.3-1.9-20.1-50.6 1.9-110.8 33.7-147.1 75.8-28.5 32.4-55.1 83.6-55.1 135.5 0 7.8 1.3 15.6 1.9 18.1 3.2.6 8.4 1.3 13.6 1.3 45.4 0 102.5-30.4 135.5-71.3z" />
    </svg>
  );
}

function DownloadArrowIcon() {
  return (
    <svg viewBox="0 0 24 24" aria-hidden="true">
      <path d="M12 3v13m0 0 5-5m-5 5-5-5M5 21h14" />
    </svg>
  );
}

function DownloadLink({ className }: { className: string }) {
  return (
    <a className={className} href={downloadUrl}>
      <span className="download-leading"><AppleIcon /></span>
      <span className="download-label">Download for Mac</span>
      <span className="download-trailing"><DownloadArrowIcon /></span>
    </a>
  );
}

function GitHubIcon() {
  return (
    <svg viewBox="0 0 24 24" aria-hidden="true">
      <path d="M12 .7a11.5 11.5 0 0 0-3.64 22.41c.58.1.79-.25.79-.56v-2.23c-3.23.7-3.91-1.37-3.91-1.37-.53-1.34-1.29-1.7-1.29-1.7-1.05-.72.08-.71.08-.71 1.17.08 1.78 1.2 1.78 1.2 1.04 1.78 2.72 1.27 3.38.97.1-.75.4-1.27.74-1.56-2.58-.29-5.29-1.29-5.29-5.69 0-1.26.45-2.28 1.19-3.09-.12-.29-.52-1.47.11-3.05 0 0 .97-.31 3.16 1.18a10.96 10.96 0 0 1 5.76 0c2.2-1.49 3.16-1.18 3.16-1.18.63 1.58.23 2.76.11 3.05.74.81 1.19 1.83 1.19 3.09 0 4.41-2.72 5.39-5.3 5.68.42.36.79 1.07.79 2.16v3.21c0 .31.21.67.8.56A11.5 11.5 0 0 0 12 .7Z" />
    </svg>
  );
}

function XIcon() {
  return (
    <svg viewBox="0 0 24 24" aria-hidden="true">
      <path d="M18.9 2H22l-6.77 7.74L23.2 22h-6.24l-4.89-6.39L6.48 22H3.36l7.26-8.3L2.97 2H9.4l4.42 5.84L18.9 2Zm-1.1 17.84h1.73L8.46 4.05H6.6L17.8 19.84Z" />
    </svg>
  );
}

function LinkedInIcon() {
  return (
    <svg viewBox="0 0 24 24" aria-hidden="true">
      <path d="M5.34 7.67H1.68V22h3.66V7.67ZM3.51 2A2.13 2.13 0 1 0 3.5 6.25 2.13 2.13 0 0 0 3.51 2ZM22.32 13.78c0-4.32-2.3-6.33-5.38-6.33a4.65 4.65 0 0 0-4.21 2.32v-2.1H9.07V22h3.66v-7.1c0-1.87.36-3.69 2.68-3.69 2.29 0 2.32 2.14 2.32 3.81V22h3.66l.93-8.22Z" />
    </svg>
  );
}

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
    strokeWidth: 2.7,
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
    "@type": "SoftwareApplication",
    name: "Wake My Mac",
    alternateName: "Hold My Lid",
    url: "https://wakemymac.com/",
    downloadUrl,
    operatingSystem: "macOS 14 Sonoma and later",
    applicationCategory: "UtilitiesApplication",
    description:
      "A private macOS utility that keeps your Mac awake while downloads, builds, exports, and remote sessions finish.",
    offers: {
      "@type": "Offer",
      price: "0",
      priceCurrency: "USD",
    },
  };

  return (
    <main className="page-shell">
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }}
      />

      <section className="hero">
        <nav className="nav" aria-label="Main navigation">
          <a className="brand" href="#" aria-label="Wake My Mac home">
            <span className="brand-mark" aria-hidden="true"><span /></span>
            <span>Wake My Mac</span>
            <span className="version">v0.0.3</span>
          </a>

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
            Keep your Mac awake.
            <br />
            Even with the <span>lid closed.</span>
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
            sizes="(max-width: 720px) 132vw, (max-width: 1200px) 92vw, 1220px"
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

      <section className="closing">
        <p>Let your Mac finish downloading, building, and backing up.</p>
        <DownloadLink className="download-button" />
        <div className="social-links" aria-label="Project links">
          <a
            href="https://github.com/DeepanshuMishraa/wake-my-mac"
            aria-label="Wake My Mac on GitHub"
          >
            <GitHubIcon />
          </a>
          <a
            href="https://x.com/dipxsyy"
            aria-label="Dipxsy on X"
          >
            <XIcon />
          </a>
          <a
            href="https://linkedin.com/in/deepanshum"
            aria-label="Deepanshum on LinkedIn"
          >
            <LinkedInIcon />
          </a>
        </div>
      </section>

      <footer className="footer">
        <span>Wake My Mac</span>
      </footer>
    </main>
  );
}
