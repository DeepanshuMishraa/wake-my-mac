import type { Metadata } from "next";
import "./globals.css";
import { siteUrl } from "./site";

export const metadata: Metadata = {
  metadataBase: new URL(siteUrl),
  icons: { icon: "/icon.svg", apple: "/icon.svg" },
  title: {
    default: "Keep Mac Running With the Lid Closed | StayRunning",
    template: "%s — StayRunning",
  },
  description: "Keep your Mac running with the lid closed during downloads, builds, backups, SSH, and coding agents. StayRunning is free, native, and private.",
  applicationName: "StayRunning",
  authors: [{ name: "StayRunning" }],
  creator: "Deepanshu Mishra",
  publisher: "StayRunning",
  category: "Utilities",
  keywords: ["keep Mac running with lid closed", "keep Mac awake", "keep MacBook awake with lid closed", "prevent Mac from sleeping", "macOS keep awake app", "Amphetamine alternative", "Caffeine alternative for Mac", "KeepingYouAwake alternative", "Mac awake for coding agents", "SSH Mac utility"],
  alternates: { canonical: "/" },
  openGraph: {
    title: "Keep Mac Running With the Lid Closed",
    description: "A free, native macOS utility that keeps downloads, builds, backups, SSH, and coding agents running after you close the lid.",
    url: "/",
    siteName: "StayRunning",
    type: "website",
    images: [{ url: "/og-image.png", width: 1200, height: 630, alt: "StayRunning keeps a Mac awake while work finishes" }],
  },
  twitter: { card: "summary_large_image", title: "Keep Mac Running With the Lid Closed", description: "Keep downloads, builds, backups, SSH, and coding agents running after you close your Mac.", images: ["/og-image.png"] },
  robots: { index: true, follow: true },
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return <html lang="en"><body>{children}</body></html>;
}
