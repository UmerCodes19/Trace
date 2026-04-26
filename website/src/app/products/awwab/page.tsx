"use client";

import { motion, useScroll, useTransform, useSpring, useMotionValue } from "framer-motion";
import { ArrowLeft, Moon, Sun, Heart, Sparkles, Wind, Leaf, Compass, Eye, Cloud, Coffee, BookOpen, Music, Shield, ArrowRight, Stars, Droplets, MapPin, Volume2, Calendar, Layout, Globe, Bell, Fingerprint, Search, Download, Smartphone, Play, HelpCircle, ChevronDown, CheckCircle2 } from "lucide-react";
import Link from "next/link";
import { useRef, useEffect, useState } from "react";

// Islamic Background Pattern
function IslamicPattern() {
  return (
    <div className="absolute inset-0 overflow-hidden pointer-events-none opacity-20 transition-colors duration-1000">
      <div className="absolute top-[-10%] left-[-10%] w-[80%] md:w-[60%] h-[60%] bg-[#E8EEDF]/40 dark:bg-[#78866B]/10 blur-[80px] md:blur-[120px] rounded-full animate-pulse" />
      <div className="absolute bottom-[-10%] right-[-10%] w-[70%] md:w-[50%] h-[50%] bg-[#D4AF37]/5 blur-[60px] md:blur-[100px] rounded-full" />
      <div className="absolute inset-0 bg-[url('https://www.transparenttextures.com/patterns/natural-paper.png')] opacity-10" />
    </div>
  );
}

// Simple Section Card
function FeatureCard({ icon: Icon, title, desc, delay }: { icon: any, title: string, desc: string, delay: number }) {
  return (
    <motion.div 
      initial={{ opacity: 0, y: 20 }}
      whileInView={{ opacity: 1, y: 0 }}
      transition={{ delay }}
      className="p-8 md:p-10 bg-[var(--card-bg)]/40 backdrop-blur-3xl border border-[var(--border-color)] group hover:border-[#D4AF37]/30 transition-all h-full"
    >
       <div className="w-10 h-10 md:w-12 md:h-12 bg-[#78866B]/10 flex items-center justify-center mb-6 md:mb-8 rounded-full group-hover:scale-110 transition-transform">
          <Icon className="w-4 h-4 md:w-5 md:h-5 text-[#78866B]" />
       </div>
       <h4 className="text-lg md:text-xl font-serif text-[#78866B] mb-4">{title}</h4>
       <p className="text-neutral-500 text-[10px] md:text-[11px] uppercase tracking-widest leading-relaxed">{desc}</p>
    </motion.div>
  );
}

// FAQ Component using simple language
function SimpleFAQItem({ question, answer }: { question: string, answer: string }) {
  const [isOpen, setIsOpen] = useState(false);
  return (
    <div className="border-b border-[#D4AF37]/10 py-6">
      <button onClick={() => setIsOpen(!isOpen)} className="w-full flex justify-between items-center text-left group">
        <span className="text-xs md:text-sm font-serif text-[#78866B] italic group-hover:text-[#D4AF37] transition-colors pr-8">{question}</span>
        <ChevronDown className={`w-4 h-4 text-neutral-400 transition-transform shrink-0 ${isOpen ? 'rotate-180' : ''}`} />
      </button>
      {isOpen && (
        <motion.p initial={{ opacity: 0, height: 0 }} animate={{ opacity: 1, height: 'auto' }} className="mt-4 text-neutral-400 text-[10px] md:text-xs italic leading-relaxed">
          {answer}
        </motion.p>
      )}
    </div>
  );
}

