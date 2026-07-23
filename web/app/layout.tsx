import type { Metadata } from "next";
import "./globals.css";
import { siteUrl } from "./site";

export const metadata: Metadata = {
  metadataBase: new URL(siteUrl),
  icons: { icon: "/icon.svg", apple: "/icon.svg" },
  title: {
    default: "Keep Mac Awake, Even With the Lid Closed | Wake My Mac",
    template: "%s — Wake My Mac",
  },
  description: "Keep your Mac awake for downloads, builds, backups, SSH, and remote access—even with the lid closed. Wake My Mac is free, native, and private.",
  applicationName: "Wake My Mac",
  authors: [{ name: "Wake My Mac" }],
  creator: "Deepanshu Mishra",
  publisher: "Wake My Mac",
  category: "Utilities",
  keywords: ["keep Mac awake", "keep MacBook awake with lid closed", "prevent Mac from sleeping", "macOS keep awake app", "Amphetamine alternative", "Caffeine alternative for Mac", "KeepingYouAwake alternative", "hold my Mac awake", "SSH Mac utility", "macOS productivity app"],
  alternates: { canonical: "/" },
  openGraph: {
    title: "Keep Mac Awake, Even With the Lid Closed",
    description: "A free, native macOS utility for downloads, builds, backups, SSH, remote access, and closed-lid work.",
    url: "/",
    siteName: "Wake My Mac",
    type: "website",
    images: [{ url: "/og-image.png", width: 1200, height: 630, alt: "Wake My Mac keeps a Mac awake while work finishes" }],
  },
  twitter: { card: "summary_large_image", title: "Keep Mac Awake, Even With the Lid Closed", description: "Keep your Mac awake while downloads, builds, backups, and remote work finish.", images: ["/og-image.png"] },
  robots: { index: true, follow: true },
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return <html lang="en"><body>{children}</body></html>;
}
