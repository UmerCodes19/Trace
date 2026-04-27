"use client";

import { motion, useScroll, useTransform, useMotionValue } from "framer-motion";
import { ArrowLeft, Compass, Volume2, BookOpen, Calendar, Shield, MapPin, Globe, Bell, Fingerprint, Search, Download, Smartphone, Play, ChevronDown, Star } from "lucide-react";
import Link from "next/link";
import { useRef, useState } from "react";
import { FadeInUp, SplitText, TextReveal, ParallaxSection, ImprovedMagneticCursor, CountUp, StaggerReveal, FluidTransition, ClipPathReveal, PremiumCard, HoverGlow, ScaleReveal } from "@/components/animations";

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

// Enhanced Feature Card
function FeatureCard({ icon: Icon, title, desc, delay }: { icon: any, title: string, desc: string, delay: number }) {
  return (
    <PremiumCard delay={delay} className="p-8 md:p-10 bg-[var(--card-bg)]/40 backdrop-blur-3xl group h-full">
      <div className="w-10 h-10 md:w-12 md:h-12 bg-[#78866B]/10 flex items-center justify-center mb-6 md:mb-8 rounded-full group-hover:scale-110 transition-transform">
        <Icon className="w-4 h-4 md:w-5 md:h-5 text-[#78866B]" />
      </div>
      <h4 className="text-lg md:text-xl font-serif text-[#78866B] mb-4">{title}</h4>
      <p className="text-neutral-500 text-[10px] md:text-[11px] uppercase tracking-widest leading-relaxed">{desc}</p>
    </PremiumCard>
  );
}

