import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  metadataBase: new URL("https://wakemymac.com"),
  title: {
    default: "Wake My Mac — Keep your Mac awake, on your terms",
    template: "%s — Wake My Mac",
  },
  description: "Keep your Mac awake while downloads, builds, exports, SSH sessions, and remote work finish — with a native, private macOS utility.",
  keywords: ["macOS keep awake app", "keep Mac awake", "prevent Mac sleep", "lid closed Mac", "SSH Mac utility", "macOS productivity app"],
  alternates: { canonical: "/" },
  openGraph: {
    title: "Wake My Mac — Keep your Mac awake, on your terms",
    description: "Keep your Mac awake while downloads, builds, exports, SSH sessions, and remote work finish.",
    url: "https://wakemymac.com",
    siteName: "Wake My Mac",
    type: "website",
  },
  twitter: { card: "summary_large_image", title: "Wake My Mac — Keep your Mac awake, on your terms", description: "Keep your Mac awake while the work finishes. Native, private, and built for macOS." },
  robots: { index: true, follow: true },
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return <html lang="en"><body>{children}</body></html>;
}
