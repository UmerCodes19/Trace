"use client";

import { motion, useMotionTemplate, useMotionValue, useTransform, useSpring, AnimatePresence } from "framer-motion";
import { ArrowRight, Grid, Database, Shield, Globe, Rocket, Ghost, MessageCircle, Target } from "lucide-react";
import Link from "next/link";
import { MouseEvent, useEffect, useState, useRef } from "react";

// Social/Brand SVGs
const YoutubeLogo = () => <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" className="w-full h-full"><path d="M22.54 6.42a2.78 2.78 0 0 0-1.94-2C18.88 4 12 4 12 4s-6.88 0-8.6.46a2.78 2.78 0 0 0-1.94 2A29 29 0 0 0 1 11.75a29 29 0 0 0 .46 5.33A2.78 2.78 0 0 0 3.4 19c1.72.46 8.6.46 8.6.46s6.88 0 8.6-.46a2.78 2.78 0 0 0-1.94-2 29 29 0 0 0 .46-5.25 29 29 0 0 0-.46-5.33z" /><polygon points="9.75 15.02 15.5 11.75 9.75 8.48 9.75 15.02" /></svg>;
const MetaLogo = () => <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" className="w-full h-full"><path d="M12 21.15c-3.1 0-5.7-1.5-7.3-3.9-1.6-2.4-1.6-5.2 0-7.6 1.6-2.4 4.2-3.9 7.3-3.9s5.7 1.5 7.3 3.9c1.6 2.4 1.6 5.2 0 7.6-1.6 2.4-4.2 3.9-7.3 3.9z" /><path d="M12 6.15c-1.8 0-3.4.9-4.3 2.3-.9 1.4-.9 3 0 4.4.9 1.4 2.5 2.3 4.3 2.3s3.4-.9 4.3-2.3c.9-1.4.9-3 0-4.4-.9-1.4-2.5-2.3-4.3-2.3z" /></svg>;
const AppleLogo = () => <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" className="w-full h-full"><path d="M12 20.94c1.88 0 3.85-1.04 5.08-1.9.32-.23.41-.53.25-.87-.38-.8-.67-1.74-.67-2.67 0-2.81 2.39-5.12 5.34-5.12.35 0 .69.03 1.01.09.43.08.79-.14.92-.51.48-1.35.74-2.81.74-4.32C24 2.52 21.48 0 18.35 0c-1.63 0-3.18.66-4.35 1.83C12.83.66 11.28 0 9.65 0 6.52 0 4 2.52 4 5.64c0 1.51.26 2.97.74 4.32.13.37.49.59.92.51.32-.06.66-.09 1.01-.09 2.95 0 5.34 2.31 5.34 5.12 0 .93-.29 1.87-.67 2.67-.16.34-.07.64.25.87 1.23.86 3.2 1.9 5.08 1.9z" /></svg>;
const GoogleLogo = () => <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" className="w-full h-full"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm0 18c-4.41 0-8-3.59-8-8s3.59-8 8-8 8 3.59 8 8-3.59 8-8 8z" /><path d="M12 12V7" /><path d="M12 12l4 4" /><path d="M12 12l-4 4" /></svg>;
const MicrosoftLogo = () => <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" className="w-full h-full"><rect x="3" y="3" width="7" height="7" /><rect x="14" y="3" width="7" height="7" /><rect x="3" y="14" width="7" height="7" /><rect x="14" y="14" width="7" height="7" /></svg>;
const NetflixLogo = () => <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" className="w-full h-full"><path d="M4 4v16h4V4H4z" /><path d="M16 4v16h4V4h-4z" /><path d="M4 4l12 16V4h4v16H4V4z" /></svg>;
const SpotifyLogo = () => <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" className="w-full h-full"><circle cx="12" cy="12" r="10" /><path d="M8 12c2.5-1 5.5-1 8 0" /><path d="M9 15c2-.7 4-.7 6 0" /><path d="M7 9c3.5-1.5 7.5-1.5 10 0" /></svg>;
const GithubLogo = () => <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" className="w-full h-full"><path d="M9 19c-5 1.5-5-2.5-7-3m14 6v-3.87a3.37 3.37 0 0 0-.94-2.61c3.14-.35 6.44-1.54 6.44-7A5.44 5.44 0 0 0 20 4.77 5.07 5.07 0 0 0 19.91 1S18.73.65 16 2.48a13.38 13.38 0 0 0-7 0C6.27.65 5.09 1 5.09 1A5.07 5.07 0 0 0 5 4.77a5.44 5.44 0 0 0-1.5 3.78c0 5.42 3.3 6.61 6.44 7A3.37 3.37 0 0 0 9 18.13V22" /></svg>;
const TwitterLogo = () => <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" className="w-full h-full"><path d="M22 4s-.7 2.1-2 3.4c1.6 10-9.4 17.3-18 11.6 2.2.1 4.4-.6 6-2C3 15.5.5 9.6 3 5c2.2 2.6 5.6 4.1 9 4-.9-4.2 4-6.6 7-3.8 1.1 0 3-1.2 3-1.2z" /></svg>;
const InstagramLogo = () => <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" className="w-full h-full"><rect x="2" y="2" width="20" height="20" rx="5" ry="5" /><path d="M16 11.37A4 4 0 1 1 12.63 8 4 4 0 0 1 16 11.37z" /><line x1="17.5" y1="6.5" x2="17.51" y2="6.5" /></svg>;

