"use client";

import React, { useEffect, useRef } from "react";
import { motion, useScroll, useTransform, AnimatePresence } from "framer-motion";
import gsap from "gsap";
import { ScrollTrigger } from "gsap/ScrollTrigger";
import SplitType from "split-type";

if (typeof window !== "undefined") {
  gsap.registerPlugin(ScrollTrigger);
}

export const FadeInUp = ({ children, delay = 0, className = "" }: { children: React.ReactNode, delay?: number, className?: string }) => (
  <motion.div
    initial={{ opacity: 0, y: 30 }}
    whileInView={{ opacity: 1, y: 0 }}
    viewport={{ once: true, margin: "-100px" }}
    transition={{ duration: 0.8, delay, ease: [0.21, 0.47, 0.32, 0.98] }}
    className={className}
  >
    {children}
  </motion.div>
);

export const SplitText = ({ text, className = "", delay = 0, variant = "chars" }: { text: React.ReactNode, className?: string, delay?: number, variant?: "chars" | "words" | "lines" }) => {
  const ref = useRef<HTMLDivElement>(null);
  
  useEffect(() => {
    if (!ref.current) return;
    const split = new SplitType(ref.current, { types: variant as any });
    const targets = variant === "chars" ? split.chars : variant === "words" ? split.words : split.lines;
    
    gsap.from(targets, {
      opacity: 0,
      y: 50,
      rotateX: -30,
      stagger: 0.02,
      duration: 1,
      ease: "power4.out",
      delay,
      scrollTrigger: {
        trigger: ref.current,
        start: "top 90%",
      }
    });
    
    return () => split.revert();
  }, [text, variant, delay]);
  
  return <div ref={ref} className={className}>{text}</div>;
};

export const TextReveal = ({ text, className = "" }: { text: React.ReactNode, className?: string }) => {
  const ref = useRef<HTMLDivElement>(null);
  
  useEffect(() => {
    if (!ref.current) return;
    const split = new SplitType(ref.current, { types: "lines" });
    
    gsap.from(split.lines, {
      yPercent: 100,
      opacity: 0,
      stagger: 0.1,
      duration: 1.2,
      ease: "power4.out",
      scrollTrigger: {
        trigger: ref.current,
        start: "top 85%",
      }
    });
    
    return () => split.revert();
  }, [text]);
  
  return <div ref={ref} className={className} style={{ overflow: "hidden" }}>{text}</div>;
};

export const ParallaxSection = ({ children, offset = 50, className = "" }: { children: React.ReactNode, offset?: number, className?: string }) => {
  const ref = useRef<HTMLDivElement>(null);
  const { scrollYProgress } = useScroll({ target: ref, offset: ["start end", "end start"] });
  const y = useTransform(scrollYProgress, [0, 1], [-offset, offset]);
  
  return <motion.div ref={ref} style={{ y }} className={className}>{children}</motion.div>;
};

export const ImprovedMagneticCursor = ({ children, strength = 0.5 }: { children: React.ReactNode, strength?: number }) => {
  const ref = useRef<HTMLDivElement>(null);
  
  useEffect(() => {
    const el = ref.current;
    if (!el) return;
    
    const xTo = gsap.quickTo(el, "x", { duration: 1, ease: "elastic.out(1, 0.3)" });
    const yTo = gsap.quickTo(el, "y", { duration: 1, ease: "elastic.out(1, 0.3)" });
    
    const move = (e: MouseEvent) => {
      const { clientX, clientY } = e;
      const { height, width, left, top } = el.getBoundingClientRect();
      const x = clientX - (left + width / 2);
      const y = clientY - (top + height / 2);
      xTo(x * strength);
      yTo(y * strength);
    };
    
    const reset = () => { xTo(0); yTo(0); };
    
    el.addEventListener("mousemove", move);
    el.addEventListener("mouseleave", reset);
    return () => {
      el.removeEventListener("mousemove", move);
      el.removeEventListener("mouseleave", reset);
    };
  }, [strength]);
  
  return <div ref={ref} className="inline-block">{children}</div>;
};

