import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  metadataBase: new URL("https://wakemymac.com"),
  title: {
    default: "Wake My Mac — Keep your Mac awake, on your terms",
    template: "%s — Wake My Mac",
  },
  description: "A tiny, thoughtful macOS utility that keeps your Mac awake when you need it to — lid closed or not.",
  keywords: ["macOS app", "keep Mac awake", "lid closed", "prevent sleep", "productivity utility"],
  alternates: { canonical: "/" },
  openGraph: {
    title: "Wake My Mac — Keep your Mac awake, on your terms",
    description: "A tiny, thoughtful macOS utility for uninterrupted work, downloads, and SSH sessions.",
    url: "https://wakemymac.com",
    siteName: "Wake My Mac",
    type: "website",
  },
  twitter: { card: "summary_large_image", title: "Wake My Mac", description: "Keep your Mac awake, on your terms." },
  robots: { index: true, follow: true },
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return <html lang="en"><body>{children}</body></html>;
}
