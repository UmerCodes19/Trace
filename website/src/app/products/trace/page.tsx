"use client";

import { useEffect, useRef, useState } from "react";
import gsap from "gsap";
import { ScrollTrigger } from "gsap/ScrollTrigger";
import Link from "next/link";

gsap.registerPlugin(ScrollTrigger);

const FEATURES = [
  { icon: "📸", title: "AI Image Analysis", desc: "Snap a photo and Gemini AI instantly identifies and categorizes your lost item with high accuracy." },
  { icon: "🗺️", title: "Campus Map", desc: "Pin exact locations on detailed Bahria University floor maps. Never say 'somewhere near the cafeteria' again." },
  { icon: "⛓️", title: "Blockchain Logging", desc: "Every claim is SHA-256 hashed and chained — tamper-proof audit trail for every handover." },
  { icon: "📱", title: "QR Handover", desc: "Generate a secure QR code for item exchange. Scan to confirm — clean, contactless, verified." },
  { icon: "🔔", title: "Real-time Alerts", desc: "Firebase push notifications the moment someone finds something matching your description." },
  { icon: "🤖", title: "Discord Bot", desc: "Report lost/found items directly from Discord. /lost /found /claim — campus-wide reach." },
];

const STEPS = [
  { num: "01", title: "Snap & Report", desc: "Take a photo. AI fills in the details. Post in under 30 seconds." },
  { num: "02", title: "Smart Match", desc: "Our matching engine compares tags, location, and image similarity across all posts." },
  { num: "03", title: "Secure Return", desc: "Chat in-app, verify ownership, scan QR to complete the handover. Done." },
];

const TECH = [
  { name: "Flutter", role: "Mobile App" },
  { name: "Node.js", role: "Backend API" },
  { name: "Next.js", role: "Website" },
  { name: "Supabase", role: "Database" },
  { name: "Firebase", role: "Auth + FCM" },
  { name: "Gemini AI", role: "Image Analysis" },
  { name: "Cloudinary", role: "Image Storage" },
  { name: "Vercel", role: "Deployment" },
];

const FAQS = [
  { q: "Is Trace only for Bahria University?", a: "Currently yes — built specifically for Bahria University Karachi campus with its floor maps and CMS integration. Other campuses coming soon." },
  { q: "How does ownership verification work?", a: "The claimant must describe unique details about the item. Once matched, a QR code is generated for physical exchange — logged on the blockchain." },
  { q: "Is my data safe?", a: "All data is stored on Supabase (PostgreSQL) with Firebase Auth. Claim logs are blockchain-secured and tamper-proof." },
  { q: "Can I use it without the app?", a: "Yes! The web version lets you browse and report items. The mobile app gives you push notifications and camera access." },
];

