"use client";

import { Search, Activity, Menu } from "lucide-react";
import { useState } from "react";

export default function AdminHeader() {
  return (
    <header className="h-20 border-b border-white/5 flex items-center justify-between px-6 md:px-10 sticky top-0 z-20 bg-[#0A0A14]/80 backdrop-blur-md">
      <div className="flex items-center gap-4">
        <button className="md:hidden p-2 -ml-2 text-neutral-500 hover:text-white">
          <Menu className="w-5 h-5" />
        </button>
        <div className="hidden sm:flex text-[8px] font-mono text-neutral-500 border border-white/5 bg-white/5 px-2 py-1 rounded-sm uppercase tracking-[0.4em] items-center gap-2">
          <div className="w-1.5 h-1.5 bg-emerald-500 rounded-full animate-pulse shadow-[0_0_8px_rgba(16,185,129,0.5)]"></div>
          UPLINK_SECURE
        </div>
      </div>
      
      <div className="flex items-center gap-4 md:gap-6">
        <div className="hidden lg:flex bg-[#12121F] border border-white/5 rounded-lg px-4 py-2 items-center gap-2 w-64 focus-within:border-cyan-500/50 transition-colors">
          <Search className="w-3 h-3 text-neutral-600" />
          <input 
            type="text" 
            placeholder="Global_Search..." 
            className="bg-transparent text-[10px] font-mono uppercase tracking-widest outline-none w-full placeholder:text-neutral-700"
          />
        </div>
        <div className="flex items-center gap-3">
          <div className="text-right hidden sm:block">
            <div className="text-[10px] font-bold font-mono uppercase tracking-wider">Administrator</div>
            <div className="text-[8px] font-mono text-cyan-500/70 tracking-widest uppercase">Root Access</div>
          </div>
          <div className="w-8 h-8 bg-cyan-500/10 border border-cyan-500/20 rounded-lg flex items-center justify-center text-[10px] font-bold font-mono text-cyan-500">
            AD
          </div>
        </div>
      </div>
    </header>
  );
}
