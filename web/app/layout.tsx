import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  metadataBase: new URL("https://wakemymac.com"),
  icons: { icon: "/icon.svg", apple: "/icon.svg" },
  title: {
    default: "Keep Your Mac Awake with Wake My Mac | Free macOS Utility",
    template: "%s — Wake My Mac",
  },
  description: "Wake My Mac is a free, private macOS utility that keeps your Mac awake for downloads, builds, exports, SSH sessions, remote work, and closed-lid tasks.",
  applicationName: "Wake My Mac",
  authors: [{ name: "Wake My Mac" }],
  creator: "Wake My Mac",
  publisher: "Wake My Mac",
  category: "Utilities",
  keywords: ["keep Mac awake", "keep MacBook awake with lid closed", "prevent Mac from sleeping", "macOS keep awake app", "Amphetamine alternative", "Caffeine alternative for Mac", "KeepingYouAwake alternative", "hold my Mac awake", "SSH Mac utility", "macOS productivity app"],
  alternates: { canonical: "/" },
  openGraph: {
    title: "Keep Your Mac Awake with Wake My Mac",
    description: "A free, private macOS utility for downloads, builds, exports, SSH sessions, remote work, and closed-lid tasks.",
    url: "https://wakemymac.com",
    siteName: "Wake My Mac",
    type: "website",
    images: [{ url: "/og-image.png", width: 1200, height: 630, alt: "Wake My Mac keeps a Mac awake while work finishes" }],
  },
  twitter: { card: "summary_large_image", title: "Keep Your Mac Awake with Wake My Mac", description: "Keep your Mac awake while the work finishes. Native, private, and built for macOS.", images: ["/og-image.png"] },
  robots: { index: true, follow: true },
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return <html lang="en"><body>{children}</body></html>;
}