// Spectral Layer Sub-Component
function SpectralLayer({ char, distanceX, distanceY, layer, opacity, blur }: { char: string, distanceX: any, distanceY: any, layer: any, opacity: any, blur: any }) {
  const x = useTransform(distanceX, (v: number) => v * layer.weight);
  const y = useTransform(distanceY, (v: number) => v * layer.weight);
  
  return (
    <motion.span 
      style={{ 
        x, 
        y, 
        translateZ: layer.z,
        opacity, 
        filter: useMotionTemplate`blur(${blur}px)`,
        color: layer.color
      }}
      className="absolute inset-0 pointer-events-none -z-10 mix-blend-screen"
    >
      {char}
    </motion.span>
  );
}

// Individual Letter with Spectral Bleed (Interactive)
function SpectralLetter({ char, mouseX, mouseY, isMobile }: { char: string, mouseX: any, mouseY: any, isMobile: boolean }) {
  const ref = useRef<HTMLSpanElement>(null);
  const distanceX = useMotionValue(0);
  const distanceY = useMotionValue(0);
  
  useEffect(() => {
    if (isMobile) return;
    const updateDistance = () => {
      if (!ref.current) return;
      const rect = ref.current.getBoundingClientRect();
      const centerX = rect.left + rect.width / 2;
      const centerY = rect.top + rect.height / 2;
      distanceX.set(mouseX.get() - centerX);
      distanceY.set(mouseY.get() - centerY);
    };
    const unsubX = mouseX.on("change", updateDistance);
    const unsubY = mouseY.on("change", updateDistance);
    return () => { unsubX(); unsubY(); };
  }, [mouseX, mouseY, isMobile, distanceX, distanceY]);

  const dist = useTransform([distanceX, distanceY], ([x, y]: any) => {
    const d = Math.sqrt(x * x + y * y);
    return Math.max(0, 1 - d / 400); 
  });
  const proximity = useSpring(dist, { stiffness: 120, damping: 25 });

  const opacity = useTransform(proximity, [0, 1], [0, 0.5]); 
  const blur = useTransform(proximity, [0, 1], [0, 15]);

  const layerColors = [
    { color: "#06b6d4", weight: 0.12, z: -5 },
    { color: "#ef4444", weight: -0.08, z: -10 },
    { color: "#f59e0b", weight: 0.05, z: -15 },
    { color: "#a855f7", weight: -0.04, z: -20 },
    { color: "#10b981", weight: 0.10, z: -25 },
  ];

  if (isMobile) {
    return <span className="relative inline-block">{char}</span>;
  }

  return (
    <span ref={ref} className="relative inline-block" style={{ transformStyle: "preserve-3d" }}>
       <motion.span style={{ position: 'relative', display: 'inline-block', zIndex: 10 }} animate={{ translateZ: 20 }}>
         {char}
       </motion.span>
       
       {layerColors.map((layer, i) => (
         <SpectralLayer 
           key={i} 
           char={char} 
           distanceX={distanceX} 
           distanceY={distanceY} 
           layer={layer} 
           opacity={opacity} 
           blur={blur} 
         />
       ))}
    </span>
  );
}

