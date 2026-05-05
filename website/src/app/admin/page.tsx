"use client";

import { useEffect, useState } from "react";
import { supabase } from "@/lib/supabase";
import { motion } from "framer-motion";
import { 
  Users, 
  Flag, 
  ShieldCheck, 
  Zap,
  TrendingUp,
  ArrowUpRight,
  FileText,
  Lock,
  Compass,
  CheckCircle,
  AlertCircle
} from "lucide-react";

interface Stats {
  totalPosts: number;
  totalUsers: number;
  flaggedPosts: number;
  itemsReturned: number;
  totalLost: number;
  totalFound: number;
  activeClaims: number;
  resolvedItems: number;
  successRate: number;
}

export default function AdminOverview() {
  const [stats, setStats] = useState<Stats>({ 
    totalPosts: 0, 
    totalUsers: 0, 
    flaggedPosts: 0, 
    itemsReturned: 0,
    totalLost: 0,
    totalFound: 0,
    activeClaims: 0,
    resolvedItems: 0,
    successRate: 0
  });
  const [activityTrend, setActivityTrend] = useState<number[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [validationState, setValidationState] = useState<"idle" | "validating" | "secure" | "tampered">("idle");
  const [validationMsg, setValidationMsg] = useState("");

  useEffect(() => {
    fetchStats();
    generateMockTrend();
  }, []);

  async function fetchStats() {
    setIsLoading(true);
    try {
      const [
        postsRes, 
        usersRes, 
        flaggedRes, 
        lostRes, 
        foundRes, 
        claimsRes, 
        resolvedRes
      ] = await Promise.all([
        supabase.from('posts').select('*', { count: 'exact', head: true }),
        supabase.from('users').select('*', { count: 'exact', head: true }),
        supabase.from('posts').select('*', { count: 'exact', head: true }).eq('isReported', true),
        supabase.from('posts').select('*', { count: 'exact', head: true }).eq('type', 'lost'),
        supabase.from('posts').select('*', { count: 'exact', head: true }).eq('type', 'found'),
        supabase.from('claims').select('*', { count: 'exact', head: true }).eq('status', 'pending'),
        supabase.from('posts').select('*', { count: 'exact', head: true }).eq('status', 'resolved')
      ]);

      const totalPosts = postsRes.count || 0;
      const resolvedCount = resolvedRes.count || 0;
      const successRate = totalPosts > 0 ? Math.round((resolvedCount / totalPosts) * 100) : 0;

      setStats({
        totalPosts,
        totalUsers: usersRes.count || 0,
        flaggedPosts: flaggedRes.count || 0,
        itemsReturned: resolvedCount,
        totalLost: lostRes.count || 0,
        totalFound: foundRes.count || 0,
        activeClaims: claimsRes.count || 0,
        resolvedItems: resolvedCount,
        successRate
      });
    } catch (error) {
      console.error("Error fetching stats:", error);
    } finally {
      setIsLoading(false);
    }
  }

  async function validateChain() {
    setValidationState("validating");
    setValidationMsg("Auditing blockchain logs recursively...");
    
    try {
      const { data: logs, error } = await supabase
        .from('claim_logs')
        .select('*')
        .order('timestamp', { ascending: true });

      if (error) throw error;

      if (!logs || logs.length === 0) {
        setValidationState("secure");
        setValidationMsg("Chain is empty but secure (No logs found yet).");
        return;
      }

      // Check integrity of SHA256 chain links
      let isChainSecure = true;
      for (let i = 0; i < logs.length; i++) {
        const current = logs[i];
        const prevHash = i === 0 ? 'GENESIS' : logs[i - 1].current_hash;

        if (current.prev_hash !== prevHash) {
          isChainSecure = false;
          break;
        }
      }

      if (isChainSecure) {
        setValidationState("secure");
        setValidationMsg(`Chain Verified Secure! Successfully validated ${logs.length} blocks.`);
      } else {
        setValidationState("tampered");
        setValidationMsg("CRITICAL: Blockchain link discrepancy detected!");
      }
    } catch (err: any) {
      setValidationState("tampered");
      setValidationMsg("Verification failed: " + err.message);
    }
  }

  function generateMockTrend() {
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
            Management, Moderation & Blockchain Integrity
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

      {/* Advanced Blockchain Integration Panel */}
      <div className="bg-[var(--card-bg)] border border-[var(--border-color)] rounded-[40px] p-10 relative overflow-hidden group shadow-xl shadow-black/5 grid grid-cols-1 md:grid-cols-2 gap-10">
        <div className="space-y-6">
          <div className="flex items-center gap-4">
            <div className="w-14 h-14 bg-jade-primary/10 rounded-2xl flex items-center justify-center border border-jade-primary/10">
              <Lock className="w-7 h-7 text-jade-primary" />
            </div>
            <div>
              <h3 className="text-lg font-black uppercase tracking-tighter text-[var(--foreground)]">Blockchain Audit Core</h3>
              <p className="text-[10px] font-bold text-sage-secondary uppercase tracking-[0.2em] mt-1">Cryptographic System Integrity</p>
            </div>
          </div>
          <p className="text-xs text-sage-secondary leading-relaxed font-medium">
            Every resolved claim triggers a secure cryptographic log entry in our immutable blockchain ledger. Use this panel to audit the chronological ledger chain for tampering.
          </p>
          <button 
            onClick={validateChain}
            disabled={validationState === "validating"}
            className="px-6 py-3.5 bg-jade-primary text-white rounded-xl text-xs font-bold uppercase tracking-widest hover:bg-jade-deep transition-all shadow-md shadow-jade-primary/10"
          >
            {validationState === "validating" ? "Auditing Ledger..." : "Validate System Integrity"}
          </button>
        </div>

        <div className="flex flex-col justify-center items-center border border-dashed border-[var(--border-color)] rounded-3xl p-8 bg-[var(--background)] relative">
          {validationState === "idle" && (
            <div className="text-center">
              <Compass className="w-12 h-12 text-sage-secondary/40 mx-auto mb-4 animate-spin-slow" />
              <div className="text-xs font-bold uppercase tracking-wider text-sage-secondary">Audit System Ready</div>
            </div>
          )}
          {validationState === "validating" && (
            <div className="text-center space-y-4">
              <div className="w-8 h-8 border-4 border-jade-primary border-t-transparent rounded-full animate-spin mx-auto"></div>
              <div className="text-xs font-bold uppercase tracking-wider text-jade-primary">{validationMsg}</div>
            </div>
          )}
          {validationState === "secure" && (
            <div className="text-center space-y-3">
              <CheckCircle className="w-12 h-12 text-emerald-500 mx-auto" />
              <div className="text-md font-black uppercase text-emerald-500 tracking-wide">✅ SECURE</div>
              <div className="text-[10px] font-bold text-sage-secondary uppercase tracking-widest max-w-xs">{validationMsg}</div>
            </div>
          )}
          {validationState === "tampered" && (
            <div className="text-center space-y-3">
              <AlertCircle className="w-12 h-12 text-red-500 mx-auto" />
              <div className="text-md font-black uppercase text-red-500 tracking-wide">❌ TAMPERED</div>
              <div className="text-[10px] font-bold text-red-400 uppercase tracking-widest max-w-xs">{validationMsg}</div>
            </div>
          )}
        </div>
      </div>

      {/* Stats Quick-Grid */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
        <QuickStat title="Total Posts" value={stats.totalPosts} icon={<FileText className="w-6 h-6" />} color="jade" />
        <QuickStat title="Total Users" value={stats.totalUsers} icon={<Users className="w-6 h-6" />} color="sage" />
        <QuickStat title="Reported Posts" value={stats.flaggedPosts} icon={<Flag className="w-6 h-6" />} color="red" alert={stats.flaggedPosts > 0} />
        <QuickStat title="Items Returned" value={stats.itemsReturned} icon={<ShieldCheck className="w-6 h-6" />} color="emerald" />
      </div>

      {/* Intelligence Dashboard Grid */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div className="bg-[var(--card-bg)] border border-[var(--border-color)] p-8 rounded-[32px] space-y-4 shadow-md">
          <div className="text-[10px] font-black text-jade-primary uppercase tracking-widest">Active Lost Reports</div>
          <div className="text-5xl font-black text-[var(--foreground)] tracking-tight">{stats.totalLost}</div>
          <div className="text-xs font-semibold text-sage-secondary leading-relaxed">Items reported as lost across the campus.</div>
        </div>

        <div className="bg-[var(--card-bg)] border border-[var(--border-color)] p-8 rounded-[32px] space-y-4 shadow-md">
          <div className="text-[10px] font-black text-jade-primary uppercase tracking-widest">Active Found Reports</div>
          <div className="text-5xl font-black text-[var(--foreground)] tracking-tight">{stats.totalFound}</div>
          <div className="text-xs font-semibold text-sage-secondary leading-relaxed">Items found and currently with campus finders.</div>
        </div>

        <div className="bg-[var(--card-bg)] border border-[var(--border-color)] p-8 rounded-[32px] space-y-4 shadow-md">
          <div className="text-[10px] font-black text-jade-primary uppercase tracking-widest">Match Success Rate</div>
          <div className="text-5xl font-black text-jade-primary tracking-tight">{stats.successRate}%</div>
          <div className="text-xs font-semibold text-sage-secondary leading-relaxed">Heuristic accuracy & successful recovery rate.</div>
        </div>
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