// FAQ Component
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

      {/* Product Navigation */}
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

      {/* Enhanced Hero Section */}
      <section className="relative min-h-[calc(100vh-8rem)] flex flex-col items-center justify-center text-center px-6 overflow-hidden py-12 md:py-0">
        <IslamicPattern />

        <motion.div style={{ opacity: heroOpacity, scale: heroScale }} className="relative z-10 space-y-8 md:space-y-12">
          <FluidTransition className="space-y-4 md:space-y-6">
            <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="flex items-center justify-center gap-2 md:gap-4">
              <div className="w-8 md:w-12 h-px bg-[#D4AF37]/30" />
              <span className="text-[8px] md:text-[10px] font-medium text-[#D4AF37] uppercase tracking-[0.4em] md:tracking-[1em]">Smart Namaz App</span>
              <div className="w-8 md:w-12 h-px bg-[#D4AF37]/30" />
            </motion.div>

            <SplitText text="Awwab." className="text-6xl sm:text-8xl md:text-[11rem] font-serif text-[#78866B] leading-none" />
          </FluidTransition>

          <FluidTransition delay={0.3} className="text-neutral-400 text-sm md:text-lg max-w-2xl mx-auto font-serif italic leading-relaxed px-4">
            A simple and smart app to help you stay regular with your prayers. Accurate prayer times, Azan alerts, and a daily Namaz guide to support your faith.
          </FluidTransition>

          <FluidTransition delay={0.5} className="flex flex-col sm:flex-row justify-center gap-4 md:gap-6 pt-6 md:pt-8 px-6 md:px-0">
            <ImprovedMagneticCursor>
              <button className="px-10 md:px-12 py-3 md:py-4 bg-[#78866B] text-white font-serif italic text-base md:text-lg shadow-xl hover:bg-[#68765B] transition-all flex items-center justify-center gap-4 w-full sm:w-auto rounded-lg">
                <Download className="w-5 h-5" /> Download APK
              </button>
            </ImprovedMagneticCursor>
            <ImprovedMagneticCursor>
              <button className="px-10 md:px-12 py-3 md:py-4 border border-[#78866B]/20 text-[#78866B] font-serif italic text-base md:text-lg hover:bg-[#78866B]/5 transition-all flex items-center justify-center gap-4 w-full sm:w-auto rounded-lg">
                <Smartphone className="w-5 h-5" /> Get on iPhone
              </button>
            </ImprovedMagneticCursor>
          </FluidTransition>
        </motion.div>
      </section>

      {/* Video Section with Parallax */}
      <section className="py-24 md:py-32 px-4 md:px-6 bg-[#FDFCF8] dark:bg-black/20 relative overflow-hidden">
        <ParallaxSection offset={30} className="max-w-7xl mx-auto">
          <ScaleReveal className="aspect-video bg-[var(--card-bg)] border border-[var(--border-color)] rounded-[2rem] md:rounded-[3rem] shadow-2xl flex flex-col items-center justify-center group cursor-pointer overflow-hidden relative">
            <div className="w-16 h-16 md:w-20 md:h-20 rounded-full bg-[#D4AF37]/10 border border-[#D4AF37]/30 flex items-center justify-center group-hover:scale-110 transition-transform relative z-10">
              <Play className="w-6 h-6 text-[#D4AF37]" />
            </div>
            <span className="mt-6 md:mt-8 text-[8px] md:text-[10px] font-serif text-[#78866B] italic uppercase tracking-[0.4em] md:tracking-[0.6em] relative z-10">Watch App Demo</span>
          </ScaleReveal>
        </ParallaxSection>
      </section>

      {/* Journey Section */}
      <section className="py-24 md:py-48 px-6 border-y border-[var(--border-color)]">
        <div className="max-w-7xl mx-auto space-y-16 md:space-y-24">
          <FadeInUp>
            <TextReveal
              text="Your Spiritual Journey"
              className="text-center text-4xl md:text-7xl font-serif text-[#78866B] mb-6"
            />
            <p className="text-center text-neutral-400 text-sm leading-relaxed italic max-w-2xl mx-auto">
              Awwab is built for Muslims who want to maintain consistency in their prayers without the complexity.
            </p>
          </FadeInUp>

          <StaggerReveal className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-4 gap-8">
            {[
              { title: "Home Page", desc: "See your next prayer time." },
              { title: "Learn Namaz", desc: "Easy steps for every prayer." },
              { title: "Qibla", desc: "Find the right direction." },
              { title: "History", desc: "Track your daily prayers." }
            ].map((screen, i) => (
              <div key={i} className="space-y-6 group">
                <HoverGlow glowColor="rgba(216, 175, 55, 0.2)" className="aspect-[9/19] bg-[var(--card-bg)] border border-[var(--border-color)] rounded-[2rem] md:rounded-[2.5rem] relative overflow-hidden group-hover:shadow-2xl transition-all shadow-lg max-w-[240px] mx-auto w-full p-4 flex items-center justify-center">
                  <div className="text-[8px] font-mono text-neutral-400 uppercase tracking-[0.5em] text-center">{screen.title}</div>
                </HoverGlow>
                <div className="text-center space-y-2">
                  <h4 className="text-sm md:text-base font-serif text-[#78866B] italic">{screen.title}</h4>
                  <p className="text-neutral-400 text-[9px] md:text-[10px] uppercase tracking-widest">{screen.desc}</p>
                </div>
              </div>
            ))}
          </StaggerReveal>
        </div>
      </section>

      {/* Core Objectives with Parallax */}
      <section className="py-24 md:py-48 px-6 bg-[var(--card-bg)]/20 relative">
        <div className="max-w-7xl mx-auto grid lg:grid-cols-2 gap-16 md:gap-24 items-center">
          <FadeInUp>
            <div className="space-y-8 md:space-y-12">
              <div className="space-y-4">
                <span className="text-[10px] text-[#D4AF37] uppercase tracking-[0.6em] md:tracking-[0.8em]">Our Goal</span>
                <SplitText
                  text="Stay Regular With Namaz."
                  className="text-4xl md:text-7xl font-serif text-[#78866B]"
                  variant="words"
                />
              </div>
              <p className="text-neutral-400 text-sm leading-relaxed italic max-w-sm text-left">
                We know life gets busy. Awwab is designed to make sure you never miss a prayer by giving you smart alerts and reminders.
              </p>
            </div>
          </FadeInUp>

          <ParallaxSection offset={-20}>
            <ClipPathReveal direction="right">
              <div className="relative aspect-square max-w-md mx-auto w-full">
                <div className="absolute inset-0 bg-[#E8EEDF]/20 rounded-[3rem] md:rounded-[4rem] rotate-6 opacity-30" />
                <div className="absolute inset-0 bg-[var(--card-bg)] shadow-2xl rounded-[3rem] md:rounded-[4rem] flex flex-col items-center justify-center p-8 md:p-16 border border-[var(--border-color)] overflow-hidden group">
                  <div className="relative z-10 text-center space-y-8 md:space-y-12">
                    <div className="w-16 h-16 md:w-20 md:h-20 border border-[#D4AF37]/20 rounded-full flex items-center justify-center mx-auto">
                      <Star className="w-6 h-6 md:w-8 md:h-8 text-[#D4AF37] opacity-40" />
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
            </ClipPathReveal>
          </ParallaxSection>
        </div>
      </section>

      {/* Features Section with Stagger */}
      <section className="py-24 md:py-48 px-6 max-w-7xl mx-auto">
        <FadeInUp className="mb-16 md:mb-24 text-center space-y-6">
          <h3 className="text-xs md:text-sm font-mono text-neutral-700 uppercase tracking-[0.6em] md:tracking-[0.8em]">What's Inside</h3>
          <SplitText
            text="Core Features."
            className="text-4xl md:text-7xl font-serif text-[#78866B]"
            variant="words"
          />
        </FadeInUp>

        <StaggerReveal className="grid sm:grid-cols-2 lg:grid-cols-3 gap-8 md:gap-12">
          {[
            { icon: Compass, title: "Qibla Direction", desc: "Find the exact direction for your prayer easily using your phone's built-in compass." },
            { icon: Volume2, title: "Azan Notifications", desc: "Get beautiful Azan alerts at the exact time of every prayer, even when the app is closed." },
            { icon: BookOpen, title: "Namaz Guide", desc: "A simple guide to help you learn how to pray, including steps and rakats for every Namaz." },
            { icon: Calendar, title: "Prayer Tracker", desc: "Keep track of your prayers daily and build a good habit with our visual progress tracker." },
            { icon: Shield, title: "Silent Mode Smart", desc: "The app is smart enough to handle silent mode, ensuring you still get important prayer alerts." },
            { icon: MapPin, title: "Nearby Mosques", desc: "Find the closest mosques around you with easy map directions and distance info." }
          ].map((mod, i) => (
            <FeatureCard key={i} icon={mod.icon} title={mod.title} desc={mod.desc} delay={i * 0.08} />
          ))}
        </StaggerReveal>
      </section>

      {/* FAQ Section */}
      <section className="py-24 md:py-48 px-6 border-t border-[var(--border-color)] bg-[var(--card-bg)]/5">
        <div className="max-w-3xl mx-auto">
          <FadeInUp className="mb-16 md:mb-24 text-center">
            <SplitText
              text="Questions? We've Got Answers."
              className="text-4xl md:text-7xl font-serif text-[#78866B] mb-6"
            />
          </FadeInUp>

          <div className="space-y-4">
            {[
              { q: "Is Awwab free?", a: "Yes, Awwab is completely free to download and use. No subscriptions, no hidden charges." },
              { q: "Does it work offline?", a: "Yes! Prayer times are stored on your device, so the app works perfectly without internet." },
              { q: "How accurate are prayer times?", a: "We use your exact GPS location to calculate prayer times according to Islamic standards." },
              { q: "Can I customize notifications?", a: "Absolutely! You can customize notification times, sounds, and enable/disable alerts for each prayer." },
              { q: "What languages are supported?", a: "Awwab currently supports English and Urdu, with more languages coming soon." }
            ].map((item, i) => (
              <FadeInUp key={i} delay={i * 0.05}>
                <SimpleFAQItem question={item.q} answer={item.a} />
              </FadeInUp>
            ))}
          </div>
        </div>
      </section>

      {/* CTA Section */}
      <section className="py-24 md:py-48 px-6 bg-gradient-to-b from-[var(--background)] to-[var(--card-bg)]/20 border-t border-[var(--border-color)]">
        <div className="max-w-4xl mx-auto text-center">
          <FadeInUp>
            <SplitText
              text="Start Your Prayer Journey Today"
              className="text-4xl md:text-6xl font-serif text-[#78866B] mb-8"
              variant="words"
            />
          </FadeInUp>
          <FluidTransition delay={0.3} className="text-neutral-500 text-sm leading-relaxed italic mb-12 max-w-2xl mx-auto">
            Join thousands of Muslims using Awwab to stay consistent with their prayers. Download now and get started in seconds.
          </FluidTransition>
          <div className="flex flex-col sm:flex-row gap-6 justify-center flex-wrap">
            <ImprovedMagneticCursor>
              <button className="px-8 py-4 bg-[#78866B] text-white rounded-lg font-bold hover:shadow-lg hover:shadow-[#78866B]/30 transition-all uppercase text-[10px] md:text-sm">
                Download Now
              </button>
            </ImprovedMagneticCursor>
            <ImprovedMagneticCursor>
              <button className="px-8 py-4 border border-[#78866B]/30 text-[#78866B] rounded-lg font-bold hover:border-[#78866B]/60 hover:bg-[#78866B]/5 transition-all uppercase text-[10px] md:text-sm">
                Learn More
              </button>
            </ImprovedMagneticCursor>
          </div>
        </div>
      </section>

      {/* Footer */}
      <footer className="py-16 px-6 md:px-10 border-t border-[var(--border-color)] bg-[var(--card-bg)]/10">
        <div className="max-w-7xl mx-auto text-center">
          <FadeInUp>
            <p className="text-neutral-700 text-[8px] uppercase tracking-[0.6em] leading-loose">
              © 2026 Awwab App. Built with ❤️ for the Muslim community. By MomentUUM Labs.
            </p>
          </FadeInUp>
        </div>
      </footer>
    </div>
  );
}
