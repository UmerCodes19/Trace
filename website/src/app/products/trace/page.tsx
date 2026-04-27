"use client";

import { motion, useScroll, useTransform, useSpring, useMotionValue } from "framer-motion";
import { ArrowLeft, ArrowRight, MapIcon, Search, Shield, Zap, Activity, Users, Radio, Navigation, Bell, Globe, Terminal, Cpu, Database, ChevronRight, Share2, Target, Link as LinkIcon, Layout, Fingerprint, QrCode, Lock, Server, Cpu as CpuIcon, Download, Smartphone, Laptop, Layers, Play, HelpCircle, CheckCircle2, ChevronDown } from "lucide-react";
import Link from "next/link";
import { useRef, useEffect, useState } from "react";

// Trace Mesh Background
function SimpleMesh() {
   return (
      <div className="absolute inset-0 overflow-hidden pointer-events-none opacity-10">
         <div className="absolute inset-0 bg-[url('https://www.transparenttextures.com/patterns/carbon-fibre.png')] opacity-20" />
         <svg className="w-full h-full">
            <pattern id="grid" width="40" height="40" patternUnits="userSpaceOnUse">
               <path d="M 40 0 L 0 0 0 40" fill="none" stroke="currentColor" strokeWidth="0.5" className="text-[var(--border-color)]" />
            </pattern>
            <rect width="100%" height="100%" fill="url(#grid)" />
         </svg>
      </div>
   );
}

// Simple FAQ Component
function SimpleFAQItem({ question, answer }: { question: string, answer: string }) {
   const [isOpen, setIsOpen] = useState(false);
   return (
      <div className="border-b border-[var(--border-color)] py-6">
         <button onClick={() => setIsOpen(!isOpen)} className="w-full flex justify-between items-center text-left group">
            <span className="text-xs md:text-sm font-bold uppercase tracking-widest group-hover:text-[#E0874A] transition-colors pr-8">{question}</span>
            <ChevronDown className={`w-4 h-4 text-neutral-600 transition-transform shrink-0 ${isOpen ? 'rotate-180' : ''}`} />
         </button>
         {isOpen && (
            <motion.p initial={{ opacity: 0, height: 0 }} animate={{ opacity: 1, height: 'auto' }} className="mt-4 text-neutral-500 text-[10px] uppercase tracking-widest leading-relaxed">
               {answer}
            </motion.p>
         )}
      </div>
   );
}

