import type { ReactNode } from "react";
import { Brand, DownloadLink, SocialLinks } from "./site-ui";

export function GuideShell({ children }: { children: ReactNode }) {
  return (
    <main className="guide-page">
      <nav className="nav guide-nav" aria-label="Guide navigation">
        <Brand iconAction="privacy" />
        <DownloadLink className="nav-download" />
      </nav>

      <article className="guide-content">{children}</article>

      <SocialLinks />

      <footer className="footer guide-footer">
        <span>Wake My Mac</span>
      </footer>
    </main>
  );
}