// 3D Depth Layer
function DepthLayer({ text, z, titleProxSpring, isMobile }: { text: string, z: number, titleProxSpring: any, isMobile: boolean }) {
  const opacity = useTransform(titleProxSpring, [0, 1], [0, 0.08 / (z / 15)]);
  
  if (isMobile) return null;
  
  return (
    <motion.span 
      style={{ opacity }}
      animate={{ translateZ: -z }}
      className="absolute inset-0 text-white select-none pointer-events-none blur-[1px]"
    >
      {text}
    </motion.span>
  );
}

// Repelling 3D Logo Component
function RepellingLogo({ children, mouseX, mouseY, isMobile }: { children: React.ReactNode, mouseX: any, mouseY: any, isMobile: boolean }) {
  const ref = useRef<HTMLDivElement>(null);
  const x = useMotionValue(0);
  const y = useMotionValue(0);
  const springX = useSpring(x, { stiffness: 100, damping: 30 });
  const springY = useSpring(y, { stiffness: 100, damping: 30 });

  useEffect(() => {
    if (isMobile) return;
    const update = () => {
      if (!ref.current) return;
      const rect = ref.current.getBoundingClientRect();
      const centerX = rect.left + rect.width / 2;
      const centerY = rect.top + rect.height / 2;
      const dx = mouseX.get() - centerX;
      const dy = mouseY.get() - centerY;
      const dist = Math.sqrt(dx * dx + dy * dy);
      if (dist < 400) {
        const power = (1 - dist / 400) * 150;
        x.set(-dx / dist * power);
        y.set(-dy / dist * power);
      } else {
        x.set(0); y.set(0);
      }
    };
    const unsubX = mouseX.on("change", update);
    const unsubY = mouseY.on("change", update);
    return () => { unsubX(); unsubY(); };
  }, [mouseX, mouseY, isMobile, x, y]);

  if (isMobile) {
    return (
      <div className="w-16 h-16 flex items-center justify-center p-4 bg-[var(--card-bg)] border border-[var(--border-color)] pixel-corners shrink-0 opacity-40">
        {children}
      </div>
    );
  }

  return (
    <motion.div 
      ref={ref}
      style={{ x: springX, y: springY, perspective: "1000px" }}
      className="w-28 h-28 flex items-center justify-center p-6 bg-[var(--card-bg)] border border-[var(--border-color)] pixel-corners relative group shrink-0"
    >
       <div className="absolute inset-0 bg-noise opacity-10" />
       <motion.div 
         style={{ transformStyle: "preserve-3d" }}
         whileHover={{ translateZ: 50, rotateX: 20, rotateY: 20 }}
         className="w-full h-full text-neutral-600 group-hover:text-[var(--foreground)] transition-colors opacity-40 group-hover:opacity-100"
       >
         {children}
       </motion.div>
    </motion.div>
  );
}