export default function TraceProductPage() {
   const containerRef = useRef<HTMLDivElement>(null);
   const { scrollYProgress } = useScroll({
      target: containerRef,
      offset: ["start start", "end end"]
   });

   const heroOpacity = useTransform(scrollYProgress, [0, 0.1], [1, 0]);
   const heroScale = useTransform(scrollYProgress, [0, 0.1], [1, 0.95]);

   return (
      <div ref={containerRef} className="min-h-screen bg-[var(--background)] text-[var(--foreground)] selection:bg-[#E0874A]/20 overflow-x-hidden font-sans transition-colors duration-1000">

         {/* Product Navigation - Below Global Navbar */}
         <div className="relative pt-16 z-40 px-4 md:px-10">
            <div className="max-w-7xl mx-auto h-16 flex justify-between items-center border-b border-[var(--border-color)]">
               <Link href="/" className="group flex items-center gap-2 md:gap-4 text-[9px] md:text-[10px] uppercase tracking-[0.2em] md:tracking-[0.4em] font-mono text-neutral-500 hover:text-[var(--foreground)] transition-colors">
                  <ArrowLeft className="w-4 h-4 group-hover:-translate-x-1 transition-transform" /> Back
               </Link>
               <div className="px-3 md:px-4 py-2 bg-[var(--card-bg)]/60 backdrop-blur-md border border-[var(--border-color)] text-[8px] md:text-[9px] uppercase tracking-[0.2em] md:tracking-[0.4em] font-mono truncate max-w-[200px] md:max-w-none">
                  Trace // Lost & Found App
               </div>
            </div>
         </div>

         {/* Hero Section - The Simple Solution */}
         <section className="relative min-h-[calc(100vh-8rem)] flex flex-col items-center justify-center text-center px-6 overflow-hidden py-12 md:py-0">
            <SimpleMesh />

            <motion.div style={{ opacity: heroOpacity, scale: heroScale }} className="relative z-10 space-y-8 md:space-y-12 max-w-6xl w-full">
               <div className="space-y-4 md:space-y-6">
                  <motion.div
                     initial={{ opacity: 0, y: 10 }}
                     animate={{ opacity: 1, y: 0 }}
                     className="flex items-center justify-center gap-2 md:gap-4"
                  >
                     <div className="w-6 md:w-8 h-px bg-[#E0874A]/30" />
                     <span className="text-[8px] md:text-[10px] font-mono text-[#E0874A] uppercase tracking-[0.4em] md:tracking-[0.8em]">Find Your Lost Items Faster</span>
                     <div className="w-6 md:w-8 h-px bg-[#E0874A]/30" />
                  </motion.div>

                  <motion.h1
                     initial={{ opacity: 0, y: 20 }}
                     animate={{ opacity: 1, y: 0 }}
                     transition={{ delay: 0.1 }}
                     className="text-6xl sm:text-8xl md:text-[11rem] font-black tracking-tighter uppercase leading-none"
                  >
                     Trace<span className="text-[#E0874A]">.</span>
                  </motion.h1>
               </div>

               <motion.div
                  initial={{ opacity: 0 }}
                  animate={{ opacity: 1 }}
                  transition={{ delay: 0.3 }}
                  className="flex flex-wrap justify-center gap-2 md:gap-3 max-w-3xl mx-auto px-4"
               >
                  {["Smart AI", "Cloud Storage", "Easy Matching", "Secure Claims", "Notifications"].map(tech => (
                     <span key={tech} className="px-3 md:px-4 py-1 md:py-1.5 border border-[var(--border-color)] bg-[var(--card-bg)] text-[8px] md:text-[9px] font-mono text-neutral-500 uppercase tracking-widest whitespace-nowrap">
                        {tech}
                     </span>
                  ))}
               </motion.div>

               <motion.p
                  initial={{ opacity: 0 }}
                  animate={{ opacity: 1 }}
                  transition={{ delay: 0.4 }}
                  className="text-neutral-500 text-[9px] md:text-xs max-w-2xl mx-auto uppercase tracking-[0.2em] md:tracking-[0.4em] leading-loose font-mono px-4"
               >
                  Forget physical help desks. Trace is a simple app that helps you find your lost things by connecting you with people who found them.
               </motion.p>

               <motion.div
                  initial={{ opacity: 0, y: 20 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ delay: 0.5 }}
                  className="flex flex-col sm:flex-row justify-center gap-4 md:gap-6 pt-6 md:pt-8 px-6 md:px-0"
               >
                  <button className="btn-premium px-8 md:px-10 group flex items-center justify-center gap-4 bg-[#E0874A] text-white border-none w-full sm:w-auto">
                     <Download className="w-4 h-4" /> Download APK <span className="text-[8px] opacity-50 font-mono">v4.0.2</span>
                  </button>
                  <button className="btn-outline px-8 md:px-10 flex items-center justify-center gap-4 w-full sm:w-auto">
                     <Smartphone className="w-4 h-4" /> Get on iPhone
                  </button>
               </motion.div>
            </motion.div>

            {/* Decorative Radar Ring */}
            <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[300px] md:w-[600px] h-[300px] md:h-[600px] border border-[#E0874A]/5 rounded-full pointer-events-none animate-ping" />
         </section>

         {/* Video Demo Placeholder */}
         <section className="py-24 md:py-32 px-4 md:px-6 bg-black relative overflow-hidden">
            <div className="max-w-7xl mx-auto aspect-video bg-[var(--card-bg)] border border-[var(--border-color)] pixel-corners flex flex-col items-center justify-center group cursor-pointer relative">
               <div className="w-16 h-16 md:w-24 md:h-24 rounded-full bg-[#E0874A]/10 border border-[#E0874A]/30 flex items-center justify-center group-hover:scale-110 transition-transform relative z-10">
                  <Play className="w-6 h-6 md:w-8 md:h-8 text-[#E0874A]" />
               </div>
               <span className="mt-6 md:mt-8 text-[8px] md:text-[10px] font-mono text-neutral-600 uppercase tracking-[0.4em] md:tracking-[0.8em] relative z-10">Watch App Demo</span>
               <div className="absolute inset-0 bg-[url('https://images.unsplash.com/photo-1451187580459-43490279c0fa?auto=format&fit=crop&q=80')] bg-cover bg-center opacity-5 group-hover:opacity-10 transition-opacity" />
            </div>
         </section>

         {/* Problem & Solution - Easy Language */}
         <section className="py-24 md:py-64 px-6 border-y border-[var(--border-color)] bg-[var(--card-bg)]/20 relative overflow-hidden">
            <div className="max-w-7xl mx-auto grid lg:grid-cols-2 gap-16 md:gap-24 items-center">
               <div className="space-y-8 md:space-y-12">
                  <div className="space-y-4 text-center lg:text-left">
                     <span className="text-xs md:text-sm font-mono text-[#E0874A] uppercase tracking-[0.6em]">The Problem</span>
                     <h2 className="text-4xl md:text-7xl font-bold tracking-tighter uppercase leading-[0.9]">Stop Losing <br />Your Stuff.</h2>
                  </div>
                  <div className="space-y-6 md:space-y-8 text-neutral-500 font-mono text-[10px] md:text-[11px] uppercase tracking-widest leading-loose max-w-md mx-auto lg:mx-0">
                     <p>1. No easy way to report lost items online.</p>
                     <p>2. Hard to match items when descriptions are different.</p>
                     <p>3. No way to prove that you are the real owner.</p>
                     <p>4. You don't get alerts when someone finds your item.</p>
                  </div>
               </div>

               <div className="relative group px-4 md:px-0">
                  <div className="absolute inset-0 bg-[#E0874A]/5 blur-[100px] opacity-0 group-hover:opacity-40 transition-opacity" />
                  <div className="p-8 md:p-12 border border-[var(--border-color)] bg-[var(--background)] pixel-corners relative overflow-hidden">
                     <div className="space-y-4 font-mono text-[8px] md:text-[9px] uppercase tracking-widest text-neutral-500">
                        <div>&gt; Checking...</div>
                        <div>&gt; Result: Most items are never found.</div>
                        <div>&gt; Reason: Poor communication.</div>
                        <div className="text-[#E0874A]">&gt; Solution: Use Trace App.</div>
                     </div>
                  </div>
               </div>
            </div>
         </section>

         {/* Main Features - Easy Language */}
         <section className="py-24 md:py-64 px-6 max-w-7xl mx-auto">
            <div className="mb-16 md:mb-48 text-center space-y-6">
               <h3 className="text-xs md:text-sm font-mono text-neutral-700 uppercase tracking-[0.6em] md:tracking-[0.8em]">Core Features</h3>
               <h4 className="text-4xl md:text-7xl font-bold tracking-tighter uppercase">How it Helps.</h4>
            </div>

            <div className="grid md:grid-cols-3 gap-8 md:gap-12">
               {[
                  {
                     icon: Server,
                     title: "Cloud Backup",
                     desc: "All item reports are saved safely online so everyone can see them instantly.",
                     tag: "Secure & Fast"
                  },
                  {
                     icon: Cpu,
                     title: "Smart Matching",
                     desc: "Our AI helps find matches even if the words used to describe items are different.",
                     tag: "AI Powered"
                  },
                  {
                     icon: Lock,
                     title: "Safe Claims",
                     desc: "A secure way to prove you own the item before you pick it up.",
                     tag: "Verified Ownership"
                  }
               ].map((node, i) => (
                  <motion.div
                     key={i}
                     whileHover={{ y: -10 }}
                     className="p-8 md:p-10 border border-[var(--border-color)] bg-[var(--card-bg)]/40 pixel-corners relative group overflow-hidden"
                  >
                     <div className="absolute inset-0 bg-gradient-to-br from-[#E0874A]/5 to-transparent opacity-0 group-hover:opacity-100 transition-opacity" />
                     <node.icon className="w-8 h-8 text-[#E0874A] mb-8 md:mb-12" />
                     <h5 className="text-lg md:text-xl font-bold uppercase tracking-tighter mb-4 text-[var(--foreground)]">{node.title}</h5>
                     <p className="text-neutral-500 text-[9px] uppercase tracking-widest leading-loose mb-8 md:mb-10">{node.desc}</p>
                     <div className="text-[8px] font-mono text-neutral-700 uppercase tracking-widest">{node.tag}</div>
                  </motion.div>
               ))}
            </div>
         </section>

         {/* Step by Step Guide */}
         <section className="py-24 md:py-64 px-6 border-t border-[var(--border-color)] relative">
            <div className="max-w-7xl mx-auto grid lg:grid-cols-2 gap-16 md:gap-24 items-center">
               <div className="space-y-12">
                  <div className="space-y-4 text-center lg:text-left">
                     <span className="text-xs md:text-sm font-mono text-[#E0874A] uppercase tracking-[0.6em]">Tutorial</span>
                     <h2 className="text-4xl md:text-7xl font-bold tracking-tighter uppercase leading-[0.9]">Easy To Use.</h2>
                  </div>
                  <div className="space-y-10 md:space-y-12 max-w-md mx-auto lg:mx-0">
                     {[
                        { step: "01", title: "Report It", desc: "Take a photo and write a simple description of what you lost or found." },
                        { step: "02", title: "Smart Search", desc: "The app automatically checks for matches across the entire network." },
                        { step: "03", title: "Confirm", desc: "Prove that the item is yours through a simple verification process." },
                        { step: "04", title: "Pick Up", desc: "Collect your item using a secure QR code for safety." }
                     ].map((item, i) => (
                        <div key={i} className="flex gap-6 md:gap-8 group">
                           <span className="text-xl md:text-2xl font-black text-neutral-800 group-hover:text-[#E0874A] transition-colors">{item.step}</span>
                           <div className="space-y-2">
                              <h5 className="text-[12px] md:text-sm font-bold uppercase tracking-widest">{item.title}</h5>
                              <p className="text-neutral-500 text-[9px] md:text-[10px] uppercase tracking-widest leading-loose">{item.desc}</p>
                           </div>
                        </div>
                     ))}
                  </div>
               </div>

               <div className="aspect-square bg-[var(--card-bg)] border border-[var(--border-color)] pixel-corners relative overflow-hidden max-w-md mx-auto w-full">
                  <div className="absolute inset-0 bg-[url('https://images.unsplash.com/photo-1551288049-bebda4e38f71?auto=format&fit=crop&q=80')] bg-cover bg-center opacity-10" />
                  <div className="absolute inset-0 flex items-center justify-center">
                     <div className="p-6 md:p-8 bg-black/60 backdrop-blur-xl border border-white/5 max-w-[240px] md:max-w-[280px]">
                        <Activity className="w-6 h-6 md:w-8 md:h-8 text-[#E0874A] mb-4 md:mb-6 animate-pulse" />
                        <div className="space-y-4">
                           <div className="h-2 w-full bg-white/10 rounded-full" />
                           <div className="h-2 w-2/3 bg-white/5 rounded-full" />
                        </div>
                     </div>
                  </div>
               </div>
            </div>
         </section>

         {/* Support FAQ */}
         <section className="py-24 md:py-64 px-6 bg-[var(--card-bg)]/20 border-y border-[var(--border-color)]">
            <div className="max-w-4xl mx-auto space-y-16 md:space-y-20">
               <div className="text-center space-y-4">
                  <HelpCircle className="w-8 h-8 text-[#E0874A] mx-auto" />
                  <h3 className="text-3xl md:text-6xl font-bold tracking-tighter uppercase">Common Questions.</h3>
               </div>
               <div className="space-y-2 px-2 md:px-0">
                  <SimpleFAQItem
                     question="How does the smart matching work?"
                     answer="Our app uses smart AI to understand what you're looking for. It doesn't just look at keywords—it understands the meaning behind your description to find better matches."
                  />
                  <SimpleFAQItem
                     question="Is my identity safe?"
                     answer="Yes. We use secure technology to make sure your personal info is hidden until a match is confirmed and you're ready to collect your item."
                  />
                  <SimpleFAQItem
                     question="How do I pick up my item?"
                     answer="Once a match is confirmed, you'll get a unique QR code. You just show that code when picking up the item to prove you're the owner."
                  />
                  <SimpleFAQItem
                     question="Is it free to use?"
                     answer="Yes, the app is free for students and community members to report and find items."
                  />
               </div>
            </div>
         </section>

         {/* CTA Footer */}
         <section className="py-24 md:py-64 px-6 text-center">
            <div className="max-w-4xl mx-auto space-y-12 md:space-y-16">
               <h2 className="text-4xl md:text-[6rem] font-black tracking-tighter uppercase leading-none">Find Your <span className="text-[#E0874A]">Stuff</span> Now.</h2>
               <div className="flex flex-col sm:flex-row justify-center gap-4 md:gap-8 px-6 md:px-0">
                  <button className="btn-premium px-10 md:px-12 group flex items-center justify-center gap-4 bg-[#E0874A] text-white border-none w-full sm:w-auto">
                     <Download className="w-4 h-4" /> Download App <ArrowRight className="w-4 h-4 group-hover:translate-x-2 transition-transform" />
                  </button>
                  <Link href="/" className="btn-outline px-10 md:px-12 flex justify-center w-full sm:w-auto">Back to Site</Link>
               </div>
            </div>
         </section>

      </div>
   );
}
