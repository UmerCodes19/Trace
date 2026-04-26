"use client";

import { motion, useMotionValue, useSpring, useTransform } from "framer-motion";
import { useEffect } from "react";

export default function CustomCursor() {
  const mouseX = useMotionValue(0);
  const mouseY = useMotionValue(0);
  const cursorX = useSpring(mouseX, { stiffness: 500, damping: 28 });
  const cursorY = useSpring(mouseY, { stiffness: 500, damping: 28 });
  
  const velocityX = useMotionValue(0);
  const velocityY = useMotionValue(0);
  
  useEffect(() => {
    let lastX = 0;
    let lastY = 0;
    const moveCursor = (e: MouseEvent) => {
      mouseX.set(e.clientX);
      mouseY.set(e.clientY);
      velocityX.set(e.clientX - lastX);
      velocityY.set(e.clientY - lastY);
      lastX = e.clientX;
      lastY = e.clientY;
    };
    window.addEventListener("mousemove", moveCursor);
    return () => window.removeEventListener("mousemove", moveCursor);
  }, []);

  return (
    <motion.div
      style={{ x: cursorX, y: cursorY }}
      className="fixed top-0 left-0 w-6 h-6 border border-[var(--foreground)] opacity-20 rounded-full pointer-events-none z-[9999] -translate-x-1/2 -translate-y-1/2 mix-blend-difference flex items-center justify-center"
    >
       <motion.div 
         className="w-1.5 h-1.5 bg-[var(--foreground)] rounded-full"
       />
    </motion.div>
  );
}