// Team Card
function TeamCard({ name, role, image, color, isMobile }: { name: string, role: string, image?: string, color: string, isMobile: boolean }) {
  const x = useMotionValue(0);
  const y = useMotionValue(0);
  const mouseXSpring = useSpring(x, { stiffness: 200, damping: 30 });
  const mouseYSpring = useSpring(y, { stiffness: 200, damping: 30 });
  
  const rotateX = useTransform(mouseYSpring, [-0.5, 0.5], ["20deg", "-20deg"]);
  const rotateY = useTransform(mouseXSpring, [-0.5, 0.5], ["-20deg", "20deg"]);

  const localMouseX = useMotionValue(0);
  const localMouseY = useMotionValue(0);

  function handleMouseMove(e: MouseEvent<HTMLDivElement>) {
    if (isMobile) return;
    const rect = e.currentTarget.getBoundingClientRect();
    const xPct = (e.clientX - rect.left) / rect.width - 0.5;
    const yPct = (e.clientY - rect.top) / rect.height - 0.5;
    x.set(xPct);
    y.set(yPct);
    localMouseX.set(e.clientX - rect.left);
    localMouseY.set(e.clientY - rect.top);
  }

  const accentColor = color === 'cyan' ? '#06b6d4' : color === 'red' ? '#ef4444' : '#f59e0b';
  const borderGlow = useMotionTemplate`radial-gradient(300px circle at ${localMouseX}px ${localMouseY}px, ${accentColor}15, transparent 70%)`;

  return (
    <div className="relative group/card" style={{ perspective: "2000px" }}>
      <motion.div
        onMouseMove={handleMouseMove}
        onMouseLeave={() => { x.set(0); y.set(0); }}
        style={{ rotateY: isMobile ? 0 : rotateY, rotateX: isMobile ? 0 : rotateX, transformStyle: "preserve-3d" }}
        className="relative w-full aspect-[4/5] md:h-[520px] md:max-w-[400px] bg-[var(--background)] border border-white/5 flex flex-col justify-end group pixel-corners transition-all duration-300 overflow-hidden cursor-pointer shadow-[0_0_50px_rgba(0,0,0,0.5)] will-change-transform"
      >
        {!isMobile && (
          <motion.div 
            className="absolute inset-0 z-10 opacity-0 group-hover:opacity-100 transition-opacity duration-700 pointer-events-none"
            style={{ background: borderGlow }}
          />
        )}

        {image && (
          <div className="absolute inset-0" style={{ transformStyle: "preserve-3d" }}>
            <motion.img 
              src={image} 
              alt={name} 
              className="absolute inset-0 w-full h-full object-cover grayscale group-hover:grayscale-0 transition-all duration-1000 scale-110 group-hover:scale-100"
              style={{ transform: isMobile ? "none" : "translateZ(-60px)" }}
              loading="lazy"
            />
            <div className="absolute inset-0 bg-gradient-to-t from-black via-black/40 to-transparent opacity-90 group-hover:opacity-95 transition-opacity" style={{ transform: isMobile ? "none" : "translateZ(-30px)" }} />
            
            {!isMobile && (
              <motion.div 
                animate={{ top: ["-10%", "110%"] }} 
                transition={{ duration: 6, repeat: Infinity, ease: "linear" }}
                className="absolute inset-x-0 h-[1px] bg-gradient-to-r from-transparent via-white/5 to-transparent pointer-events-none" 
                style={{ transform: "translateZ(-10px)" }}
              />
            )}
          </div>
        )}

        <div className="absolute inset-0 bg-noise opacity-20 pointer-events-none"></div>
        
        <div className="absolute top-8 left-8 flex items-center gap-3" style={{ transform: isMobile ? "none" : "translateZ(100px)" }}>
           <div className={`w-1 h-1 rounded-full bg-${color === 'cyan' ? 'retro-cyan' : color === 'red' ? 'retro-red' : 'retro-amber'} opacity-60 animate-pulse`} />
           <span className="text-[7px] font-mono text-neutral-600 uppercase tracking-[0.4em]">Status // Active</span>
        </div>

        <div style={{ transform: isMobile ? "none" : "translateZ(120px)" }} className="relative z-20 p-8 md:p-10 w-full space-y-4 md:space-y-6">
          <div className="space-y-2 text-left">
            <div className="flex items-center gap-4">
              <div className="h-px flex-1 bg-white/5 group-hover:bg-white/10 transition-colors" />
              <div className="w-1.5 h-1.5 border border-white/10 rotate-45" />
            </div>
            <h3 className="text-2xl md:text-4xl font-black text-white tracking-tighter uppercase drop-shadow-[0_8px_16px_rgba(0,0,0,1)] leading-tight">{name}</h3>
            <p className="text-neutral-500 font-mono text-[9px] uppercase tracking-[0.5em]">{role}</p>
          </div>
          <div className="flex items-center justify-between pt-6 border-t border-white/5">
            <span className="text-[8px] font-mono text-neutral-600 group-hover:text-white transition-colors uppercase tracking-[0.3em] flex items-center gap-3">
              Dossier Access <ArrowRight className="w-3 h-3 group-hover:translate-x-2 transition-transform" />
            </span>
          </div>
        </div>

        {!isMobile && (
          <div className="absolute inset-6 border border-white/5 pointer-events-none group-hover:border-white/10 transition-colors" style={{ transform: "translateZ(40px)" }} />
        )}
      </motion.div>
    </div>
  );
}

