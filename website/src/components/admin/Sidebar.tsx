"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { 
  LayoutDashboard, 
  Users, 
  Flag, 
  ShieldCheck, 
  LogOut,
  Terminal,
  Activity,
  Database
} from "lucide-react";
import { motion } from "framer-motion";

const menuItems = [
  { icon: LayoutDashboard, label: "Overview", href: "/admin" },
  { icon: Flag, label: "Moderation", href: "/admin/posts" },
  { icon: ShieldCheck, label: "Audit Logs", href: "/admin/claims" },
  { icon: Users, label: "Personnel", href: "/admin/users" },
];

export default function Sidebar() {
  const pathname = usePathname();

  return (
    <aside className="hidden md:flex flex-col w-[280px] bg-[#12121F] border-r border-white/5 shrink-0">
      <div className="p-8">
        <div className="flex items-center gap-3 mb-12 group">
          <div className="w-8 h-8 border border-white/10 bg-[#0A0A14] flex items-center justify-center relative overflow-hidden">
            <div className="absolute inset-0 bg-cyan-500/10 glow-cyan-accent opacity-20"></div>
            <Terminal className="w-4 h-4 text-cyan-500 relative z-10 group-hover:scale-110 transition-transform" />
          </div>
          <div>
            <span className="block text-sm font-bold tracking-[0.2em] uppercase font-mono">Trace</span>
            <span className="block text-[8px] font-medium text-neutral-600 tracking-[0.4em] uppercase">Control Center</span>
          </div>
        </div>

        <nav className="space-y-1">
          {menuItems.map((item) => {
            const isActive = pathname === item.href;
            return (
              <Link
                key={item.href}
                href={item.href}
                className={`flex items-center gap-3 px-6 py-4 rounded-lg transition-all relative group ${
                  isActive 
                    ? "bg-cyan-500/5 text-cyan-500" 
                    : "text-neutral-500 hover:text-white"
                }`}
              >
                {isActive && (
                  <motion.div 
                    layoutId="sidebar-active"
                    className="absolute left-0 top-2 bottom-2 w-[2px] bg-cyan-500 shadow-[0_0_8px_rgba(6,182,212,0.5)]" 
                  />
                )}
                <item.icon className={`w-4 h-4 ${isActive ? "text-cyan-500" : "group-hover:text-white transition-colors"}`} />
                <span className="text-[10px] font-mono uppercase tracking-[0.2em]">{item.label}</span>
              </Link>
            );
          })}
        </nav>
      </div>

      <div className="mt-auto p-8 border-t border-white/5">
        <Link 
          href="/" 
          className="flex items-center gap-3 text-neutral-500 hover:text-red-400 transition-colors text-[9px] font-mono uppercase tracking-[0.3em] group"
        >
          <LogOut className="w-4 h-4 group-hover:-translate-x-1 transition-transform" />
          <span>Exit Console</span>
        </Link>
      </div>
    </aside>
  );
}
