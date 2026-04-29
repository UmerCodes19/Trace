"use client";

import { Menu, Shield } from "lucide-react";

interface MobileNavProps {
  onOpenSidebar: () => void;
}

export default function MobileNav({ onOpenSidebar }: MobileNavProps) {
  return (
    <header className="md:hidden flex items-center justify-between px-6 py-4 bg-[var(--card-bg)] border-b border-[var(--border-color)] sticky top-0 z-50 transition-colors duration-500">
      <div className="flex items-center gap-3">
        <div className="w-10 h-10 bg-jade-primary/10 rounded-xl flex items-center justify-center">
          <Shield className="w-5 h-5 text-jade-primary" />
        </div>
        <div>
          <span className="block text-lg font-black tracking-tighter text-[var(--foreground)] uppercase">Trace<span className="text-jade-primary">.</span></span>
        </div>
      </div>

      <button 
        onClick={onOpenSidebar}
        className="p-2 text-jade-primary hover:text-jade-deep transition-colors"
      >
        <Menu className="w-6 h-6" />
      </button>
    </header>
  );
}
