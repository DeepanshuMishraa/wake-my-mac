"use client";

import { useState } from "react";

const useCases = [
  { number: "01", title: "Long jobs", body: "Keep a build, export, download, or backup moving while you step away." },
  { number: "02", title: "Closed-lid work", body: "Your Mac can stay reachable for SSH, remote access, and services in the background." },
  { number: "03", title: "Your rules", body: "Choose when it holds, when it stops, and what happens on battery. Then leave it alone." },
];

const faqs = [
  ["What does Wake My Mac do?", "It keeps your Mac awake when something important is still running. You can use it for long downloads, builds, exports, presentations, remote access, and SSH sessions — with the lid open or closed."],
  ["Will it keep my display on?", "No. Wake My Mac separates keeping the Mac awake from keeping the display on. You decide what happens when the lid closes or a task finishes."],
  ["Can I use it on battery?", "Yes. Set a battery cutoff, choose whether it should work only while plugged in, and let Wake My Mac respect Low Power Mode when you need to save energy."],
  ["Does it send anything to the cloud?", "No account is required. Wake My Mac runs locally on your Mac and keeps its activity history there."],
  ["Which Macs are supported?", "Wake My Mac supports macOS 14 Sonoma and later."],
];

function AppleIcon() {
  return <svg className="apple-icon" viewBox="0 0 814 1000" aria-hidden="true"><path d="M788.1 340.9c-5.8 4.5-108.2 62.2-108.2 190.5 0 148.4 130.3 200.9 134.2 202.2-.6 3.2-20.7 71.9-68.7 141.9-42.8 61.6-87.5 123.1-155.5 123.1s-85.5-39.5-164-39.5c-76.5 0-103.7 40.8-165.9 40.8s-105.6-57-155.5-127C46.7 790.7 0 663 0 541.8c0-194.4 126.4-297.5 250.8-297.5 66.1 0 121.2 43.4 162.7 43.4 39.5 0 101.1-46 176.3-46 28.5 0 130.9 2.6 198.3 99.2zm-234-181.5c31.1-36.9 53.1-88.1 53.1-139.3 0-7.1-.6-14.3-1.9-20.1-50.6 1.9-110.8 33.7-147.1 75.8-28.5 32.4-55.1 83.6-55.1 135.5 0 7.8 1.3 15.6 1.9 18.1 3.2.6 8.4 1.3 13.6 1.3 45.4 0 102.5-30.4 135.5-71.3z" /></svg>;
}

function DownloadButton({ className = "" }: { className?: string }) {
  return <a className={`button button-dark ${className}`} href="https://github.com/DeepanshuMishraa/wake-my-mac/releases/download/V0.0.2/Wake-My-Mac-0.0.2.dmg"><AppleIcon />Download for Mac</a>;
}

function MiniIcon({ children }: { children: React.ReactNode }) {
  return <span className="mini-icon" aria-hidden="true">{children}</span>;
}

