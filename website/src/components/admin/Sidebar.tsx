"use client";

import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { 
  LayoutDashboard, 
  Users, 
  LogOut,
  FileText,
  History,
  Sun,
  Moon,
  Activity,
  Home
} from "lucide-react";
import { motion, AnimatePresence } from "framer-motion";
import { auth } from "@/lib/firebase";
import { signOut } from "firebase/auth";

const menuItems = [
  { icon: LayoutDashboard, label: "Overview", href: "/admin" },
  { icon: FileText, label: "Manage Posts", href: "/admin/posts" },
  { icon: History, label: "View Claims", href: "/admin/claims" },
  { icon: Users, label: "User List", href: "/admin/users" },
];

interface SidebarProps {
  isOpen?: boolean;
  onClose?: () => void;
  theme?: "light" | "dark";
  onToggleTheme?: () => void;
}

export default function Sidebar({ isOpen, onClose, theme, onToggleTheme }: SidebarProps) {
  const pathname = usePathname();
  const router = useRouter();

  const handleLogout = async () => {
    try {
      await signOut(auth);
      router.push("/login");
    } catch (error) {
      console.error("Logout Error:", error);
    }
  };

  return (
    <>
      {/* Mobile Backdrop */}
      <AnimatePresence>
        {isOpen && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            onClick={onClose}
            className="fixed inset-0 bg-[var(--background)]/80 backdrop-blur-sm z-[60] md:hidden"
          />
        )}
      </AnimatePresence>

      <aside 
        className={`
          fixed md:static inset-y-0 left-0 z-[70] 
          flex flex-col w-[280px] bg-[var(--card-bg)] border-r border-[var(--border-color)] shrink-0
          transition-all duration-300 ease-in-out
          ${isOpen ? "translate-x-0" : "-translate-x-full md:translate-x-0"}
        `}
      >
        <div className="p-8 flex flex-col h-full">
          {/* Official Branding Block */}
          <div className="flex items-center justify-between mb-12">
            <div className="flex items-center gap-3 group">
              <div className="w-10 h-10 bg-[var(--background)] border border-[var(--border-color)] p-1 rounded-lg flex items-center justify-center group-hover:border-jade-primary/30 transition-colors">
                <img 
                  src="/images/branding/trace_logo.png" 
                  alt="Trace"
                  className="w-full h-full object-contain"
                />
              </div>
              <div>
                <span className="block text-lg font-black tracking-tight text-[var(--foreground)]">Trace</span>
                <span className="block text-[9px] font-bold text-sage-secondary uppercase tracking-widest">Admin Hub</span>
              </div>
            </div>

            {/* Mobile Close Button */}
            <button 
              onClick={onClose}
              className="md:hidden p-2 text-jade-primary hover:bg-jade-primary/10 rounded-md transition-colors"
            >
              <LogOut className="w-4 h-4 rotate-180" />
            </button>
          </div>

          <nav className="space-y-1">
            <span className="block text-[9px] font-bold text-sage-secondary uppercase tracking-widest mb-4 px-4 opacity-50">Navigation</span>
            {menuItems.map((item) => {
              const isActive = pathname === item.href;
              return (
                <Link
                  key={item.href}
                  href={item.href}
                  onClick={() => onClose?.()}
                  className={`flex items-center gap-4 px-5 py-3.5 rounded-xl transition-all relative group border ${
                    isActive 
                      ? "bg-jade-primary text-white shadow-md border-transparent" 
                      : "border-transparent text-[var(--foreground)]/60 hover:text-[var(--foreground)] hover:bg-jade-primary/5"
                  }`}
                >
                  <item.icon className={`w-4 h-4 ${isActive ? "text-white" : ""}`} />
                  <span className="text-xs font-bold">{item.label}</span>
                </Link>
              );
            })}
          </nav>

          <div className="mt-auto space-y-4">
             {/* Live System Info stripped of jargon */}
             <div className="bg-[var(--background)] border border-[var(--border-color)] p-4 rounded-xl space-y-3">
                <div className="flex items-center justify-between">
                   <span className="text-[9px] font-bold text-sage-secondary uppercase tracking-wider">System Status</span>
                   <Activity className="w-3 h-3 text-jade-primary animate-pulse" />
                </div>
                <div className="flex items-center gap-2">
                   <div className="h-1 bg-jade-primary w-full rounded-full" />
                </div>
             </div>

            <div className="pt-4 border-t border-[var(--border-color)] space-y-2">
              {/* Re-Injected Theme Toggle */}
              <button
                onClick={onToggleTheme}
                className="w-full flex items-center gap-4 px-5 py-3 bg-[var(--background)] border border-[var(--border-color)] text-[var(--foreground)] hover:border-jade-primary/50 transition-all rounded-xl text-xs font-bold group"
              >
                {theme === "light" ? <Moon className="w-4 h-4 text-jade-primary" /> : <Sun className="w-4 h-4 text-jade-primary" />}
                <span>{theme === "light" ? "Dark Mode" : "Light Mode"}</span>
              </button>

              <Link 
                href="/" 
                className="flex items-center gap-4 px-5 py-3 text-[var(--foreground)]/60 hover:text-jade-primary transition-colors text-xs font-bold group"
              >
                <Home className="w-4 h-4" />
                <span>Visit App Page</span>
              </Link>
              
              <button 
                onClick={handleLogout}
                className="w-full flex items-center gap-4 px-5 py-3 text-red-500/60 hover:text-red-500 hover:bg-red-500/5 transition-all rounded-xl text-xs font-bold group"
              >
                <LogOut className="w-4 h-4" />
                <span>Sign Out</span>
              </button>
            </div>
          </div>
        </div>
      </aside>
    </>
  );
}

