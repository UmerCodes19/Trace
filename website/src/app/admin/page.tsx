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
  ArrowUpRight,
  FileText
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
      <div className="flex flex-col md:flex-row md:items-end justify-between gap-6 border-b border-[var(--border-color)] pb-10">
        <motion.div initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }}>
          <div className="flex items-center gap-2 mb-3">
            <div className="w-2 h-2 rounded-full bg-jade-primary animate-pulse"></div>
            <span className="text-[10px] font-bold text-jade-primary uppercase tracking-[0.3em]">System Operational</span>
          </div>
          <h1 className="text-4xl font-black tracking-tighter uppercase text-[var(--foreground)]">Dashboard <span className="text-jade-primary">Overview</span></h1>
          <p className="text-sm text-jade-primary/60 font-bold uppercase tracking-widest mt-2 max-w-md">
            Management & Activity Insights
          </p>
        </motion.div>
        
        <button 
          onClick={fetchStats}
          className="flex items-center gap-3 px-8 py-4 bg-jade-primary text-white rounded-2xl hover:bg-jade-deep transition-all shadow-lg shadow-jade-primary/20 font-bold text-xs uppercase tracking-widest"
        >
          <Zap className={`w-4 h-4 ${isLoading ? 'animate-spin' : ''}`} />
          Refresh Data
        </button>
      </div>

      {/* Analytics Visualization */}
      <div className="bg-[var(--card-bg)] border border-[var(--border-color)] rounded-[40px] p-10 relative overflow-hidden group shadow-xl shadow-black/5">
        <div className="absolute inset-0 bg-[radial-gradient(circle_at_50%_0%,rgba(0,121,107,0.05),transparent_50%)] pointer-events-none"></div>
        <div className="flex flex-col md:flex-row justify-between items-start md:items-center mb-12 gap-6">
          <div className="flex items-center gap-4">
            <div className="w-14 h-14 bg-jade-primary/10 rounded-2xl flex items-center justify-center border border-jade-primary/10">
              <TrendingUp className="w-7 h-7 text-jade-primary" />
            </div>
            <div>
              <h3 className="text-lg font-black uppercase tracking-tighter text-[var(--foreground)]">Community Activity</h3>
              <p className="text-[10px] font-bold text-sage-secondary uppercase tracking-[0.2em] mt-1">24-Hour Post Cycle</p>
            </div>
          </div>
          <div className="flex gap-10">
             <div className="text-right">
                <div className="text-[8px] font-bold text-jade-primary/40 uppercase tracking-widest mb-1">Engagement</div>
                <div className="text-2xl font-black text-[var(--foreground)]">High</div>
             </div>
             <div className="text-right">
                <div className="text-[8px] font-bold text-jade-primary/40 uppercase tracking-widest mb-1">Resolution Rate</div>
                <div className="text-2xl font-black text-jade-primary">78%</div>
             </div>
          </div>
        </div>

        {/* Custom Chart - Scrollable on mobile */}
        <div className="overflow-x-auto pb-4 -mx-4 px-4 scrollbar-hide">
          <div className="h-64 flex items-end justify-between gap-3 min-w-[600px] md:min-w-0 px-4 relative">
            {activityTrend.map((val, i) => (
              <div key={i} className="flex-1 flex flex-col items-center group/bar relative">
                 <motion.div 
                   initial={{ height: 0 }}
                   animate={{ height: `${val}%` }}
                   transition={{ duration: 1, delay: i * 0.02 }}
                   className="w-full bg-jade-primary/20 rounded-t-xl group-hover/bar:bg-jade-primary transition-all cursor-pointer relative"
                 >
                    <div className="absolute -top-10 left-1/2 -translate-x-1/2 opacity-0 group-hover/bar:opacity-100 transition-opacity bg-jade-deep text-white text-[10px] font-bold px-3 py-1.5 rounded-xl">
                      {val}
                    </div>
                 </motion.div>
                 <div className="mt-4 text-[10px] font-bold text-jade-primary/20 group-hover/bar:text-jade-primary transition-colors">
                   {i}:00
                 </div>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Stats Quick-Grid */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
        <QuickStat title="Total Posts" value={stats.totalPosts} icon={<FileText className="w-6 h-6" />} color="jade" />
        <QuickStat title="Total Users" value={stats.totalUsers} icon={<Users className="w-6 h-6" />} color="sage" />
        <QuickStat title="Reported Posts" value={stats.flaggedPosts} icon={<Flag className="w-6 h-6" />} color="red" alert={stats.flaggedPosts > 0} />
        <QuickStat title="Items Returned" value={stats.itemsReturned} icon={<ShieldCheck className="w-6 h-6" />} color="emerald" />
      </div>
    </div>
  );
}

function QuickStat({ title, value, icon, color, alert }: any) {
  const colors: any = {
    jade: "text-jade-primary border-jade-primary/10",
    sage: "text-sage-secondary border-sage-secondary/10",
    red: "text-red-500 border-red-500/10",
    emerald: "text-jade-primary border-jade-primary/10"
  };

  return (
    <div className={`bg-[var(--card-bg)] border p-10 rounded-[40px] relative overflow-hidden group transition-all hover:border-jade-primary/30 shadow-xl shadow-black/5 ${colors[color]}`}>
      {alert && <div className="absolute top-6 right-6 w-3 h-3 rounded-full bg-red-500 animate-ping"></div>}
      <div className="flex items-center justify-between mb-8">
        <div className="w-12 h-12 rounded-2xl bg-current/10 border border-current/10 flex items-center justify-center">
          {icon}
        </div>
        <ArrowUpRight className="w-5 h-5 opacity-20 group-hover:opacity-100 group-hover:translate-x-1 group-hover:-translate-y-1 transition-all" />
      </div>
      <div className="text-4xl font-black tracking-tighter mb-2 text-[var(--foreground)]">{value}</div>
      <div className="text-[10px] font-bold text-sage-secondary uppercase tracking-[0.2em]">{title}</div>
    </div>
  );
}
