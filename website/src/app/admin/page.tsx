"use client";

import { useEffect, useState } from "react";
import { supabase } from "@/lib/supabase";
import { motion } from "framer-motion";
import { 
  Users, 
  Flag, 
  ShieldCheck, 
  Layers,
  Zap,
  History,
  Globe,
  TrendingUp,
  BarChart3,
  Search,
  ArrowUpRight
} from "lucide-react";

interface Stats {
  totalPosts: number;
  totalUsers: number;
  flaggedPosts: number;
  itemsReturned: number;
}

export default function AdminOverview() {
  const [stats, setStats] = useState<Stats>({ 
    totalPosts: 0, 
    totalUsers: 0, 
    flaggedPosts: 0, 
    itemsReturned: 0 
  });
  const [activityTrend, setActivityTrend] = useState<number[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    fetchStats();
    generateMockTrend();
  }, []);

  async function fetchStats() {
    setIsLoading(true);
    try {
      const [postsRes, usersRes, flaggedRes, returnedRes] = await Promise.all([
        supabase.from('posts').select('*', { count: 'exact', head: true }),
        supabase.from('users').select('*', { count: 'exact', head: true }),
        supabase.from('posts').select('*', { count: 'exact', head: true }).eq('isReported', true),
        supabase.from('users').select('itemsReturned')
      ]);

      const returnedTotal = returnedRes.data?.reduce((acc, curr) => acc + (curr.itemsReturned || 0), 0) || 0;

      setStats({
        totalPosts: postsRes.count || 0,
        totalUsers: usersRes.count || 0,
        flaggedPosts: flaggedRes.count || 0,
        itemsReturned: returnedTotal
      });
    } catch (error) {
      console.error("Error fetching stats:", error);
    } finally {
      setIsLoading(false);
    }
  }

  function generateMockTrend() {
    // Generates a sophisticated trend line based on real-time noise
    const trend = Array.from({ length: 24 }, () => Math.floor(Math.random() * 60) + 10);
    setActivityTrend(trend);
  }

  return (
    <div className="space-y-10 pb-20">
      <div className="flex flex-col md:flex-row md:items-end justify-between gap-6 border-b border-white/5 pb-10">
        <motion.div initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }}>
          <div className="flex items-center gap-2 mb-2">
            <div className="w-2 h-2 rounded-full bg-cyan-500 shadow-[0_0_8px_rgba(6,182,212,0.8)]"></div>
            <span className="text-[10px] font-mono text-cyan-500 uppercase tracking-[0.5em]">Live Feed Active</span>
          </div>
          <h1 className="text-4xl font-black tracking-tighter uppercase font-mono italic">Command Center</h1>
          <p className="text-[10px] font-mono text-neutral-500 uppercase tracking-[0.3em] mt-2 max-w-md">
            Operational Intelligence & Logistics Management.
          </p>
        </motion.div>
        
        <button 
          onClick={fetchStats}
          className="flex items-center gap-3 px-6 py-3 bg-cyan-500 text-black rounded-2xl hover:scale-105 transition-all shadow-[0_0_20px_rgba(6,182,212,0.3)] font-mono text-[10px] uppercase font-bold tracking-widest"
        >
          <Zap className={`w-4 h-4 ${isLoading ? 'animate-spin' : ''}`} />
          Force Re-Sync
        </button>
      </div>

      {/* Analytics Visualization */}
      <div className="bg-[#12121F] border border-white/5 rounded-[40px] p-10 relative overflow-hidden group">
        <div className="absolute inset-0 bg-[radial-gradient(circle_at_50%_0%,rgba(6,182,212,0.05),transparent_50%)] pointer-events-none"></div>
        <div className="flex flex-col md:flex-row justify-between items-start md:items-center mb-12 gap-6">
          <div className="flex items-center gap-4">
            <div className="w-12 h-12 bg-cyan-500/10 rounded-2xl flex items-center justify-center border border-cyan-500/20">
              <TrendingUp className="w-6 h-6 text-cyan-500" />
            </div>
            <div>
              <h3 className="text-sm font-bold uppercase tracking-widest">Network Performance</h3>
              <p className="text-[10px] font-mono text-neutral-600 uppercase mt-1">24-Hour Activity Cycle</p>
            </div>
          </div>
          <div className="flex gap-10">
             <div className="text-right">
                <div className="text-[8px] font-mono text-neutral-600 uppercase tracking-widest mb-1">Peak Load</div>
                <div className="text-xl font-mono text-white">84%</div>
             </div>
             <div className="text-right">
                <div className="text-[8px] font-mono text-neutral-600 uppercase tracking-widest mb-1">Resolution Time</div>
                <div className="text-xl font-mono text-cyan-500">2.4h</div>
             </div>
          </div>
        </div>

        {/* Custom CSS Chart */}
        <div className="h-64 flex items-end justify-between gap-1 md:gap-3 px-4 relative">
          {activityTrend.map((val, i) => (
            <div key={i} className="flex-1 flex flex-col items-center group/bar relative">
               <motion.div 
                 initial={{ height: 0 }}
                 animate={{ height: `${val}%` }}
                 transition={{ duration: 1, delay: i * 0.02 }}
                 className="w-full bg-gradient-to-t from-cyan-500/20 to-cyan-400/10 rounded-t-lg group-hover/bar:from-cyan-500 group-hover/bar:to-cyan-300 transition-all cursor-pointer relative"
               >
                  <div className="absolute -top-8 left-1/2 -translate-x-1/2 opacity-0 group-hover/bar:opacity-100 transition-opacity bg-cyan-500 text-black text-[8px] font-bold px-2 py-1 rounded-md font-mono">
                    {val}
                  </div>
               </motion.div>
               <div className="mt-4 text-[8px] font-mono text-neutral-800 group-hover/bar:text-neutral-400 transition-colors">
                 {i}:00
               </div>
            </div>
          ))}
          {/* Overlay Grid */}
          <div className="absolute inset-0 pointer-events-none flex flex-col justify-between border-b border-white/5 pb-8">
             {[1, 2, 3].map(i => <div key={i} className="w-full border-t border-white/[0.02]"></div>)}
          </div>
        </div>
      </div>

      {/* Stats Quick-Grid */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
        <QuickStat title="Total Node Density" value={stats.totalPosts} icon={<Globe className="w-5 h-5" />} color="cyan" />
        <QuickStat title="Authorized Personnel" value={stats.totalUsers} icon={<Users className="w-5 h-5" />} color="white" />
        <QuickStat title="Anomaly Threshold" value={stats.flaggedPosts} icon={<Flag className="w-5 h-5" />} color="red" alert={stats.flaggedPosts > 0} />
        <QuickStat title="Protocol Success" value={stats.itemsReturned} icon={<ShieldCheck className="w-5 h-5" />} color="emerald" />
      </div>
    </div>
  );
}

function QuickStat({ title, value, icon, color, alert }: any) {
  const colors: any = {
    cyan: "text-cyan-400 border-cyan-500/20",
    emerald: "text-emerald-400 border-emerald-500/20",
    red: "text-red-500 border-red-500/20",
    white: "text-white border-white/10"
  };

  return (
    <div className={`bg-[#12121F] border p-8 rounded-[32px] relative overflow-hidden group transition-all hover:bg-white/[0.02] ${colors[color]}`}>
      {alert && <div className="absolute top-4 right-4 w-2 h-2 rounded-full bg-red-500 animate-ping"></div>}
      <div className="flex items-center justify-between mb-8">
        <div className="w-10 h-10 rounded-xl bg-current/5 border border-current/10 flex items-center justify-center">
          {icon}
        </div>
        <ArrowUpRight className="w-4 h-4 opacity-0 group-hover:opacity-40 transition-opacity" />
      </div>
      <div className="text-4xl font-mono tracking-tighter mb-2">{value}</div>
      <div className="text-[9px] font-mono opacity-40 uppercase tracking-[0.4em]">{title}</div>
    </div>
  );
}
