"use client";

import { motion, AnimatePresence, useScroll } from "framer-motion";
import { Grid, ChevronDown, Terminal, Map, Moon, Sun, Menu, X, ShieldCheck } from "lucide-react";
import Link from "next/link";
import { useState, useEffect } from "react";
import { usePathname } from "next/navigation";

export default function Navbar() {
  const [isProductsOpen, setIsProductsOpen] = useState(false);
  const [isAdminOpen, setIsAdminOpen] = useState(false);
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);
  const [theme, setTheme] = useState<'dark' | 'light'>('dark');
  const pathname = usePathname();
  
  const { scrollY } = useScroll();
  const [scrolled, setScrolled] = useState(false);

  useEffect(() => {
    return scrollY.on("change", (latest) => {
       setScrolled(latest > 50);
    });
  }, [scrollY]);

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

  useEffect(() => {
    setIsMobileMenuOpen(false);
  }, [pathname]);

  const toggleTheme = (event: React.MouseEvent) => {
    const isTransitionable = 
      // @ts-ignore
      document.startViewTransition && 
      !window.matchMedia('(prefers-reduced-motion: reduce)').matches;

    if (!isTransitionable) {
      const newTheme = theme === 'dark' ? 'light' : 'dark';
      document.documentElement.setAttribute('data-theme', newTheme);
      setTheme(newTheme);
      return;
    }

    const x = event.clientX;
    const y = event.clientY;
    const endRadius = Math.hypot(
      Math.max(x, window.innerWidth - x),
      Math.max(y, window.innerHeight - y)
    );

    // @ts-ignore
    const transition = document.startViewTransition(async () => {
      const newTheme = theme === 'dark' ? 'light' : 'dark';
      document.documentElement.setAttribute('data-theme', newTheme);
      setTheme(newTheme);
    });

    transition.ready.then(() => {
      const clipPath = [
        `circle(0px at ${x}px ${y}px)`,
        `circle(${endRadius}px at ${x}px ${y}px)`,
      ];
      document.documentElement.animate(
        {
          clipPath: clipPath,
        },
        {
          duration: 400,
          easing: 'ease-in-out',
          pseudoElement: '::view-transition-new(root)',
        }
      );
    });
  };

  if (pathname?.startsWith("/admin")) return null;

  return (
    <div className="fixed top-0 w-full z-50 flex justify-center transition-all duration-500 pointer-events-none" style={{ paddingTop: scrolled ? '12px' : '0px' }}>
      <nav className={`
         relative pointer-events-auto
         w-full max-w-7xl mx-auto md:w-[95%]
         backdrop-blur-xl border border-[var(--border-color)] 
         transition-all duration-500 ease-[cubic-bezier(0.23,1,0.32,1)]
         ${scrolled ? 'bg-[var(--nav-bg)]/90 rounded-3xl shadow-xl shadow-black/5 h-14 px-4' : 'bg-[var(--nav-bg)] border-x-0 border-t-0 rounded-none h-16 px-6'}
      `}>
        <div className="h-full flex items-center justify-between">
          <Link href="/" className="group">
            <motion.div layout="position" className="flex items-center gap-3">
              <div className="w-8 h-8 border border-[var(--border-color)] bg-[var(--card-bg)] flex items-center justify-center rounded-xl relative overflow-hidden transition-all group-hover:border-[var(--foreground)]/20 group-hover:scale-105">
                <Grid className="w-4 h-4 text-[var(--foreground)] relative z-10 transition-transform group-hover:rotate-90 duration-500" />
              </div>
              <span className="text-sm font-black tracking-tight text-[var(--foreground)] hidden sm:inline-block uppercase font-mono">MomentUUM Labs</span>
            </motion.div>
          </Link>

          {/* Desktop Menu */}
          <div className="hidden md:flex items-center gap-6 text-sm font-medium text-neutral-500 h-full">
            <div
              className="relative h-full flex items-center"
              onMouseEnter={() => setIsProductsOpen(true)}
              onMouseLeave={() => setIsProductsOpen(false)}
            >
              <button className="flex items-center gap-1 hover:text-[var(--foreground)] transition-colors h-full font-bold text-xs uppercase tracking-wider">
                Products <ChevronDown className={`w-3 h-3 transition-transform duration-300 ${isProductsOpen ? 'rotate-180' : ''}`} />
              </button>

              <AnimatePresence>
                {isProductsOpen && (
                  <motion.div
                    initial={{ opacity: 0, y: 10, scale: 0.95 }}
                    animate={{ opacity: 1, y: 0, scale: 1 }}
                    exit={{ opacity: 0, y: 5, scale: 0.98 }}
                    className="absolute top-[100%] left-1/2 -translate-x-1/2 w-64 bg-[var(--card-bg)] border border-[var(--border-color)] p-2 shadow-2xl rounded-2xl"
                  >
                    <Link href="/products/trace" className="flex items-center gap-4 p-3 hover:bg-jade-primary/5 rounded-xl transition-all group">
                      <div className="w-9 h-9 bg-[var(--background)] border border-[var(--border-color)] rounded-xl flex items-center justify-center group-hover:border-jade-primary/30 transition-all">
                        <Map className="w-4 h-4 text-jade-primary" />
                      </div>
                      <div>
                        <div className="text-[var(--foreground)] font-bold text-sm">Trace</div>
                        <div className="text-[10px] text-jade-primary/60 font-bold uppercase tracking-widest">Campus Discovery</div>
                      </div>
                    </Link>
                    <Link href="/products/awwab" className="flex items-center gap-4 p-3 hover:bg-retro-amber/5 rounded-xl transition-all group mt-1">
                      <div className="w-9 h-9 bg-[var(--background)] border border-[var(--border-color)] rounded-xl flex items-center justify-center group-hover:border-retro-amber/30 transition-all">
                        <Moon className="w-4 h-4 text-retro-amber" />
                      </div>
                      <div>
                        <div className="text-[var(--foreground)] font-bold text-sm">Awwab</div>
                        <div className="text-[10px] text-retro-amber/60 font-bold uppercase tracking-widest">Prayer Companion</div>
                      </div>
                    </Link>
                  </motion.div>
                )}
              </AnimatePresence>
            </div>

            <Link href="/" className="hover:text-[var(--foreground)] transition-colors font-bold text-xs uppercase tracking-wider">Overview</Link>

            <div className="w-px h-4 bg-[var(--border-color)] mx-1"></div>

            <button
              onClick={toggleTheme}
              className="p-2 text-[var(--foreground)] hover:bg-[var(--foreground)]/5 rounded-full transition-colors active:scale-90"
            >
              {theme === 'dark' ? <Sun className="w-4 h-4" /> : <Moon className="w-4 h-4" />}
            </button>

            <div
              className="relative h-full flex items-center"
              onMouseEnter={() => setIsAdminOpen(true)}
              onMouseLeave={() => setIsAdminOpen(false)}
            >
              <button className="px-4 py-1.5 bg-[var(--foreground)] text-[var(--background)] rounded-full font-bold text-xs uppercase tracking-wider flex items-center gap-2 hover:scale-105 transition-all">
                <ShieldCheck className="w-3.5 h-3.5" /> Admin <ChevronDown className={`w-3 h-3 transition-transform ${isAdminOpen ? 'rotate-180' : ''}`} />
              </button>

              <AnimatePresence>
                {isAdminOpen && (
                  <motion.div
                    initial={{ opacity: 0, y: 10, scale: 0.95 }}
                    animate={{ opacity: 1, y: 0, scale: 1 }}
                    exit={{ opacity: 0, y: 5, scale: 0.98 }}
                    className="absolute top-[100%] right-0 w-64 bg-[var(--card-bg)] border border-[var(--border-color)] p-2 shadow-2xl rounded-2xl mt-1"
                  >
                    <div className="px-3 py-2 text-[9px] font-black text-neutral-500 uppercase tracking-widest border-b border-[var(--border-color)] mb-2">Select Control Console</div>
                    <Link href="/login" className="flex items-center gap-4 p-3 hover:bg-jade-primary/5 rounded-xl transition-all group">
                      <div className="w-9 h-9 bg-[var(--background)] border border-[var(--border-color)] rounded-xl flex items-center justify-center group-hover:border-jade-primary/30 transition-all">
                        <Terminal className="w-4 h-4 text-jade-primary" />
                      </div>
                      <div>
                        <div className="text-[var(--foreground)] font-bold text-sm">Trace Dashboard</div>
                        <div className="text-[10px] text-jade-primary/60 font-bold uppercase tracking-widest">Management Portal</div>
                      </div>
                    </Link>
                  </motion.div>
                )}
              </AnimatePresence>
            </div>
          </div>

          {/* Mobile Block */}
          <div className="flex md:hidden items-center gap-2">
            <button onClick={toggleTheme} className="p-2 text-neutral-500">
              {theme === 'dark' ? <Sun className="w-5 h-5" /> : <Moon className="w-5 h-5" />}
            </button>
            <button
              onClick={() => setIsMobileMenuOpen(!isMobileMenuOpen)}
              className="p-2 text-[var(--foreground)] z-50 relative"
            >
              {isMobileMenuOpen ? <X className="w-6 h-6" /> : <Menu className="w-6 h-6" />}
            </button>
          </div>
        </div>

        {/* Mobile Nav Drawer */}
        <AnimatePresence>
          {isMobileMenuOpen && (
            <>
              <motion.div
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                exit={{ opacity: 0 }}
                className="fixed inset-0 z-30 bg-black/40 backdrop-blur-xl md:hidden pointer-events-auto top-0 left-0 w-full h-screen"
                onClick={() => setIsMobileMenuOpen(false)}
              />

              <motion.div
                initial={{ opacity: 0, y: -20 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0, y: -20 }}
                className="absolute top-[calc(100%+8px)] inset-x-0 z-40 bg-[var(--card-bg)] border border-[var(--border-color)] shadow-2xl md:hidden rounded-2xl overflow-hidden p-6"
              >
                <div className="space-y-6">
                  <div className="flex flex-col gap-3">
                    <span className="text-[10px] font-bold text-neutral-500 uppercase tracking-widest px-1">Apps</span>
                    <Link href="/products/trace" className="flex items-center gap-4 p-4 bg-[var(--background)] border border-[var(--border-color)] rounded-xl">
                      <div className="w-10 h-10 bg-[var(--card-bg)] border border-[var(--border-color)] flex items-center justify-center rounded-xl">
                        <Map className="w-5 h-5 text-jade-primary" />
                      </div>
                      <div>
                        <div className="font-bold text-sm text-[var(--foreground)]">Trace</div>
                        <div className="text-[9px] text-jade-primary font-bold uppercase tracking-widest">Lost & Found</div>
                      </div>
                    </Link>
                    <Link href="/products/awwab" className="flex items-center gap-4 p-4 bg-[var(--background)] border border-[var(--border-color)] rounded-xl">
                      <div className="w-10 h-10 bg-[var(--card-bg)] border border-[var(--border-color)] flex items-center justify-center rounded-xl">
                        <Moon className="w-5 h-5 text-retro-amber" />
                      </div>
                      <div>
                        <div className="font-bold text-sm text-[var(--foreground)]">Awwab</div>
                        <div className="text-[9px] text-retro-amber font-bold uppercase tracking-widest">Prayer App</div>
                      </div>
                    </Link>
                  </div>

                  <div className="h-px bg-[var(--border-color)]" />

                  <div className="flex flex-col gap-3">
                    <span className="text-[10px] font-bold text-neutral-500 uppercase tracking-widest px-1">Administration</span>
                    <Link href="/login" className="flex items-center gap-4 p-4 bg-jade-primary/10 border border-jade-primary/20 rounded-xl">
                      <div className="w-10 h-10 bg-jade-primary text-white flex items-center justify-center rounded-xl">
                        <ShieldCheck className="w-5 h-5" />
                      </div>
                      <div>
                        <div className="font-bold text-sm text-[var(--foreground)]">Trace Admin Dash</div>
                        <div className="text-[9px] text-jade-primary font-bold uppercase tracking-widest">Console Control</div>
                      </div>
                    </Link>
                  </div>
                </div>
              </motion.div>
            </>
          )}
        </AnimatePresence>
      </nav>
    </div>
  );
}