export default function TracePage() {
  const titleRef = useRef<HTMLHeadingElement>(null);
  const featuresRef = useRef<HTMLDivElement>(null);
  const stepsRef = useRef<HTMLDivElement>(null);
  const [openFaq, setOpenFaq] = useState<number | null>(null);

  useEffect(() => {
    const ctx = gsap.context(() => {
      gsap.from(titleRef.current, { y: 80, opacity: 0, duration: 1.2, ease: "power4.out" });
      gsap.from(".hero-sub", { y: 40, opacity: 0, duration: 1, delay: 0.3, ease: "power3.out" });
      gsap.from(".hero-badge", { y: 20, opacity: 0, stagger: 0.1, delay: 0.5, duration: 0.6 });
      gsap.from(".hero-btn", { y: 20, opacity: 0, stagger: 0.15, delay: 0.7, duration: 0.6 });
      gsap.from(".feature-card", {
        scrollTrigger: { trigger: featuresRef.current, start: "top 80%" },
        y: 60, opacity: 0, stagger: 0.12, duration: 0.8, ease: "power3.out",
      });
      gsap.from(".step-item", {
        scrollTrigger: { trigger: stepsRef.current, start: "top 75%" },
        x: -50, opacity: 0, stagger: 0.2, duration: 0.9, ease: "power3.out",
      });
      gsap.to(".orb", { y: -30, duration: 3, repeat: -1, yoyo: true, ease: "sine.inOut" });
    });
    return () => ctx.revert();
  }, []);

  return (
    <div className="min-h-screen bg-[var(--background)] text-[var(--foreground)] overflow-x-hidden">

      {/* Nav */}
      <nav className="fixed top-0 left-0 right-0 z-50 flex items-center justify-between px-6 md:px-12 h-16 border-b border-[var(--border-color)] bg-[var(--background)]/80 backdrop-blur-md">
        <Link href="/" className="text-xs font-bold text-sage-secondary hover:text-jade-primary transition-colors">
          Back to Home
        </Link>
        <span className="text-sm font-black tracking-widest text-[var(--foreground)]">TRACE</span>
        <a
          href="/trace.apk"
          download
          className="px-4 py-1.5 bg-jade-primary text-white text-xs font-bold rounded-full hover:opacity-90 transition-all"
        >
          Download APK
        </a>
      </nav>

      {/* Hero */}
      <section className="relative min-h-screen flex flex-col items-center justify-center text-center px-6 pt-16 overflow-hidden">
        <div className="orb absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[600px] h-[600px] bg-jade-primary/10 blur-[140px] rounded-full pointer-events-none" />
        <div
          className="absolute inset-0 pointer-events-none"
          style={{
            backgroundImage: "linear-gradient(rgba(255,255,255,0.04) 1px, transparent 1px), linear-gradient(90deg, rgba(255,255,255,0.04) 1px, transparent 1px)",
            backgroundSize: "60px 60px",
          }}
        />

        <div className="relative z-10 flex flex-col items-center gap-8 max-w-5xl w-full">

          {/* Badge */}
          <div className="inline-flex items-center gap-2 px-5 py-2 border border-jade-primary/40 bg-jade-primary/10 rounded-full text-jade-primary text-xs font-bold uppercase tracking-widest">
            <span className="w-2 h-2 bg-jade-primary rounded-full animate-pulse inline-block" />
            Bahria University Karachi
          </div>

          {/* Title */}
          <h1
            ref={titleRef}
            className="text-8xl md:text-[11rem] font-black tracking-tighter leading-none text-[var(--foreground)]"
          >
            TRACE<span className="text-jade-primary">.</span>
          </h1>

          {/* Subtitle */}
          <p className="hero-sub text-base md:text-xl text-sage-secondary font-medium max-w-2xl leading-relaxed">
            The AI-powered lost and found system for your campus. Report, match, and recover items in minutes.
          </p>

          {/* Feature Badges */}
          <div className="flex flex-wrap justify-center gap-2">
            {["AI Image Analysis", "Blockchain Logging", "QR Handover", "Campus Maps", "Discord Bot"].map((b) => (
              <span
                key={b}
                className="hero-badge px-4 py-1.5 border border-[var(--border-color)] bg-[var(--card-bg)] text-xs font-semibold rounded-full text-[var(--foreground)]"
              >
                {b}
              </span>
            ))}
          </div>

          {/* CTA Buttons */}
          <div className="flex flex-col sm:flex-row items-center justify-center gap-4 w-full max-w-md">
            <a
              href="https://trace-self.vercel.app"
              target="_blank"
              rel="noreferrer"
              className="hero-btn w-full sm:w-auto px-8 py-4 bg-jade-primary text-white font-black text-sm rounded-2xl hover:opacity-90 transition-all shadow-lg shadow-jade-primary/30 active:scale-95 text-center"
            >
              Try Web Version
            </a>
            <a
              href="/trace.apk"
              download
              className="hero-btn w-full sm:w-auto px-8 py-4 border border-[var(--border-color)] bg-[var(--card-bg)] text-[var(--foreground)] font-black text-sm rounded-2xl hover:border-jade-primary transition-all active:scale-95 text-center"
            >
              Download APK
            </a>
          </div>

          {/* Stats Row */}
          <div className="grid grid-cols-3 gap-8 pt-4 w-full max-w-lg border-t border-[var(--border-color)]">
            {[
              { val: "AI", label: "Powered Matching" },
              { val: "QR", label: "Secure Handover" },
              { val: "⛓️", label: "Blockchain Logged" },
            ].map((s, i) => (
              <div key={i} className="text-center pt-4">
                <div className="text-2xl font-black text-jade-primary">{s.val}</div>
                <div className="text-xs text-sage-secondary mt-1">{s.label}</div>
              </div>
            ))}
          </div>
        </div>

        <div className="absolute bottom-8 left-1/2 -translate-x-1/2 flex flex-col items-center gap-1 text-sage-secondary text-xs font-bold animate-bounce">
          <span>SCROLL</span>
          <span>↓</span>
        </div>
      </section>

      {/* Features */}
      <section className="py-32 px-6">
        <div className="max-w-7xl mx-auto">
          <div className="text-center mb-20 space-y-4">
            <span className="text-jade-primary text-xs font-bold uppercase tracking-widest">What it does</span>
            <h2 className="text-4xl md:text-6xl font-black tracking-tight text-[var(--foreground)]">Built different.</h2>
            <p className="text-sage-secondary max-w-xl mx-auto text-sm leading-relaxed">
              Not just a notice board. A full-stack lost and found ecosystem with AI, blockchain, and real-time everything.
            </p>
          </div>

          <div ref={featuresRef} className="grid md:grid-cols-2 lg:grid-cols-3 gap-5">
            {FEATURES.map((f, i) => (
              <div
                key={i}
                className="feature-card p-8 bg-[var(--card-bg)] border border-[var(--border-color)] rounded-3xl hover:border-jade-primary/50 transition-all hover:-translate-y-1 cursor-default"
              >
                <div className="text-3xl mb-5">{f.icon}</div>
                <h3 className="text-base font-black text-[var(--foreground)] mb-2">{f.title}</h3>
                <p className="text-sage-secondary text-sm leading-relaxed">{f.desc}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* How it works */}
      <section className="py-32 px-6 bg-[var(--card-bg)] border-y border-[var(--border-color)]">
        <div ref={stepsRef} className="max-w-4xl mx-auto">
          <div className="text-center mb-20 space-y-4">
            <span className="text-jade-primary text-xs font-bold uppercase tracking-widest">Simple process</span>
            <h2 className="text-4xl md:text-6xl font-black tracking-tight text-[var(--foreground)]">3 steps. That is it.</h2>
          </div>

          <div className="space-y-6">
            {STEPS.map((s, i) => (
              <div
                key={i}
                className="step-item flex items-start gap-8 p-8 bg-[var(--background)] rounded-3xl border border-[var(--border-color)] hover:border-jade-primary/30 transition-all"
              >
                <span className="text-5xl font-black text-jade-primary/20 leading-none shrink-0 select-none">{s.num}</span>
                <div>
                  <h3 className="text-xl font-black text-[var(--foreground)] mb-2">{s.title}</h3>
                  <p className="text-sage-secondary text-sm leading-relaxed">{s.desc}</p>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Tech Stack */}
      <section className="py-32 px-6">
        <div className="max-w-5xl mx-auto">
          <div className="text-center mb-16 space-y-4">
            <span className="text-jade-primary text-xs font-bold uppercase tracking-widest">Under the hood</span>
            <h2 className="text-4xl md:text-5xl font-black tracking-tight text-[var(--foreground)]">Serious tech stack.</h2>
          </div>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            {TECH.map((t, i) => (
              <div
                key={i}
                className="p-6 bg-[var(--card-bg)] border border-[var(--border-color)] rounded-2xl text-center hover:border-jade-primary/40 hover:bg-jade-primary/5 transition-all"
              >
                <div className="font-black text-[var(--foreground)] text-sm">{t.name}</div>
                <div className="text-sage-secondary text-xs mt-1">{t.role}</div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* FAQ */}
      <section className="py-32 px-6 bg-[var(--card-bg)] border-t border-[var(--border-color)]">
        <div className="max-w-3xl mx-auto space-y-12">
          <div className="text-center">
            <h2 className="text-4xl font-black tracking-tight text-[var(--foreground)]">Questions?</h2>
          </div>
          <div className="space-y-2">
            {FAQS.map((f, i) => (
              <div key={i} className="border border-[var(--border-color)] rounded-2xl overflow-hidden">
                <button
                  onClick={() => setOpenFaq(openFaq === i ? null : i)}
                  className="w-full flex justify-between items-center px-6 py-5 text-left hover:bg-[var(--background)] transition-colors"
                >
                  <span className="font-bold text-sm text-[var(--foreground)] pr-4">{f.q}</span>
                  <span
                    className="text-jade-primary font-black text-xl shrink-0 inline-block transition-transform duration-300"
                    style={{ transform: openFaq === i ? "rotate(45deg)" : "rotate(0deg)" }}
                  >
                    +
                  </span>
                </button>
                {openFaq === i && (
                  <div className="px-6 pb-5 text-sage-secondary text-sm leading-relaxed border-t border-[var(--border-color)] pt-4">
                    {f.a}
                  </div>
                )}
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Final CTA */}
      <section className="py-40 px-6 text-center relative overflow-hidden">
        <div className="absolute inset-0 bg-jade-primary/5 pointer-events-none" />
        <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[400px] h-[400px] bg-jade-primary/10 blur-[100px] rounded-full pointer-events-none" />
        <div className="relative z-10 max-w-3xl mx-auto space-y-10">
          <h2 className="text-5xl md:text-8xl font-black tracking-tighter text-[var(--foreground)] leading-none">
            Never lose<br />
            <span className="text-jade-primary">again.</span>
          </h2>
          <p className="text-sage-secondary text-base">Available now for Bahria University Karachi students.</p>
          <div className="flex flex-col sm:flex-row justify-center gap-4">
            <a
              href="https://trace-self.vercel.app"
              target="_blank"
              rel="noreferrer"
              className="px-10 py-5 bg-jade-primary text-white rounded-2xl font-black text-base hover:opacity-90 transition-all shadow-lg shadow-jade-primary/20 active:scale-95"
            >
              Try Now — Web Version
            </a>
            <a
              href="/trace.apk"
              download
              className="px-10 py-5 border border-[var(--border-color)] bg-[var(--card-bg)] text-[var(--foreground)] rounded-2xl font-black text-base hover:border-jade-primary transition-all active:scale-95"
            >
              Download Android APK
            </a>
          </div>
        </div>
      </section>

    </div>
  );
}
