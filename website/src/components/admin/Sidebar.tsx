"use client";

import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { 
  LayoutDashboard, 
  Users, 
  Flag, 
  ShieldCheck, 
  LogOut,
  FileText,
  History,
  Shield,
  Sun,
  Moon
} from "lucide-react";
import { motion, AnimatePresence } from "framer-motion";
import { auth } from "@/lib/firebase";
import { signOut } from "firebase/auth";

const menuItems = [
  { icon: LayoutDashboard, label: "Overview", href: "/admin" },
  { icon: FileText, label: "Posts Registry", href: "/admin/posts" },
  { icon: History, label: "Activity Logs", href: "/admin/claims" },
  { icon: Users, label: "User Directory", href: "/admin/users" },
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
            className="fixed inset-0 bg-black/40 backdrop-blur-sm z-[60] md:hidden"
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
          <div className="flex items-center justify-between mb-12">
            <div className="flex items-center gap-3 group">
              <div className="w-10 h-10 bg-jade-primary/10 rounded-xl flex items-center justify-center">
                <Shield className="w-5 h-5 text-jade-primary" />
              </div>
              <div>
                <span className="block text-lg font-black tracking-tighter text-[var(--foreground)] uppercase">Trace<span className="text-jade-primary">.</span></span>
                <span className="block text-[8px] font-bold text-sage-secondary tracking-[0.3em] uppercase">Control Panel</span>
              </div>
            </div>

            {/* Mobile Close Button */}
            <button 
              onClick={onClose}
              className="md:hidden p-2 text-jade-primary/60 hover:text-jade-primary transition-colors"
            >
              <LogOut className="w-4 h-4 rotate-180" />
            </button>
          </div>

          <nav className="space-y-2">
            {menuItems.map((item) => {
              const isActive = pathname === item.href;
              return (
                <Link
                  key={item.href}
                  href={item.href}
                  onClick={() => onClose?.()}
                  className={`flex items-center gap-4 px-6 py-4 rounded-2xl transition-all relative group ${
                    isActive 
                      ? "bg-jade-primary text-white shadow-lg shadow-jade-primary/20" 
                      : "text-jade-primary/60 hover:text-jade-primary hover:bg-jade-primary/5"
                  }`}
                >
                  <item.icon className={`w-5 h-5 ${isActive ? "text-white" : "group-hover:text-jade-primary transition-colors"}`} />
                  <span className="text-xs font-bold uppercase tracking-wider">{item.label}</span>
                </Link>
              );
            })}
          </nav>

          <div className="mt-auto space-y-4">
            {/* Theme Toggle */}
            <button
              onClick={onToggleTheme}
              className="w-full flex items-center gap-4 px-6 py-4 rounded-2xl bg-jade-primary/5 text-jade-primary hover:bg-jade-primary/10 transition-all group"
            >
              {theme === "light" ? <Moon className="w-5 h-5" /> : <Sun className="w-5 h-5" />}
              <span className="text-xs font-bold uppercase tracking-wider">{theme === "light" ? "Dark Mode" : "Light Mode"}</span>
            </button>

            <div className="pt-6 border-t border-[var(--border-color)] space-y-2">
              <Link 
                href="/" 
                className="flex items-center gap-4 px-6 py-4 text-jade-primary/40 hover:text-jade-primary transition-colors text-[10px] font-bold uppercase tracking-widest group"
              >
                <Shield className="w-4 h-4 group-hover:scale-110 transition-transform" />
                <span>Public Portal</span>
              </Link>
              
              <button 
                onClick={handleLogout}
                className="w-full flex items-center gap-4 px-6 py-4 text-red-500/60 hover:text-red-500 hover:bg-red-500/5 rounded-2xl transition-all text-xs font-bold uppercase tracking-wider group"
              >
                <LogOut className="w-5 h-5 group-hover:translate-x-1 transition-transform" />
                <span>Sign Out</span>
              </button>
            </div>
          </div>
        </div>
      </aside>
    </>
  );
}