// Live Terminal
function SystemTerminal() {
  const [logs, setLogs] = useState<string[]>(["Starting Systems...", "Connecting to Cloud...", "Online."]);
  useEffect(() => {
    const interval = setInterval(() => {
      const messages = [
        `[${new Date().toLocaleTimeString()}] User Connected: ID_${Math.floor(Math.random() * 1000)}`,
        `[${new Date().toLocaleTimeString()}] Syncing Data: Server_Update`,
        `[${new Date().toLocaleTimeString()}] Match Found: Item_${Math.random().toString(36).substr(2, 5).toUpperCase()}`,
        `[${new Date().toLocaleTimeString()}] System Check: All Good`,
      ];
      setLogs(prev => [...prev.slice(-8), messages[Math.floor(Math.random() * messages.length)]]);
    }, 2000);
    return () => clearInterval(interval);
  }, []);

  return (
    <div className="w-full bg-black border border-white/10 rounded-sm overflow-hidden shadow-2xl font-mono text-[9px] uppercase tracking-widest text-neutral-500 p-4 md:p-6 space-y-2 pixel-corners">
      <div className="flex items-center gap-3 mb-6 border-b border-white/5 pb-4">
        <div className="flex gap-1.5">
          <div className="w-1.5 h-1.5 rounded-full bg-red-500/50" />
          <div className="w-1.5 h-1.5 rounded-full bg-amber-500/50" />
          <div className="w-1.5 h-1.5 rounded-full bg-green-500/50" />
        </div>
        <span className="text-[8px] text-neutral-700">MomentUUM Labs Site v4.2</span>
      </div>
      {logs.map((log, i) => (
        <motion.div key={i} initial={{ opacity: 0, x: -5 }} animate={{ opacity: 1, x: 0 }}>
          {log}
        </motion.div>
      ))}
    </div>
  );
}

