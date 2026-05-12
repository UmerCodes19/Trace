"use client";

import { motion, useScroll, useSpring } from "framer-motion";
import { usePathname } from "next/navigation";

export default function ScrollProgress() {
  const pathname = usePathname();
  const { scrollYProgress } = useScroll();
  const scaleX = useSpring(scrollYProgress, {
    stiffness: 100,
    damping: 30,
    restDelta: 0.001
  });

  const isTraceContext = 
    pathname?.includes('/products/trace') || 
    pathname?.includes('/admin') || 
    pathname?.includes('/post') ||
    pathname?.includes('/login') ||
    pathname?.includes('/profile');

  return (
    <motion.div
      className={`fixed top-0 left-0 right-0 h-[2px] z-[60] origin-left transition-colors duration-300 ${
        isTraceContext ? 'bg-jade-primary' : 'bg-[var(--foreground)]'
      }`}
      style={{ scaleX }}
    />
  );
}
