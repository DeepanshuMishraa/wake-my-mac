import type { Metadata } from "next";
import { Brand, DownloadLink, SocialLinks } from "../site-ui";

export const metadata: Metadata = {
  title: "Privacy Policy",
  description:
    "StayRunning does not collect, transmit, or sell personal information.",
  alternates: { canonical: "/privacy" },
  openGraph: {
    title: "Privacy Policy — StayRunning",
    description:
      "StayRunning does not collect, transmit, or sell personal information.",
    url: "/privacy",
    type: "website",
  },
};

export default function PrivacyPolicy() {
  return (
    <main className="privacy-page">
      <nav className="nav privacy-nav" aria-label="Privacy navigation">
        <Brand iconAction="home" />
        <DownloadLink className="nav-download privacy-download" />
      </nav>

      <section className="privacy-content">
        <h1>Privacy policy</h1>
        <p className="privacy-statement">
          No data or personal information is collected by{" "}
          <span className="privacy-inline-brand">
            <span aria-hidden="true" />
            StayRunning
          </span>.
        </p>

        <div className="privacy-questions">
          <h2>Have questions?</h2>
          <p>
            If you have any questions or suggestions regarding this privacy
            policy, do not hesitate to{" "}
            <a href="mailto:dipxsy@duck.com">contact us</a>.
          </p>
        </div>
      </section>

      <SocialLinks />

      <footer className="footer privacy-footer">
        <span>StayRunning</span>
      </footer>
    </main>
  );
}
