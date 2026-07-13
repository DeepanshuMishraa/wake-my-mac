"use client";

import { useState } from "react";

const features = [
  ["Quietly present", "Know when your Mac is being kept awake. A small status-bar companion, never a noisy dashboard."],
  ["Lid closed, work on", "Close the lid and keep the important bits running — displays, servers, transfers, and remote sessions."],
  ["Rules that think ahead", "Plugged in, on battery, or in a low-power moment. Set the conditions once and get out of the way."],
  ["Native by nature", "Swift-built for macOS. Lightweight, private, and comfortable in the place your Mac already feels like home."],
];

const faqs = [
  ["What is Wake My Mac?", "Wake My Mac is a tiny macOS utility that keeps your Mac awake when you need it to. It helps with long downloads, exports, presentations, remote access, and SSH sessions — even when the lid is closed."],
  ["Does it drain my battery?", "You stay in control. Wake My Mac can be set to work only while plugged in, and it respects Low Power Mode when you want to conserve energy."],
  ["Is my data private?", "Yes. Wake My Mac runs locally on your Mac. There are no accounts, analytics dashboards, or cloud services required for the app to do its job."],
  ["Which macOS versions are supported?", "Wake My Mac supports macOS 14 Sonoma and later."],
];

function AppleIcon() { return <svg className="apple-icon" style={{ display: "block", flexShrink: 0 }} viewBox="0 0 814 1000" aria-hidden="true"><path d="M788.1 340.9c-5.8 4.5-108.2 62.2-108.2 190.5 0 148.4 130.3 200.9 134.2 202.2-.6 3.2-20.7 71.9-68.7 141.9-42.8 61.6-87.5 123.1-155.5 123.1s-85.5-39.5-164-39.5c-76.5 0-103.7 40.8-165.9 40.8s-105.6-57-155.5-127C46.7 790.7 0 663 0 541.8c0-194.4 126.4-297.5 250.8-297.5 66.1 0 121.2 43.4 162.7 43.4 39.5 0 101.1-46 176.3-46 28.5 0 130.9 2.6 198.3 99.2zm-234-181.5c31.1-36.9 53.1-88.1 53.1-139.3 0-7.1-.6-14.3-1.9-20.1-50.6 1.9-110.8 33.7-147.1 75.8-28.5 32.4-55.1 83.6-55.1 135.5 0 7.8 1.3 15.6 1.9 18.1 3.2.6 8.4 1.3 13.6 1.3 45.4 0 102.5-30.4 135.5-71.3z"/></svg>; }
function DownloadButton({ className = "" }: { className?: string }) { return <a className={`button button-dark ${className}`} href="#download"><AppleIcon />Download for Mac</a>; }

