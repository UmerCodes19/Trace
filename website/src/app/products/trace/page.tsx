"use client";

import { motion, useScroll, useTransform } from "framer-motion";
import { ArrowLeft, Map, Search, ShieldCheck, Smartphone, Download, HelpCircle, ChevronDown, Camera, CheckCircle, Star } from "lucide-react";
import Link from "next/link";
import { useRef, useState } from "react";

function LuxuryGridBackground() {
   return (
      <div className="absolute inset-0 overflow-hidden pointer-events-none opacity-20">
         <div className="absolute inset-0 bg-[radial-gradient(circle_at_center,_var(--color-jade-primary)_0%,_transparent_80%)] opacity-20 mix-blend-overlay" />
         <svg className="w-full h-full">
            <pattern id="trace-grid" width="60" height="60" patternUnits="userSpaceOnUse">
               <path d="M 60 0 L 0 0 0 60" fill="none" stroke="currentColor" strokeWidth="0.5" className="text-jade-primary opacity-30" />
               <circle cx="0" cy="0" r="1" fill="currentColor" className="text-jade-primary opacity-50" />
            </pattern>
            <rect width="100%" height="100%" fill="url(#trace-grid)" />
         </svg>
      </div>
   );
}

function TraceFAQItem({ question, answer }: { question: string, answer: string }) {
   const [isOpen, setIsOpen] = useState(false);
   return (
      <div className="border-b border-[var(--border-color)] py-6 transition-colors">
         <button onClick={() => setIsOpen(!isOpen)} className="w-full flex justify-between items-center text-left group">
            <span className="text-sm md:text-base font-bold group-hover:text-jade-primary transition-colors pr-8 text-[var(--foreground)]">{question}</span>
            <ChevronDown className={`w-4 h-4 text-sage-secondary transition-transform shrink-0 ${isOpen ? 'rotate-180 text-jade-primary' : ''}`} />
         </button>
         {isOpen && (
            <motion.div 
              initial={{ opacity: 0, y: -10 }} 
              animate={{ opacity: 1, y: 0 }} 
              className="mt-4 text-sage-secondary text-sm leading-relaxed max-w-2xl"
            >
               {answer}
            </motion.div>
         )}
      </div>
   );
}