export default function Home() {
  const [activeFaq, setActiveFaq] = useState<number | null>(null);

  const jsonLd = {
    "@context": "https://schema.org",
    "@type": "SoftwareApplication",
    name: "Wake My Mac",
    operatingSystem: "macOS",
    applicationCategory: "UtilitiesApplication",
    description: "A native macOS utility that keeps your Mac awake while downloads, builds, exports, and remote sessions finish.",
    offers: { "@type": "Offer", price: "0", priceCurrency: "USD" },
  };

  return <main>
    <script type="application/ld+json" dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }} />

    <nav className="nav shell" aria-label="Main navigation">
      <a className="wordmark" href="#top"><span className="wordmark-mark">—</span> Wake My Mac</a>
      <div className="nav-links">
        <a href="#why">Why it exists</a>
        <a href="#how-it-works">How it works</a>
        <a href="#faqs">FAQ</a>
        <a className="nav-cta" href="#download"><AppleIcon />Download free</a>
      </div>
    </nav>

    <section id="top" className="hero shell">
      <div className="hero-copy-block">
        <p className="eyebrow reveal">A quiet utility for macOS</p>
        <h1 className="reveal delay-one">Stay in the flow.<br /><em>Keep your Mac awake.</em></h1>
        <p className="hero-copy reveal delay-two">Downloads finish. Builds complete. Remote sessions stay reachable. Wake My Mac keeps the machine working after you stop watching it.</p>
        <div className="hero-actions reveal delay-three"><DownloadButton /><a className="text-link" href="#why">See what it protects <span aria-hidden="true">↓</span></a></div>
        <p className="hero-note reveal delay-three"><span className="live-dot" /> Native macOS app · Runs locally · macOS 14+</p>
      </div>
      <div className="hero-aside" aria-label="Product promise"><span>01</span><p>No accounts.<br />No cloud dashboard.<br /><strong>Just a Mac that knows when to keep going.</strong></p></div>
    </section>

    <img src="/dashboard-preview.png" alt="Wake My Mac Dashboard Overview" className="product-image shell" />


    <section id="why" className="why shell">
      <div className="section-lede"><p className="eyebrow">The problem is small. The interruption isn’t.</p><h2>The lid can close.<br /><em>Your work doesn’t have to.</em></h2></div>
      <div className="why-copy"><p>macOS is right to sleep when you’re done. The trouble is that “done” is sometimes a download at 94%, a build on its last step, or a server you still need to reach.</p><p>Wake My Mac gives you a clear, local switch for those in-between moments — then gets out of your way.</p><a className="arrow-link" href="#how-it-works">How it works <span>↗</span></a></div>
    </section>

    <section id="how-it-works" className="use-cases shell">
      <div className="use-cases-heading"><p className="eyebrow">Made for the waiting parts</p><h2>Let the Mac<br /><em>finish the thought.</em></h2></div>
      <div className="use-case-list">{useCases.map((item) => <article className="use-case" key={item.number}><span>{item.number}</span><div><h3>{item.title}</h3><p>{item.body}</p></div><b>↗</b></article>)}</div>
    </section>

    <section className="principles"><div className="principles-inner shell"><p className="eyebrow">The Wake My Mac rule</p><h2>Useful enough to notice.<br /><em>Quiet enough to forget.</em></h2><div className="principle-grid"><div><MiniIcon>⌁</MiniIcon><strong>Native</strong><p>Built for macOS, not wrapped around it.</p></div><div><MiniIcon>◌</MiniIcon><strong>Private</strong><p>Your activity stays on your Mac.</p></div><div><MiniIcon>↗</MiniIcon><strong>Predictable</strong><p>Set the conditions. Know what happens next.</p></div></div></div></section>

    <section id="faqs" className="faq-section shell"><div className="faq-heading"><p className="eyebrow">Questions, answered</p><h2>Good to<br /><em>know.</em></h2><p>Still unsure? <a href="mailto:hello@wakemymac.com">Ask us directly ↗</a></p></div><div className="faq-list">{faqs.map(([question, answer], index) => <div className={`faq ${activeFaq === index ? "open" : ""}`} key={question}><button onClick={() => setActiveFaq(activeFaq === index ? null : index)} aria-expanded={activeFaq === index}><span>{question}</span><span className="plus">+</span></button><div className="faq-answer"><p>{answer}</p></div></div>)}</div></section>

    <section id="download" className="download-section shell"><div><p className="eyebrow">A better default</p><h2>Keep going.<br /><em>On your terms.</em></h2></div><div className="download-side"><p>Wake My Mac is free to download, takes a minute to set up, and stays out of the way until your Mac needs a little more time.</p><DownloadButton /><small>Free · macOS 14 Sonoma or later</small></div></section>

    <footer className="footer shell"><a className="wordmark" href="#top"><span className="wordmark-mark">—</span> Wake My Mac</a><div><a href="mailto:hello@wakemymac.com">Contact</a><a href="#faqs">FAQ</a><span>© 2026 Wake My Mac</span></div></footer>
  </main>;
}