export default function Home() {
  const [activeFaq, setActiveFaq] = useState<number | null>(null);
  const [isHeld, setIsHeld] = useState(true);

  const jsonLd = { "@context": "https://schema.org", "@type": "SoftwareApplication", name: "Wake My Mac", operatingSystem: "macOS", applicationCategory: "UtilitiesApplication", description: "A thoughtful macOS utility that keeps your Mac awake when you need it to.", offers: { "@type": "Offer", price: "0", priceCurrency: "USD" } };

  return <main>
    <script type="application/ld+json" dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }} />
    <nav className="nav shell" aria-label="Main navigation">
      <a className="wordmark" href="#top">Wake My Mac<span className="dot">.</span></a>
      <div className="nav-links"><a href="#how-it-works">How it works</a><a href="#faqs">FAQs</a><a className="nav-cta" href="#download"><AppleIcon />Download for Mac</a></div>
    </nav>

    <section id="top" className="hero shell">
      <p className="eyebrow reveal">A little more time for your Mac</p>
      <h1 className="reveal delay-one">Keep your Mac awake.<br /><em>On your terms.</em></h1>
      <p className="hero-copy reveal delay-two">Wake My Mac is a small, thoughtful utility for the moments when your Mac needs to keep going — even after you close the lid.</p>
      <div className="hero-actions reveal delay-three"><DownloadButton /><a className="text-link" href="#how-it-works">See how it works <span aria-hidden="true">↓</span></a></div>
    </section>

    <section className="product-stage shell" aria-label="Wake My Mac dashboard preview">
      <div className="product-window">
        <aside className="product-sidebar"><div className="product-brand"><span className="brand-orb">◒</span><span>Wake My Mac</span></div><div className="product-nav"><span className="selected">◉ &nbsp; Overview</span><span>◷ &nbsp; History</span><span>ϟ &nbsp; Activity Rules</span></div><div className="product-sidebar-foot">v1.0.0<br /><span>macOS utility</span></div></aside>
        <div className="product-content"><div className="product-topline"><div><span className="product-kicker">Live status</span><h3>Overview</h3><p>{isHeld ? "Your Mac is protected and reachable." : "Your Mac can sleep normally."}</p></div><div className="product-actions"><button className={`status-pill ${isHeld ? "is-on" : ""}`} onClick={() => setIsHeld(!isHeld)}><span />{isHeld ? "Holding awake" : "Sleep allowed"}</button><div className="range-pills"><span className="active">Today</span><span>7 Days</span><span>30 Days</span></div></div></div><div className="metric-grid"><div><span>Awake · Today</span><strong>{isHeld ? "6h 42m" : "—"}</strong><small>◷</small></div><div><span>Sessions · Today</span><strong>{isHeld ? "3" : "0"}</strong><small>⌁</small></div><div><span>Battery used</span><strong>{isHeld ? "4.8%" : "—"}</strong><small>▰</small></div></div><div className="chart-card"><div><strong>Awake time</strong><span>Minutes kept awake per day</span></div><div className="bars"><i style={{height:"30%"}} /><i style={{height:"49%"}} /><i style={{height:"38%"}} /><i style={{height:"72%"}} /><i className="today" style={{height:isHeld ? "92%" : "12%"}} /><i style={{height:"56%"}} /><i style={{height:"30%"}} /></div><div className="chart-labels"><span>Jul 7</span><span>Jul 13</span></div></div><div className="product-bottom"><div><strong>Currently keeping awake</strong><span>✓ Agent activity</span><span>✓ SSH session</span></div><div><strong>Agents</strong><span><b className="green-dot" /> Codex</span><span><b className="blue-dot" /> Pi</span></div></div></div>
      </div>
      <div className="stage-caption"><span>Wake My Mac · native macOS dashboard</span><span>Live preview <b>✦</b></span></div>
    </section>

    <section id="how-it-works" className="intro shell"><p className="eyebrow">A small utility with a big job</p><h2>For the work that<br /><em>needs one more minute.</em></h2><p className="intro-copy">Downloads. Builds. Backups. A presentation in another room. Wake My Mac gives your Mac permission to keep going, so you can close the lid and move on.</p></section>

    <section className="feature-list shell">{features.map(([title, body], index) => <article className="feature" key={title}><span className="feature-number">0{index + 1}</span><div><h3>{title}</h3><p>{body}</p></div><span className="feature-mark">✦</span></article>)}</section>

    <section className="quote-section"><div className="quote-inner shell"><span className="quote-mark">“</span><blockquote>Finally, a Mac utility that does exactly one thing — and does it beautifully.</blockquote><p>— Someone who closes their lid a lot</p></div></section>

    <section id="faqs" className="faq-section shell"><div className="faq-heading"><p className="eyebrow">Questions, answered</p><h2>Good to know.</h2></div><div className="faq-list">{faqs.map(([question, answer], index) => <div className={`faq ${activeFaq === index ? "open" : ""}`} key={question}><button onClick={() => setActiveFaq(activeFaq === index ? null : index)} aria-expanded={activeFaq === index}><span>{question}</span><span className="plus">+</span></button><div className="faq-answer"><p>{answer}</p></div></div>)}</div></section>

    <section id="download" className="download-section shell"><div><p className="eyebrow">Your Mac, uninterrupted</p><h2>Let it keep<br /><em>going.</em></h2></div><div className="download-side"><p>Wake My Mac is free to download, easy to set up, and stays out of your way until you need it.</p><a className="button button-dark" href="mailto:hello@wakemymac.com?subject=Wake%20My%20Mac%20download"><AppleIcon />Download for Mac</a><small>macOS 14 Sonoma or later</small></div></section>

    <footer className="footer shell"><a className="wordmark" href="#top">Wake My Mac<span className="dot">.</span></a><div><a href="mailto:hello@wakemymac.com">Contact</a><a href="#faqs">FAQs</a><span>© 2026 Wake My Mac</span></div></footer>
  </main>;
}