export default function AwwabProductPage() {
  const containerRef = useRef<HTMLDivElement>(null);
  const { scrollYProgress } = useScroll({
    target: containerRef,
    offset: ["start start", "end end"]
  });

  const heroOpacity = useTransform(scrollYProgress, [0, 0.1], [1, 0]);
  const heroScale = useTransform(scrollYProgress, [0, 0.1], [1, 0.95]);

  return (
    <div ref={containerRef} className="min-h-screen bg-[var(--background)] text-[var(--foreground)] selection:bg-[#D4AF37]/10 overflow-x-hidden font-sans transition-colors duration-1000">
      
      {/* Product Navigation - Below Global Navbar */}
      <div className="relative pt-16 z-40 px-4 md:px-10">
        <div className="max-w-7xl mx-auto h-16 flex justify-between items-center border-b border-[var(--border-color)]">
          <Link href="/" className="group flex items-center gap-2 md:gap-4 text-[9px] md:text-[10px] uppercase tracking-[0.2em] md:tracking-[0.4em] font-medium text-neutral-400 hover:text-[#78866B] transition-colors">
             <ArrowLeft className="w-4 h-4 group-hover:-translate-x-1 transition-transform" /> Back
          </Link>
          <div className="px-3 md:px-5 py-2 bg-[var(--card-bg)]/60 backdrop-blur-md border border-[var(--border-color)] shadow-sm text-[8px] md:text-[9px] uppercase tracking-[0.2em] md:tracking-[0.4em] font-medium text-[#78866B] truncate max-w-[200px] md:max-w-none">
             Awwab // Prayer App
          </div>
        </div>
      </div>

      {/* Hero Section - The Prayer Companion */}
      <section className="relative min-h-[calc(100vh-8rem)] flex flex-col items-center justify-center text-center px-6 overflow-hidden py-12 md:py-0">
        <IslamicPattern />
        
        <motion.div style={{ opacity: heroOpacity, scale: heroScale }} className="relative z-10 space-y-8 md:space-y-12">
           <div className="space-y-4 md:space-y-6">
              <motion.div 
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                className="flex items-center justify-center gap-2 md:gap-4"
              >
                 <div className="w-8 md:w-12 h-px bg-[#D4AF37]/30" />
                 <span className="text-[8px] md:text-[10px] font-medium text-[#D4AF37] uppercase tracking-[0.4em] md:tracking-[1em]">Smart Namaz App</span>
                 <div className="w-8 md:w-12 h-px bg-[#D4AF37]/30" />
              </motion.div>
              
              <motion.h1 
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                className="text-6xl sm:text-8xl md:text-[11rem] font-serif text-[#78866B] leading-none"
              >
                Awwab<span className="text-[#D4AF37]">.</span>
              </motion.h1>
           </div>

           <motion.p 
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              transition={{ delay: 0.3 }}
              className="text-neutral-400 text-sm md:text-lg max-w-2xl mx-auto font-serif italic leading-relaxed px-4"
           >
              A simple and smart app to help you stay regular with your prayers. Accurate prayer times, Azan alerts, and a daily Namaz guide to support your faith.
           </motion.p>

           <motion.div 
             initial={{ opacity: 0, y: 20 }}
             animate={{ opacity: 1, y: 0 }}
             transition={{ delay: 0.5 }}
             className="flex flex-col sm:flex-row justify-center gap-4 md:gap-6 pt-6 md:pt-8 px-6 md:px-0"
           >
              <button className="px-10 md:px-12 py-3 md:py-4 bg-[#78866B] text-white font-serif italic text-base md:text-lg shadow-xl hover:bg-[#68765B] transition-all flex items-center justify-center gap-4 w-full sm:w-auto">
                 <Download className="w-5 h-5" /> Download APK <span className="text-[10px] opacity-50 font-sans">v2.1.0</span>
              </button>
              <button className="px-10 md:px-12 py-3 md:py-4 border border-[#78866B]/20 text-[#78866B] font-serif italic text-base md:text-lg hover:bg-[#78866B]/5 transition-all flex items-center justify-center gap-4 w-full sm:w-auto">
                 <Smartphone className="w-5 h-5" /> Get on iPhone
              </button>
           </motion.div>
        </motion.div>
      </section>

      {/* Prayer Video Placeholder */}
      <section className="py-24 md:py-32 px-4 md:px-6 bg-[#FDFCF8] dark:bg-black/20 relative overflow-hidden">
         <div className="max-w-7xl mx-auto aspect-video bg-[var(--card-bg)] border border-[var(--border-color)] rounded-[2rem] md:rounded-[3rem] shadow-2xl flex flex-col items-center justify-center group cursor-pointer overflow-hidden relative">
            <div className="w-16 h-16 md:w-20 md:h-20 rounded-full bg-[#D4AF37]/10 border border-[#D4AF37]/30 flex items-center justify-center group-hover:scale-110 transition-transform relative z-10">
               <Play className="w-6 h-6 text-[#D4AF37]" />
            </div>
            <span className="mt-6 md:mt-8 text-[8px] md:text-[10px] font-serif text-[#78866B] italic uppercase tracking-[0.4em] md:tracking-[0.6em] relative z-10">Watch App Demo</span>
            <div className="absolute inset-0 bg-[url('https://images.unsplash.com/photo-1542831371-29b0f74f9713?auto=format&fit=crop&q=80')] bg-cover bg-center opacity-5 group-hover:opacity-10 transition-opacity" />
         </div>
      </section>

      {/* App Screens Gallery */}
      <section className="py-24 md:py-64 px-6 border-y border-[var(--border-color)]">
         <div className="max-w-7xl mx-auto space-y-16 md:space-y-24">
            <div className="text-center space-y-4">
               <span className="text-[10px] text-[#D4AF37] uppercase tracking-[0.6em] md:tracking-[0.8em]">App Design</span>
               <h3 className="text-3xl md:text-7xl font-serif text-[#78866B]">Beautiful & Simple.</h3>
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-4 gap-8">
               {[
                 { title: "Home Page", desc: "See your next prayer time." },
                 { title: "Learn Namaz", desc: "Easy steps for every prayer." },
                 { title: "Qibla", desc: "Find the right direction." },
                 { title: "History", desc: "Track your daily prayers." }
               ].map((screen, i) => (
                 <div key={i} className="space-y-6 group">
                    <div className="aspect-[9/19] bg-[var(--card-bg)] border border-[var(--border-color)] rounded-[2rem] md:rounded-[2.5rem] relative overflow-hidden group-hover:shadow-2xl transition-all shadow-lg max-w-[240px] mx-auto w-full">
                       <div className="absolute inset-0 bg-[url('https://www.transparenttextures.com/patterns/natural-paper.png')] opacity-10" />
                       <div className="absolute inset-0 flex items-center justify-center text-[8px] font-mono text-neutral-400 rotate-90 uppercase tracking-[0.5em]">{screen.title}</div>
                    </div>
                    <div className="text-center space-y-2">
                       <h4 className="text-sm md:text-base font-serif text-[#78866B] italic">{screen.title}</h4>
                       <p className="text-neutral-400 text-[9px] md:text-[10px] uppercase tracking-widest">{screen.desc}</p>
                    </div>
                 </div>
               ))}
            </div>
         </div>
      </section>

      {/* Core Objectives */}
      <section className="py-24 md:py-64 px-6 bg-[var(--card-bg)]/20 relative">
         <div className="max-w-7xl mx-auto grid lg:grid-cols-2 gap-16 md:gap-24 items-center">
            <div className="space-y-8 md:space-y-12">
               <div className="space-y-4 text-center lg:text-left">
                  <span className="text-[10px] text-[#D4AF37] uppercase tracking-[0.6em] md:tracking-[0.8em]">Our Goal</span>
                  <h2 className="text-4xl md:text-7xl font-serif text-[#78866B]">Stay Regular <br/>With Namaz.</h2>
               </div>
               <p className="text-neutral-400 text-sm leading-relaxed italic max-w-sm mx-auto lg:mx-0 text-center lg:text-left">
                 We know life gets busy. Awwab is designed to make sure you never miss a prayer by giving you smart alerts and reminders.
               </p>
               <div className="grid grid-cols-2 gap-6 md:gap-8 pt-8 md:pt-12 max-w-xs mx-auto lg:mx-0">
                  <div className="space-y-2">
                     <span className="text-[9px] md:text-[10px] text-[#D4AF37] uppercase tracking-widest text-center block">Azan alerts</span>
                     <div className="h-px w-full bg-[#D4AF37]/20" />
                  </div>
                  <div className="space-y-2">
                     <span className="text-[9px] md:text-[10px] text-[#D4AF37] uppercase tracking-widest text-center block">Qibla Finder</span>
                     <div className="h-px w-full bg-[#D4AF37]/20" />
                  </div>
               </div>
            </div>

            <div className="relative aspect-square max-w-md mx-auto w-full">
               <div className="absolute inset-0 bg-[#E8EEDF]/20 rounded-[3rem] md:rounded-[4rem] rotate-6 opacity-30" />
               <div className="absolute inset-0 bg-[var(--card-bg)] shadow-2xl rounded-[3rem] md:rounded-[4rem] flex flex-col items-center justify-center p-8 md:p-16 border border-[var(--border-color)] overflow-hidden group">
                  <div className="absolute inset-0 bg-[url('https://images.unsplash.com/photo-1542831371-29b0f74f9713?auto=format&fit=crop&q=80')] bg-cover bg-center opacity-10 group-hover:scale-110 transition-transform duration-1000" />
                  <div className="relative z-10 text-center space-y-8 md:space-y-12">
                     <div className="w-16 h-16 md:w-20 md:h-20 border border-[#D4AF37]/20 rounded-full flex items-center justify-center mx-auto">
                        <Stars className="w-6 h-6 md:w-8 md:h-8 text-[#D4AF37] opacity-40 animate-spin-slow" />
                     </div>
                     <div className="space-y-4">
                        <h3 className="text-xl md:text-2xl font-serif text-[#78866B]">Precise Timing</h3>
                        <p className="text-neutral-400 text-[8px] md:text-[9px] uppercase tracking-[0.4em] leading-loose max-w-[200px] mx-auto">
                           Automatically shows accurate prayer times based on where you are.
                        </p>
                     </div>
                  </div>
               </div>
            </div>
         </div>
      </section>

      {/* App Features */}
      <section className="py-24 md:py-64 px-6 max-w-7xl mx-auto">
         <div className="mb-16 md:mb-48 text-center space-y-6">
            <h3 className="text-xs md:text-sm font-mono text-neutral-700 uppercase tracking-[0.6em] md:tracking-[0.8em]">What's Inside</h3>
            <h4 className="text-4xl md:text-7xl font-serif text-[#78866B]">Core Features.</h4>
         </div>

         <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-8 md:gap-12">
            {[
              { icon: Compass, title: "Qibla Direction", desc: "Find the exact direction for your prayer easily using your phone's built-in compass." },
              { icon: Volume2, title: "Azan Notifications", desc: "Get beautiful Azan alerts at the exact time of every prayer, even when the app is closed." },
              { icon: BookOpen, title: "Namaz Guide", desc: "A simple guide to help you learn how to pray, including steps and rakats for every Namaz." },
              { icon: Calendar, title: "Prayer Tracker", desc: "Keep track of your prayers daily and build a good habit with our visual progress tracker." },
              { icon: Shield, title: "Silent Mode Smart", desc: "The app is smart enough to handle silent mode, ensuring you still get important prayer alerts." },
              { icon: MapPin, title: "Nearby Mosques", desc: "Find the closest mosques around you with easy map directions and distance info." }
            ].map((mod, i) => (
              <FeatureCard key={i} icon={mod.icon} title={mod.title} desc={mod.desc} delay={i * 0.1} />
            ))}
         </div>
      </section>

      {/* Simple Walkthrough - FIXED OVERFLOW & TERMINOLOGY */}
      <section className="py-24 md:py-64 border-t border-[var(--border-color)] relative overflow-hidden">
         <div className="max-w-7xl mx-auto px-6 mb-16 md:mb-24 flex justify-between items-end text-center lg:text-left">
            <div className="space-y-4 w-full">
               <span className="text-[10px] text-[#D4AF37] uppercase tracking-[0.6em] md:tracking-[0.8em]">Extra Features</span>
               <h2 className="text-4xl md:text-6xl font-serif text-[#78866B]">Everything <br/>You Need.</h2>
            </div>
         </div>

         <div className="w-full relative px-6 md:px-[calc((100vw-80rem)/2)]">
            <div className="flex gap-8 md:gap-12 overflow-x-auto pb-12 no-scrollbar scroll-smooth">
               {[
                 { icon: Globe, title: "English & Urdu", desc: "You can easily switch between English and Urdu languages from the app settings." },
                 { icon: Bell, title: "Daily Hadith", desc: "Receive a beautiful Hadith every day with simple translation and explanation." },
                 { icon: Fingerprint, title: "Digital Tasbeeh", desc: "A simple digital counter to help you do Zikr anytime, anywhere with your phone." },
                 { icon: Search, title: "Works Offline", desc: "All your prayer times are saved so the app works even when you don't have internet." }
               ].map((feature, i) => (
                 <motion.div 
                   key={i}
                   className="min-w-[260px] md:min-w-[400px] aspect-[4/5] p-8 md:p-12 flex flex-col justify-end relative group overflow-hidden bg-[var(--card-bg)] border border-[var(--border-color)] shadow-lg"
                 >
                    <div className="absolute top-0 left-0 w-full h-1 bg-[#D4AF37]/10" />
                    <div className="space-y-6 md:space-y-8 relative z-10">
                       <div className="w-12 h-12 md:w-16 md:h-16 rounded-full bg-[var(--background)]/80 border border-[#D4AF37]/10 flex items-center justify-center group-hover:scale-110 transition-transform shadow-sm">
                          <feature.icon className="w-5 h-5 md:w-6 md:h-6 text-[#78866B]" />
                       </div>
                       <div className="space-y-3 md:space-y-4">
                          <h4 className="text-2xl md:text-3xl font-serif text-[#78866B]">{feature.title}</h4>
                          <p className="text-neutral-400 text-xs md:text-sm leading-relaxed italic">{feature.desc}</p>
                       </div>
                       <div className="pt-6 md:pt-8 border-t border-[var(--border-color)]">
                          <span className="text-[10px] text-[#D4AF37] uppercase tracking-widest flex items-center gap-3">
                            Learn More <ArrowRight className="w-3 h-3 group-hover:translate-x-1 transition-transform" />
                          </span>
                       </div>
                    </div>
                 </motion.div>
               ))}
            </div>
         </div>
      </section>

      {/* App Support FAQ */}
      <section className="py-24 md:py-64 px-6 bg-[var(--card-bg)]/20 border-y border-[var(--border-color)]">
         <div className="max-w-4xl mx-auto space-y-16 md:space-y-20">
            <div className="text-center space-y-4">
               <HelpCircle className="w-8 h-8 text-[#D4AF37] mx-auto" />
               <h3 className="text-3xl md:text-6xl font-serif text-[#78866B]">Got Questions?</h3>
            </div>
            <div className="space-y-2 px-2 md:px-0">
               <SimpleFAQItem 
                  question="How does the app know the prayer times?" 
                  answer="The app uses your phone's location to find out exactly where you are and then gets the most accurate prayer times for that area." 
               />
               <SimpleFAQItem 
                  question="Will I get Azan alerts if the app is closed?" 
                  answer="Yes, the app is designed to send you Azan notifications even if you're not using it at that moment." 
               />
               <SimpleFAQItem 
                  question="What is Smart Silent Mode?" 
                  answer="If your phone is on silent, you can choose if you still want to hear the Azan or if the app should just vibrate to remind you." 
               />
               <SimpleFAQItem 
                  question="Is my data safe?" 
                  answer="Yes, all your settings and prayer history are kept safe and private. We don't share your information with anyone." 
               />
            </div>
         </div>
      </section>

      {/* CTA Footer */}
      <section className="py-24 md:py-64 px-6 text-center">
         <div className="max-w-4xl mx-auto space-y-12 md:space-y-16">
            <h2 className="text-4xl md:text-[6rem] font-serif text-[#78866B] leading-tight px-4">Start Your <span className="text-[#D4AF37]">Prayer</span> Journey.</h2>
            <div className="flex flex-col sm:flex-row justify-center gap-4 md:gap-8 px-6 md:px-0">
               <button className="px-10 md:px-12 py-3 md:py-4 bg-[#78866B] text-white font-serif italic text-base md:text-lg shadow-xl hover:bg-[#68765B] transition-all flex items-center justify-center gap-4 w-full sm:w-auto">
                  <Download className="w-5 h-5" /> Download App
               </button>
               <Link href="/" className="px-10 md:px-12 py-3 md:py-4 border border-[#78866B]/20 text-[#78866B] font-serif italic text-base md:text-lg hover:bg-[#78866B]/5 transition-all w-full sm:w-auto">
                  Back to Main Site
               </Link>
            </div>
         </div>
      </section>

    </div>
  );
}