export const CountUp = ({ end, duration = 2 }: { end: number, duration?: number }) => {
  const [count, setCount] = React.useState(0);
  const ref = useRef<HTMLSpanElement>(null);
  
  useEffect(() => {
    if (!ref.current) return;
    
    const obj = { value: 0 };
    gsap.to(obj, {
      value: end,
      duration,
      ease: "power2.out",
      scrollTrigger: {
        trigger: ref.current,
        start: "top 95%",
      },
      onUpdate: () => setCount(Math.floor(obj.value))
    });
  }, [end, duration]);
  
  return <span ref={ref}>{count}</span>;
};

export const StaggerReveal = ({ children, className = "" }: { children: React.ReactNode, className?: string }) => (
  <div className={className}>
    {React.Children.map(children, (child, i) => (
      <FadeInUp key={i} delay={i * 0.1}>{child}</FadeInUp>
    ))}
  </div>
);

export const FluidTransition = ({ children, className = "", delay = 0 }: { children: React.ReactNode, className?: string, delay?: number }) => (
  <motion.div
    initial={{ opacity: 0, filter: "blur(10px)", scale: 0.95 }}
    whileInView={{ opacity: 1, filter: "blur(0px)", scale: 1 }}
    viewport={{ once: true }}
    transition={{ duration: 1.2, delay, ease: [0.16, 1, 0.3, 1] }}
    className={className}
  >
    {children}
  </motion.div>
);

export const ClipPathReveal = ({ children, direction = "up", className = "" }: { children: React.ReactNode, direction?: "up" | "down" | "left" | "right", className?: string }) => {
  const clips = {
    up: "inset(100% 0 0 0)",
    down: "inset(0 0 100% 0)",
    left: "inset(0 0 0 100%)",
    right: "inset(0 100% 0 0)"
  };
  
  return (
    <motion.div
      initial={{ clipPath: clips[direction] }}
      whileInView={{ clipPath: "inset(0% 0 0 0)" }}
      viewport={{ once: true }}
      transition={{ duration: 1.5, ease: [0.77, 0, 0.175, 1] }}
      className={className}
    >
      {children}
    </motion.div>
  );
};

export const PremiumCard = ({ children, delay = 0, className = "" }: { children: React.ReactNode, delay?: number, className?: string }) => (
  <motion.div
    initial={{ opacity: 0, y: 40, rotateX: 10 }}
    whileInView={{ opacity: 1, y: 0, rotateX: 0 }}
    viewport={{ once: true }}
    transition={{ duration: 1, delay, ease: "circOut" }}
    className={`${className} perspective-1000`}
  >
    {children}
  </motion.div>
);

export const HoverGlow = ({ children, glowColor = "rgba(255,255,255,0.1)", className = "" }: { children: React.ReactNode, glowColor?: string, className?: string }) => {
  const ref = useRef<HTMLDivElement>(null);
  
  const handleMouseMove = (e: React.MouseEvent<HTMLDivElement>) => {
    if (!ref.current) return;
    const { left, top } = ref.current.getBoundingClientRect();
    const x = e.clientX - left;
    const y = e.clientY - top;
    ref.current.style.setProperty("--x", `${x}px`);
    ref.current.style.setProperty("--y", `${y}px`);
  };
  
  return (
    <div
      ref={ref}
      onMouseMove={handleMouseMove}
      className={`${className} relative group overflow-hidden`}
      style={{ "--glow-color": glowColor } as any}
    >
      <div className="absolute inset-0 opacity-0 group-hover:opacity-100 transition-opacity duration-500 pointer-events-none" 
           style={{ background: `radial-gradient(600px circle at var(--x) var(--y), var(--glow-color), transparent 40%)` }} />
      {children}
    </div>
  );
};

export const ScaleReveal = ({ children, className = "" }: { children: React.ReactNode, className?: string }) => (
  <motion.div
    initial={{ opacity: 0, scale: 0.8 }}
    whileInView={{ opacity: 1, scale: 1 }}
    viewport={{ once: true }}
    transition={{ duration: 1.5, ease: [0.16, 1, 0.3, 1] }}
    className={className}
  >
    {children}
  </motion.div>
);