export default function TraceProductPage() {
   const containerRef = useRef<HTMLDivElement>(null);
   const { scrollYProgress } = useScroll({ target: containerRef, offset: ["start start", "end end"] });
   const heroOpacity = useTransform(scrollYProgress, [0, 0.15], [1, 0]);
   const heroY = useTransform(scrollYProgress, [0, 0.15], [0, -20]);

   return (
      <div ref={containerRef} className="min-h-screen bg-[var(--background)] text-[var(--foreground)] transition-colors selection:bg-jade-primary/30 overflow-x-hidden font-sans">
         
         {/* Top Context Nav */}
         <div className="relative pt-20 z-40 px-4 md:px-10">
            <div className="max-w-7xl mx-auto h-16 flex justify-between items-center border-b border-[var(--border-color)]">
               <Link href="/" className="group flex items-center gap-2 text-xs font-bold text-sage-secondary hover:text-jade-primary transition-colors">
                  <ArrowLeft className="w-4 h-4 group-hover:-translate-x-1 transition-transform" /> Home
               </Link>
               <div className="px-4 py-1.5 bg-[var(--card-bg)] border border-[var(--border-color)] text-[10px] font-bold text-jade-primary rounded-full uppercase tracking-wider shadow-sm">
                  Available for Android
               </div>
            </div>
         </div>

         {/* Premium Hero Section */}
         <section className="relative min-h-[calc(100vh-8rem)] flex flex-col items-center justify-center text-center px-6 overflow-hidden">
            <LuxuryGridBackground />
            
            {/* Soft Ambient Glow */}
            <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[600px] h-[600px] bg-jade-primary/10 blur-[140px] rounded-full pointer-events-none" />

            <motion.div style={{ opacity: heroOpacity, y: heroY }} className="relative z-10 space-y-8 max-w-4xl">
               <div className="space-y-6 flex flex-col items-center">
                  <motion.div 
                     initial={{ scale: 0.9, opacity: 0 }} 
                     animate={{ scale: 1, opacity: 1 }}
                     className="w-20 h-20 bg-[var(--card-bg)] border-2 border-[var(--border-color)] p-2 rounded-2xl shadow-xl mb-4"
                  >
                     <img src="/images/branding/trace_logo.png" alt="Trace App Logo" className="w-full h-full object-contain" />
                  </motion.div>

                  <motion.h1 
                     initial={{ opacity: 0, y: 30 }} 
                     animate={{ opacity: 1, y: 0 }} 
                     className="text-5xl md:text-8xl font-black tracking-tight leading-[0.9] text-[var(--foreground)]"
                  >
                     Trace<span className="text-jade-primary">.</span>
                  </motion.h1>
                  <p className="text-lg md:text-xl font-medium text-sage-secondary max-w-2xl mx-auto">
                     The modern lost and found app for your university campus. Find missing items instantly.
                  </p>
               </div>

               <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} transition={{ delay: 0.2 }} className="flex flex-wrap justify-center gap-3">
                  {["Visual Search", "Campus Maps", "Safety Rewards", "Realtime Chat"].map(f => (
                     <span key={f} className="px-4 py-1.5 border border-[var(--border-color)] bg-[var(--card-bg)] text-xs font-bold text-[var(--foreground)] rounded-full shadow-sm">
                        {f}
                     </span>
                  ))}
               </motion.div>

               <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.3 }} className="flex flex-col sm:flex-row justify-center gap-4 pt-4">
                  <a href="#" className="px-8 py-4 bg-jade-primary text-white font-bold text-sm rounded-xl flex items-center justify-center gap-3 hover:bg-jade-deep transition-all shadow-lg shadow-jade-primary/20 active:scale-95">
                     <Download className="w-5 h-5" /> Get the App
                  </a>
                  <a href="#" className="px-8 py-4 border border-[var(--border-color)] bg-[var(--card-bg)] text-[var(--foreground)] font-bold text-sm rounded-xl flex items-center justify-center gap-3 hover:border-jade-primary transition-all active:scale-95">
                     <Smartphone className="w-5 h-5" /> View Screens
                  </a>
               </motion.div>
            </motion.div>
         </section>

         {/* Problem Statement Section */}
         <section className="py-24 px-6 bg-[var(--card-bg)] border-y border-[var(--border-color)]">
            <div className="max-w-5xl mx-auto grid md:grid-cols-2 gap-12 items-center">
               <div className="space-y-6">
                  <h2 className="text-3xl md:text-4xl font-black tracking-tight text-[var(--foreground)]">Why we built Trace</h2>
                  <p className="text-sage-secondary font-medium leading-relaxed text-base">
                     Losing something important on campus is stressful. Posting notices on social media or walking between buildings usually leads nowhere. 
                  </p>
                  <p className="text-sage-secondary font-medium leading-relaxed text-base">
                     Trace was created to solve this. It's one centralized place to report lost belongings, track found items, and securely connect users for a smooth return.
                  </p>
               </div>
               <div className="grid grid-cols-1 gap-4">
                  {[
                     "No more scrolling through messy social media groups.",
                     "Real-time push notifications when your item is found.",
                     "Secure reward systems that prevent false claims."
                  ].map((item, i) => (
                     <div key={i} className="flex items-center gap-4 p-5 bg-[var(--background)] rounded-2xl border border-[var(--border-color)] shadow-sm">
                        <div className="w-8 h-8 bg-jade-primary/10 rounded-full flex items-center justify-center shrink-0">
                           <CheckCircle className="w-5 h-5 text-jade-primary" />
                        </div>
                        <span className="font-bold text-sm text-[var(--foreground)]">{item}</span>
                     </div>
                  ))}
               </div>
            </div>
         </section>

         {/* Product Mockup Preview */}
         <section className="py-24 px-6 relative overflow-hidden">
            <div className="max-w-6xl mx-auto aspect-video bg-jade-primary/5 rounded-3xl border border-[var(--border-color)] flex items-center justify-center relative overflow-hidden shadow-2xl group">
               <div className="absolute inset-0 bg-[url('/images/branding/trace_main_jade.png')] bg-cover bg-center opacity-60 transition-transform duration-1000 group-hover:scale-105" />
               <div className="absolute inset-0 bg-gradient-to-t from-[var(--background)] via-transparent to-[var(--background)]/20" />
               <div className="relative z-10 flex flex-col items-center text-center gap-4">
                  <div className="w-20 h-20 rounded-full bg-white/20 backdrop-blur-md flex items-center justify-center border border-white/30 shadow-xl text-white">
                     <Smartphone className="w-8 h-8" />
                  </div>
                  <span className="text-lg font-bold text-white bg-black/40 px-6 py-2 rounded-full backdrop-blur-sm">Visual Preview</span>
               </div>
            </div>
         </section>

         {/* User Flow - How it works */}
         <section className="py-32 px-6 max-w-7xl mx-auto">
            <div className="text-center mb-20 space-y-4">
               <h3 className="text-sm font-bold text-jade-primary uppercase tracking-widest">Simple 3-Step Flow</h3>
               <h2 className="text-4xl md:text-5xl font-black tracking-tight text-[var(--foreground)]">How Trace Works.</h2>
            </div>

            <div className="grid md:grid-cols-3 gap-8 relative">
               {/* Connector Line hidden on mobile */}
               <div className="hidden md:block absolute top-14 left-[15%] right-[15%] h-0.5 bg-[var(--border-color)] border-t border-dashed border-sage-secondary/30 -z-10" />
               
               {[
                  { icon: Camera, title: "1. Snap & Post", desc: "Found or lost something? Just snap a quick photo and post it in 30 seconds." },
                  { icon: Map, title: "2. Map the Spot", desc: "Use internal floor maps to pin the exact location you found or lost the item." },
                  { icon: ShieldCheck, title: "3. Secure Return", desc: "Chat securely inside the app to coordinate handover and scan QR to finish." }
               ].map((step, i) => (
                  <div key={i} className="flex flex-col items-center text-center space-y-6 bg-[var(--card-bg)] p-10 rounded-3xl border border-[var(--border-color)] shadow-md hover:border-jade-primary/30 transition-all">
                     <div className="w-16 h-16 bg-jade-primary text-white rounded-2xl flex items-center justify-center shadow-lg shadow-jade-primary/20">
                        <step.icon className="w-8 h-8" />
                     </div>
                     <h4 className="text-xl font-bold text-[var(--foreground)]">{step.title}</h4>
                     <p className="text-sage-secondary text-sm font-medium leading-relaxed">{step.desc}</p>
                  </div>
               ))}
            </div>
         </section>

         {/* Visual Tech Section (Map preview) */}
         <section className="py-24 px-6 bg-[var(--card-bg)] border-y border-[var(--border-color)]">
            <div className="max-w-7xl mx-auto grid lg:grid-cols-2 gap-16 items-center">
               <div className="space-y-8 order-2 lg:order-1">
                  <div className="space-y-4">
                     <span className="text-jade-primary font-bold text-sm uppercase tracking-wider">Internal Navigation</span>
                     <h2 className="text-4xl md:text-5xl font-black tracking-tight text-[var(--foreground)] leading-[1.1]">Never get lost looking for your stuff.</h2>
                     <p className="text-sage-secondary text-base font-medium leading-relaxed">
                        Finding a specific floor or room can be confusing. Trace includes detailed floorplans of the building so you can drop a pin exactly where you stand.
                     </p>
                  </div>
                  
                  <ul className="space-y-4">
                     {[
                        "Multi-floor navigation selector.",
                        "Precise indoor room tags.",
                        "Real-time route calculation on arrival."
                     ].map((text, idx) => (
                        <li key={idx} className="flex items-center gap-3 text-sm font-bold text-[var(--foreground)]">
                           <Star className="w-4 h-4 text-jade-primary" fill="currentColor" /> {text}
                        </li>
                     ))}
                  </ul>
               </div>

               {/* The Jade Map Image Container */}
               <div className="aspect-square rounded-3xl border border-[var(--border-color)] relative shadow-2xl overflow-hidden bg-[var(--background)] order-1 lg:order-2">
                  <div className="absolute inset-0 bg-[url('/images/branding/trace_map_jade.png')] bg-cover bg-center opacity-80 group-hover:scale-105 transition-transform duration-[2s]" />
                  <div className="absolute inset-0 bg-gradient-to-b from-transparent to-[var(--background)]/60" />
                  <div className="absolute bottom-6 left-6 right-6 bg-[var(--card-bg)]/90 backdrop-blur-md border border-[var(--border-color)] p-5 rounded-2xl flex items-center justify-between shadow-xl">
                     <div className="flex items-center gap-3">
                        <div className="w-3 h-3 bg-jade-primary rounded-full animate-pulse" />
                        <span className="font-bold text-sm text-[var(--foreground)]">Campus Live Map</span>
                     </div>
                     <div className="text-xs font-bold text-jade-primary">Ready</div>
                  </div>
               </div>
            </div>
         </section>

         {/* Simplified FAQ */}
         <section className="py-32 px-6">
            <div className="max-w-3xl mx-auto space-y-12">
               <div className="text-center">
                  <HelpCircle className="w-8 h-8 text-jade-primary mx-auto mb-4" />
                  <h3 className="text-3xl md:text-4xl font-black tracking-tight text-[var(--foreground)]">Got Questions?</h3>
               </div>
               <div className="px-2">
                  <TraceFAQItem 
                     question="How do I prove an item belongs to me?"
                     answer="The original owner must describe structural details or unique keys. Once coordinated, the finder generates a secure QR code that is verified on physical exchange."
                  />
                  <TraceFAQItem 
                     question="Can I reward the finder?"
                     answer="Yes! Trace includes a gesture and ranking system to reward honest community users for helping returns."
                  />
                  <TraceFAQItem 
                     question="Is campus mapping accurate?"
                     answer="We build precise, layered structural floorplans for every university department covered by the system."
                  />
               </div>
            </div>
         </section>

         {/* Final CTA */}
         <section className="py-32 px-6 text-center bg-jade-primary/5 border-t border-[var(--border-color)]">
            <div className="max-w-3xl mx-auto space-y-10">
               <h2 className="text-4xl md:text-7xl font-black tracking-tight text-[var(--foreground)] leading-tight">Start tracing <br /><span className="text-jade-primary">today.</span></h2>
               <div className="flex flex-col sm:flex-row justify-center gap-4">
                  <a href="#" className="px-10 py-5 bg-jade-primary text-white rounded-2xl font-bold text-base hover:bg-jade-deep transition-all shadow-lg shadow-jade-primary/20 active:scale-95">
                     Download for Android
                  </a>
                  <Link href="/" className="px-10 py-5 border border-[var(--border-color)] bg-[var(--card-bg)] text-[var(--foreground)] rounded-2xl font-bold text-base hover:border-jade-primary transition-all active:scale-95">
                     Back to Website
                  </Link>
               </div>
            </div>
         </section>

      </div>
   );
}

