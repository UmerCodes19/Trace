"use client";

import { motion, AnimatePresence } from "framer-motion";
import { Grid, ChevronDown, Terminal, Map, Moon, Sun, Menu, X } from "lucide-react";
import Link from "next/link";
import { useState, useEffect } from "react";
import { usePathname } from "next/navigation";

export default function Navbar() {
  const [isProductsOpen, setIsProductsOpen] = useState(false);
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);
  const [theme, setTheme] = useState<'dark' | 'light'>('dark');
  const pathname = usePathname();

  useEffect(() => {
    const currentTheme = document.documentElement.getAttribute('data-theme') as 'dark' | 'light' || 'dark';
    setTheme(currentTheme);

    const observer = new MutationObserver((mutations) => {
      mutations.forEach((mutation) => {
        if (mutation.attributeName === 'data-theme') {
          const newTheme = document.documentElement.getAttribute('data-theme') as 'dark' | 'light';
          if (newTheme) setTheme(newTheme);
        }
      });
    });

    observer.observe(document.documentElement, { attributes: true });
    return () => observer.disconnect();
  }, []);

  // Close mobile menu on route change
  useEffect(() => {
    setIsMobileMenuOpen(false);
  }, [pathname]);

  const toggleTheme = () => {
    const newTheme = theme === 'dark' ? 'light' : 'dark';
    document.documentElement.setAttribute('data-theme', newTheme);
    setTheme(newTheme);
  };

  if (pathname?.startsWith("/admin")) return null;

  return (
    <nav className="fixed top-0 w-full z-50 bg-[var(--nav-bg)] backdrop-blur-md border-b border-[var(--border-color)] transition-colors duration-500">
      <div className="max-w-7xl mx-auto px-6 h-16 flex items-center justify-between relative">
        <Link href="/">
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            className="flex items-center gap-3"
          >
            <div className="w-8 h-8 border border-[var(--border-color)] bg-[var(--card-bg)] flex items-center justify-center pixel-corners relative overflow-hidden group">
              <div className="absolute inset-0 glow-cyan-accent opacity-30 group-hover:opacity-60 transition-opacity"></div>
              <Grid className="w-4 h-4 text-[var(--foreground)] relative z-10" />
            </div>
            <span className="text-sm font-bold tracking-tight uppercase font-mono text-[var(--foreground)]">MomentUUM Labs</span>
          </motion.div>
        </Link>

        {/* Desktop Menu */}
        <div className="hidden md:flex items-center gap-8 text-sm font-medium text-neutral-500 h-full">
          <div
            className="relative h-full flex items-center"
            onMouseEnter={() => setIsProductsOpen(true)}
            onMouseLeave={() => setIsProductsOpen(false)}
          >
            <button className="flex items-center gap-1 hover:text-[var(--foreground)] transition-colors h-full">
              Products <ChevronDown className={`w-3 h-3 transition-transform ${isProductsOpen ? 'rotate-180' : ''}`} />
            </button>

            <AnimatePresence>
              {isProductsOpen && (
                <motion.div
                  initial={{ opacity: 0, y: 10, scale: 0.95 }}
                  animate={{ opacity: 1, y: 0, scale: 1 }}
                  exit={{ opacity: 0, y: 10, scale: 0.95 }}
                  className="absolute top-16 left-1/2 -translate-x-1/2 w-64 bg-[var(--card-bg)] border border-[var(--border-color)] p-2 shadow-2xl pixel-corners"
                >
                  <div className="absolute inset-0 bg-noise opacity-30 pointer-events-none rounded-lg"></div>

                  <Link href="/products/trace" className="flex items-center gap-4 p-3 hover:bg-[var(--foreground)]/5 rounded-md transition-colors group relative overflow-hidden">
                    <div className="absolute inset-0 glow-cyan-accent opacity-0 group-hover:opacity-20 transition-opacity pointer-events-none"></div>
                    <div className="w-8 h-8 bg-[var(--background)] border border-[var(--border-color)] rounded flex items-center justify-center">
                      <Map className="w-4 h-4 text-retro-cyan" />
                    </div>
                    <div>
                      <div className="text-[var(--foreground)] font-bold text-sm">Trace</div>
                      <div className="text-[10px] text-neutral-500 font-mono tracking-widest uppercase">Recovery Network</div>
                    </div>
                  </Link>

                  <Link href="/products/awwab" className="flex items-center gap-4 p-3 hover:bg-[var(--foreground)]/5 rounded-md transition-colors group relative overflow-hidden mt-1">
                    <div className="absolute inset-0 glow-amber-accent opacity-0 group-hover:opacity-20 transition-opacity pointer-events-none"></div>
                    <div className="w-8 h-8 bg-[var(--background)] border border-[var(--border-color)] rounded flex items-center justify-center">
                      <Moon className="w-4 h-4 text-retro-amber" />
                    </div>
                    <div>
                      <div className="text-[var(--foreground)] font-bold text-sm">Awwab</div>
                      <div className="text-[10px] text-neutral-500 font-mono tracking-widest uppercase">Namaz Companion</div>
                    </div>
                  </Link>
                </motion.div>
              )}
            </AnimatePresence>
          </div>

          <Link href="#technologies" className="hover:text-[var(--foreground)] transition-colors">Tech</Link>
          <Link href="#team" className="hover:text-[var(--foreground)] transition-colors">Team</Link>

          <div className="w-px h-4 bg-[var(--border-color)] mx-2"></div>

          <button
            onClick={toggleTheme}
            className="p-1.5 hover:text-[var(--foreground)] transition-colors group"
          >
            {theme === 'dark' ? <Sun className="w-4 h-4" /> : <Moon className="w-4 h-4" />}
          </button>

          <Link href="/admin" className="hover:text-[var(--foreground)] transition-colors flex items-center gap-2 group">
            <Terminal className="w-4 h-4 group-hover:text-retro-cyan transition-colors" />
            <span className="group-hover:text-retro-cyan transition-shadow">Admin</span>
          </Link>
        </div>

        {/* Mobile Toggle */}
        <div className="flex md:hidden items-center gap-4">
          <button
            onClick={toggleTheme}
            className="p-2 text-neutral-500 hover:text-[var(--foreground)]"
          >
            {theme === 'dark' ? <Sun className="w-5 h-5" /> : <Moon className="w-5 h-5" />}
          </button>
          <button
            onClick={() => setIsMobileMenuOpen(!isMobileMenuOpen)}
            className="p-2 text-neutral-500 hover:text-[var(--foreground)] z-50 relative"
          >
            {isMobileMenuOpen ? <X className="w-6 h-6" /> : <Menu className="w-6 h-6" />}
          </button>
        </div>
      </div>

      {/* Mobile Drawer */}
      <AnimatePresence>
        {isMobileMenuOpen && (
          <>
            {/* Blurred Backdrop Overlay */}
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              className="fixed inset-0 z-30 bg-black/40 backdrop-blur-xl md:hidden"
              onClick={() => setIsMobileMenuOpen(false)}
            />

            <motion.div
              initial={{ opacity: 0, y: -20 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -20 }}
              transition={{ type: "spring", damping: 30, stiffness: 300 }}
              className="fixed top-16 inset-x-0 z-40 bg-[var(--card-bg)] border-b border-[var(--border-color)] shadow-2xl md:hidden overflow-hidden"
            >
              <div className="absolute inset-0 bg-noise opacity-20 pointer-events-none"></div>

              <div className="p-6 space-y-8 relative z-10">
                <div className="flex flex-col gap-6">
                  <span className="text-[10px] font-mono text-neutral-500 uppercase tracking-widest px-2">Products</span>
                  <div className="grid grid-cols-1 gap-3">
                    <Link href="/products/trace" className="flex items-center gap-4 p-4 bg-[var(--background)]/40 border border-[var(--border-color)] pixel-corners group">
                      <div className="w-10 h-10 bg-[var(--background)] border border-[var(--border-color)] flex items-center justify-center">
                        <Map className="w-5 h-5 text-retro-cyan" />
                      </div>
                      <div>
                        <div className="font-bold text-sm text-[var(--foreground)]">Trace</div>
                        <div className="text-[9px] text-neutral-500 uppercase tracking-widest">Recovery App</div>
                      </div>
                    </Link>
                    <Link href="/products/awwab" className="flex items-center gap-4 p-4 bg-[var(--background)]/40 border border-[var(--border-color)] pixel-corners group">
                      <div className="w-10 h-10 bg-[var(--background)] border border-[var(--border-color)] flex items-center justify-center">
                        <Moon className="w-5 h-5 text-retro-amber" />
                      </div>
                      <div>
                        <div className="font-bold text-sm text-[var(--foreground)]">Awwab</div>
                        <div className="text-[9px] text-neutral-500 uppercase tracking-widest">Prayer App</div>
                      </div>
                    </Link>
                  </div>
                </div>

                <div className="h-px bg-[var(--border-color)] w-full opacity-50"></div>

                <div className="grid grid-cols-2 gap-4">
                  <Link href="#team" className="p-4 bg-[var(--background)]/40 border border-[var(--border-color)] pixel-corners text-center font-bold uppercase tracking-tighter text-sm">The Team</Link>
                  <Link href="#technologies" className="p-4 bg-[var(--background)]/40 border border-[var(--border-color)] pixel-corners text-center font-bold uppercase tracking-tighter text-sm">Tech</Link>
                  <Link href="/admin" className="col-span-2 p-4 bg-retro-cyan/10 border border-retro-cyan/20 pixel-corners text-center font-bold uppercase tracking-tighter text-sm text-retro-cyan flex items-center justify-center gap-2">
                    <Terminal className="w-4 h-4" /> System Console
                  </Link>
                </div>
              </div>
            </motion.div>
          </>
        )}
      </AnimatePresence>
    </nav>
  );
}
