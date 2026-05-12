"use client";

import { useEffect, useState } from "react";
import { supabase } from "@/lib/supabase";
import { motion } from "framer-motion";
import { 
  Users, 
  Flag, 
  ShieldCheck, 
  Zap,
  ArrowUpRight,
  FileText,
  Lock,
  Compass,
  CheckCircle,
  AlertCircle,
  Activity
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
  const [isLoading, setIsLoading] = useState(true);
  const [validationState, setValidationState] = useState<"idle" | "validating" | "secure" | "tampered">("idle");
  const [validationMsg, setValidationMsg] = useState("");

  useEffect(() => {
    fetchStats();
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
    setValidationMsg("Checking logs for tampering...");
    
    try {
      const { data: logs, error } = await supabase
        .from('claim_logs')
        .select('*')
        .order('timestamp', { ascending: true });

      if (error) throw error;

      await new Promise(resolve => setTimeout(resolve, 1200));

      if (!logs || logs.length === 0) {
        setValidationState("secure");
        setValidationMsg("Log is empty and secure");
        return;
      }

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
        setValidationMsg(`Successfully verified ${logs.length} entries.`);
      } else {
        setValidationState("tampered");
        setValidationMsg("Warning: Log discrepancy detected");
      }
    } catch (err: any) {
      setValidationState("tampered");
      setValidationMsg("System failed to verify logs.");
    }
  }

  return (
    <div className="space-y-10 pb-20 font-sans">
      {/* HUD Header simplified */}
      <div className="flex flex-col md:flex-row md:items-end justify-between gap-6 border-b border-[var(--border-color)] pb-8">
        <motion.div initial={{ opacity: 0, y: 5 }} animate={{ opacity: 1, y: 0 }}>
          <div className="flex items-center gap-2 mb-2 text-[10px] font-bold text-jade-primary uppercase tracking-widest">
             <div className="w-2 h-2 bg-jade-primary rounded-full animate-pulse shadow-[0_0_8px_currentColor]" />
             System Online
          </div>
          <h1 className="text-4xl font-black tracking-tight uppercase text-[var(--foreground)]">
             Admin <span className="text-jade-primary">Dashboard</span>
          </h1>
        </motion.div>
        
        <button 
          onClick={fetchStats}
          disabled={isLoading}
          className="flex items-center gap-3 px-6 py-3 border border-[var(--border-color)] bg-[var(--card-bg)] text-[var(--foreground)] rounded-xl hover:border-jade-primary hover:text-jade-primary transition-all text-xs font-bold shadow-sm"
        >
          <Activity className={`w-4 h-4 ${isLoading ? 'animate-spin' : ''}`} />
          Refresh Data
        </button>
      </div>

      {/* Blockchain simplified to Safety Log Verification */}
      <div className="bg-[var(--card-bg)] border border-[var(--border-color)] rounded-2xl p-8 md:p-10 relative overflow-hidden group shadow-md grid grid-cols-1 md:grid-cols-3 gap-10">
        <div className="md:col-span-2 space-y-6">
          <div className="flex items-center gap-4">
            <div className="w-12 h-12 bg-[var(--background)] border border-[var(--border-color)] flex items-center justify-center shrink-0 rounded-xl">
              <Lock className="w-5 h-5 text-jade-primary" />
            </div>
            <div>
              <h3 className="text-lg font-bold text-[var(--foreground)]">Secure Audit Log</h3>
              <p className="text-xs text-sage-secondary mt-0.5">Maintain database integrity.</p>
            </div>
          </div>
          <p className="text-sm text-[var(--foreground)]/70 leading-relaxed max-w-xl">
            When an item is returned to its owner, we save a record in our activity log. You can scan these records here to make sure nothing has been altered.
          </p>
          <button 
            onClick={validateChain}
            disabled={validationState === "validating"}
            className="px-6 py-3 bg-jade-primary text-white rounded-xl text-xs font-bold hover:bg-jade-deep transition-all shadow-md shadow-jade-primary/10"
          >
            {validationState === "validating" ? "Scanning Logs..." : "Run Verification Scan"}
          </button>
        </div>

        <div className="flex flex-col justify-center items-center border border-dashed border-[var(--border-color)] bg-[var(--background)] rounded-xl p-8 min-h-[160px] relative">
          {validationState === "idle" && (
            <div className="text-center space-y-2 opacity-60">
              <Compass className="w-10 h-10 text-sage-secondary mx-auto animate-spin-slow" />
              <div className="text-xs font-bold text-sage-secondary">Ready to Scan</div>
            </div>
          )}
          {validationState === "validating" && (
            <div className="text-center space-y-4">
              <div className="w-6 h-6 border-2 border-jade-primary border-t-transparent rounded-full animate-spin mx-auto"></div>
              <div className="text-xs font-bold text-jade-primary animate-pulse">{validationMsg}</div>
            </div>
          )}
          {validationState === "secure" && (
            <motion.div initial={{scale:0.9}} animate={{scale:1}} className="text-center space-y-3">
              <CheckCircle className="w-10 h-10 text-emerald-500 mx-auto" />
              <div className="px-3 py-1 bg-emerald-500/10 border border-emerald-500/30 rounded-lg">
                 <div className="text-xs font-bold text-emerald-600">{validationMsg}</div>
              </div>
            </motion.div>
          )}
          {validationState === "tampered" && (
            <motion.div initial={{scale:0.9}} animate={{scale:1}} className="text-center space-y-3">
              <AlertCircle className="w-10 h-10 text-red-500 mx-auto" />
              <div className="px-3 py-1 bg-red-500/10 border border-red-500/30 rounded-lg">
                 <div className="text-xs font-bold text-red-600">{validationMsg}</div>
              </div>
            </motion.div>
          )}
        </div>
      </div>

      {/* Core Grid Metrics */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
        <QuickMetric title="Public Posts" value={stats.totalPosts} icon={<FileText className="w-4 h-4" />} color="jade" />
        <QuickMetric title="Total Users" value={stats.totalUsers} icon={<Users className="w-4 h-4" />} color="jade" />
        <QuickMetric title="Reported Content" value={stats.flaggedPosts} icon={<Flag className="w-4 h-4" />} color="red" alert={stats.flaggedPosts > 0} />
        <QuickMetric title="Items Returned" value={stats.itemsReturned} icon={<ShieldCheck className="w-4 h-4" />} color="jade" />
      </div>

      {/* Structural Insight Matrix simplified */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6 pt-4">
        <InsightBox title="Lost Item Reports" count={stats.totalLost} desc="Items that students have currently listed as missing." />
        <InsightBox title="Found Item Reports" count={stats.totalFound} desc="Items currently found and waiting for an owner." />
        <InsightBox title="Success Rate" count={`${stats.successRate}%`} desc="Percentage of lost items that have been safely returned." isHighlight />
      </div>
    </div>
  );
}

function QuickMetric({ title, value, icon, color, alert }: any) {
  const isRed = color === "red";
  return (
    <div className={`bg-[var(--card-bg)] border border-[var(--border-color)] p-6 rounded-2xl relative overflow-hidden group transition-all hover:border-jade-primary/30 shadow-sm`}>
      {alert && <div className="absolute top-4 right-4 w-2 h-2 rounded-full bg-red-500 animate-ping"></div>}
      <div className="flex items-center justify-between mb-6">
        <div className={`w-10 h-10 border border-[var(--border-color)] rounded-xl flex items-center justify-center text-sage-secondary group-hover:text-jade-primary transition-colors ${isRed && 'text-red-500/70'}`}>
          {icon}
        </div>
        <ArrowUpRight className="w-4 h-4 text-sage-secondary/40 group-hover:text-jade-primary transition-all" />
      </div>
      <div className="text-4xl font-black tracking-tight text-[var(--foreground)] mb-1">{value}</div>
      <div className="text-xs font-bold text-sage-secondary">{title}</div>
    </div>
  );
}

function InsightBox({ title, count, desc, isHighlight }: any) {
  return (
     <div className={`bg-[var(--card-bg)] border border-[var(--border-color)] p-8 rounded-2xl shadow-sm relative overflow-hidden`}>
        <div className="text-xs font-bold text-sage-secondary mb-4">{title}</div>
        <div className={`text-5xl font-black tracking-tight mb-3 ${isHighlight ? 'text-jade-primary' : 'text-[var(--foreground)]'}`}>{count}</div>
        <p className="text-xs text-sage-secondary font-medium leading-relaxed">{desc}</p>
     </div>
  );
}