export default function MomentUUMPortfolio() {
  const [showSplash, setShowSplash] = useState(true);
  const [splashFinished, setSplashFinished] = useState(false);
  const [isMobile, setIsMobile] = useState(false);
  const mouseX = useMotionValue(0);
  const mouseY = useMotionValue(0);
  const titleRef = useRef<HTMLDivElement>(null);
  const titleProximity = useMotionValue(0);
  const titleProxSpring = useSpring(titleProximity, { stiffness: 100, damping: 30 });

  useEffect(() => {
    const checkMobile = () => setIsMobile(window.innerWidth < 768);
    checkMobile();
    window.addEventListener("resize", checkMobile);
    
    const updateProximity = () => {
      if (!titleRef.current || isMobile) return;
      const rect = titleRef.current.getBoundingClientRect();
      const centerX = rect.left + rect.width / 2;
      const centerY = rect.top + rect.height / 2;
      const dx = mouseX.get() - centerX;
      const dy = mouseY.get() - centerY;
      const d = Math.sqrt(dx * dx + dy * dy);
      titleProximity.set(Math.max(0, 1 - d / 600));
    };

    const unsubX = mouseX.on("change", updateProximity);
    const unsubY = mouseY.on("change", updateProximity);
    
    // Restore Cinematic Timer
    const splashTimer = setTimeout(() => setShowSplash(false), 3000);
    const finishTimer = setTimeout(() => setSplashFinished(true), 4000);
    
    return () => {
      window.removeEventListener("resize", checkMobile);
      unsubX(); unsubY(); clearTimeout(splashTimer); clearTimeout(finishTimer);
    };
  }, [isMobile, mouseX, mouseY, titleProximity]);

  const rotateX = useTransform([mouseY, titleProxSpring], ([y, p]: any) => {
    if (isMobile) return "0deg";
    const base = (y / 1080 - 0.5) * -15; 
    return `${base * p}deg`;
  });
  const rotateY = useTransform([mouseX, titleProxSpring], ([x, p]: any) => {
    if (isMobile) return "0deg";
    const base = (x / 1920 - 0.5) * 15; 
    return `${base * p}deg`;
  });

  const rejectedLogos = [
    { icon: <YoutubeLogo />, name: "YouTube" },
    { icon: <MetaLogo />, name: "Meta" },
    { icon: <AppleLogo />, name: "Apple" },
    { icon: <GoogleLogo />, name: "Google" },
    { icon: <MicrosoftLogo />, name: "Microsoft" },
    { icon: <NetflixLogo />, name: "Netflix" },
    { icon: <SpotifyLogo />, name: "Spotify" },
    { icon: <Rocket className="w-full h-full" />, name: "NASA" },
    { icon: <TwitterLogo />, name: "X" },
    { icon: <GithubLogo />, name: "GitHub" },
    { icon: <Ghost className="w-full h-full" />, name: "Snapchat" },
    { icon: <InstagramLogo />, name: "Instagram" },
    { icon: <MessageCircle className="w-full h-full" />, name: "WhatsApp" },
    { icon: <Globe className="w-full h-full" />, name: "Chrome" },
    { icon: <Target className="w-full h-full" />, name: "Airbnb" }
  ];

  const teamMembers = [
    { name: "Muhammad Umer Qureshi", role: "Lead Developer", color: "cyan", tag: "// Lead_Dev", desc: "Leading technical design.", image: "/images/team/umer_qureshi.png" },
    { name: "Muhammad Umer", role: "Backend Developer", color: "red", tag: "// Backend_Dev", desc: "Building high-speed servers.", image: "/images/team/umer.png" },
    { name: "Maria Khan", role: "Design Lead", color: "amber", tag: "// Design_Lead", desc: "Crafting beautiful interfaces.", image: "/images/team/maria2.png" }
  ];

  const getHex = (color: string) => {
    if (color === 'red') return '#ef4444';
    if (color === 'cyan') return '#06b6d4';
    if (color === 'amber') return '#f59e0b';
    return '#ffffff';
  }

  return (
    <div 
      onMouseMove={(e) => { mouseX.set(e.clientX); mouseY.set(e.clientY); }}
      className="min-h-screen bg-[var(--background)] text-[var(--foreground)] selection:bg-foreground/10 overflow-x-hidden font-sans bg-noise"
    >
      <AnimatePresence>
        {showSplash && (
          <motion.div initial={{ opacity: 1 }} exit={{ opacity: 0 }} transition={{ duration: 0.8 }} className="fixed inset-0 z-[100] flex items-center justify-center bg-black">
            <div className="flex gap-4 md:gap-8 pointer-events-none">
              {"MOMENTUUM".split("").map((char, i) => (
                <motion.span 
                  key={i} 
                  initial={{ opacity: 0, filter: "blur(20px)", scale: 2 }} 
                  animate={{ opacity: 1, filter: "blur(0px)", scale: 1 }} 
                  exit={{ 
                    scale: 0, 
                    opacity: 0, 
                    filter: "blur(30px)", 
                    y: (Math.random() - 0.5) * 400,
                    x: (Math.random() - 0.5) * 400,
                    transition: { delay: i * 0.05, duration: 0.8, ease: "circIn" } 
                  }} 
                  transition={{ delay: i * 0.1, duration: 1.5, ease: [0.16, 1, 0.3, 1] }} 
                  className="text-3xl md:text-7xl font-black text-white uppercase font-mono inline-block origin-center"
                >
                  {char}
                </motion.span>
              ))}
            </div>
            {/* Restore Glowing Background */}
            <motion.div initial={{ opacity: 0 }} animate={{ opacity: 0.08 }} exit={{ opacity: 0 }} className="absolute inset-0 bg-[radial-gradient(circle_at_50%_50%,rgba(255,255,255,0.05),transparent_70%)]" />
          </motion.div>
        )}
      </AnimatePresence>

      <div className={`${!splashFinished ? "opacity-0" : "opacity-100"} transition-opacity duration-1000`}>
        {/* Hero Section */}
        <section className="relative pt-32 pb-24 md:pt-48 md:pb-48 px-6 min-h-screen flex flex-col items-center justify-center text-center overflow-hidden">
          <div className="absolute inset-0 -z-10 opacity-20"><div className="absolute inset-0 bg-dot-pattern" /></div>
          
          <motion.div initial={{ opacity: 0, y: 30 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 1.5, delay: 0.5 }} className="max-w-[90rem] mx-auto flex flex-col items-center relative z-10 w-full">
            <div ref={titleRef} className="relative mb-12 md:mb-16 flex items-center justify-center w-full" style={{ perspective: "1500px" }}>
              <motion.div style={{ rotateX, rotateY, transformStyle: "preserve-3d" }} className="flex flex-col items-center w-full">
                <h1 className="text-[14vw] md:text-[9rem] font-black tracking-tighter leading-none uppercase flex justify-center gap-x-[0.02em] relative w-full">
                  {"MomentUUM".split("").map((char, i) => (
                    <SpectralLetter key={i} char={char} mouseX={mouseX} mouseY={mouseY} isMobile={isMobile} />
                  ))}
                  <DepthLayer text="MomentUUM" z={15} titleProxSpring={titleProxSpring} isMobile={isMobile} />
                  <DepthLayer text="MomentUUM" z={30} titleProxSpring={titleProxSpring} isMobile={isMobile} />
                </h1>
                <div className="flex justify-center mt-2 relative opacity-40">
                  {"Labs".split("").map((char, i) => (
                    <span key={i} className="text-neutral-600 font-black tracking-[0.5em] md:tracking-[1em] uppercase text-[3vw] md:text-sm">{char}</span>
                  ))}
                </div>
              </motion.div>
            </div>

            <div className="text-xs md:text-sm font-bold tracking-[0.2em] md:tracking-[0.4em] mb-12 text-neutral-600 uppercase flex items-center gap-4">
              Building things that <span className="text-[var(--foreground)]/60 italic">matter.</span>
            </div>

            <div className="flex flex-col sm:flex-row gap-4 md:gap-8">
              <Link href="#team" className="btn-premium px-10 text-[10px]">Meet the Team</Link>
              <Link href="/admin" className="btn-outline px-10 text-[10px]">Dashboard</Link>
            </div>
          </motion.div>
        </section>

        {/* Smart Systems */}
        <section className="py-24 md:py-48 px-6 border-y border-[var(--border-color)] bg-[var(--card-bg)]/10">
          <div className="max-w-7xl mx-auto grid lg:grid-cols-2 gap-20 md:gap-32 items-center">
            <div className="space-y-10 text-center lg:text-left">
              <h4 className="text-4xl md:text-7xl font-bold tracking-tighter uppercase leading-[0.9]">Smart <br className="hidden md:block" />Systems.</h4>
              <p className="text-neutral-500 text-xs md:text-sm max-w-sm mx-auto lg:mx-0 leading-relaxed uppercase tracking-widest font-mono">We build high-performance apps that work instantly.</p>
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 md:gap-10">
                {[{ icon: <Database />, label: "Users", val: "1.2M+" }, { icon: <Shield />, label: "Secure", val: "100%" }].map((stat, i) => (
                  <div key={i} className="p-8 border border-[var(--border-color)] bg-[var(--background)] pixel-corners">
                    <div className="text-neutral-700 mb-6">{stat.icon}</div>
                    <div className="text-2xl font-bold font-mono">{stat.val}</div>
                    <div className="text-[8px] text-neutral-600 uppercase tracking-widest mt-2">{stat.label}</div>
                  </div>
                ))}
              </div>
            </div>
            {!isMobile && <SystemTerminal />}
          </div>
        </section>

        {/* Team Section */}
        <section id="team" className="py-24 md:py-48 px-6 relative">
          <div className="max-w-7xl mx-auto">
            <div className="mb-24 text-center">
              <h4 className="text-4xl md:text-7xl font-bold tracking-tighter uppercase">The People.</h4>
            </div>
            <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-12 md:gap-8">
              {teamMembers.map((member, i) => (
                <div key={i} className="space-y-8">
                  <TeamCard name={member.name} role={member.role} image={member.image} color={member.color} isMobile={isMobile} />
                  <div className="px-4 md:px-0 space-y-4">
                    <div className="w-12 h-1 mb-2" style={{ backgroundColor: getHex(member.color) }} />
                    <h5 className="text-xl font-bold uppercase tracking-tighter">{member.role}</h5>
                    <p className="text-neutral-500 text-[10px] uppercase tracking-[0.2em] font-mono leading-loose">{member.desc}</p>
                    <div className="text-[8px] font-mono text-neutral-700 uppercase tracking-widest">{member.tag}</div>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </section>

        {/* Rejected Section */}
        <section className="py-24 md:py-48 px-6 border-t border-[var(--border-color)]">
          <div className="max-w-7xl mx-auto text-center space-y-16">
            <h4 className="text-4xl font-bold tracking-tighter uppercase">Rejected By Choice.</h4>
            <div className="flex flex-wrap justify-center gap-4 md:gap-12">
              {rejectedLogos.map((company, i) => (
                <RepellingLogo key={i} mouseX={mouseX} mouseY={mouseY} isMobile={isMobile}>
                  {company.icon}
                </RepellingLogo>
              ))}
            </div>
          </div>
        </section>

        {/* Footer */}
        <footer className="py-24 px-6 md:px-10 border-t border-[var(--border-color)]">
          <div className="max-w-7xl mx-auto grid md:grid-cols-3 gap-16 text-center md:text-left">
            <div className="space-y-6">
              <span className="font-bold uppercase tracking-[0.4em] text-sm">MomentUUM Labs</span>
              <p className="text-neutral-700 text-[8px] uppercase tracking-[0.6em] leading-loose">Building things that matter.</p>
            </div>
            <div className="space-y-6">
              <h5 className="text-[10px] font-mono text-neutral-500 uppercase tracking-widest">Navigation</h5>
              <div className="flex flex-col gap-4 text-[9px] uppercase tracking-[0.4em] text-neutral-700">
                <Link href="/products/trace" className="hover:text-retro-cyan">Trace Network</Link>
                <Link href="/products/awwab" className="hover:text-retro-amber">Awwab Companion</Link>
                <Link href="/admin" className="hover:text-white">System Admin</Link>
              </div>
            </div>
            <div className="space-y-6">
              <div className="p-8 border border-[var(--border-color)] bg-[var(--background)] pixel-corners">
                <div className="text-[9px] text-neutral-700 uppercase tracking-[0.4em]">2026 Division.</div>
              </div>
            </div>
          </div>
        </footer>
      </div>
    </div>
  );
}
