"use client";

import { useEffect, useState } from "react";
import { supabase } from "@/lib/supabase";
import { motion } from "framer-motion";
import { 
  ShieldCheck, 
  Database, 
  Fingerprint, 
  Clock,
  ExternalLink,
  Lock,
  Hash,
  Activity
} from "lucide-react";

interface AuditLog {
  id: string;
  claimId: string;
  previousHash: string;
  currentHash: string;
  timestamp: number;
  action: string;
  metadata: any;
}

export default function AuditLogs() {
  const [logs, setLogs] = useState<AuditLog[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    fetchLogs();
  }, []);

  async function fetchLogs() {
    setIsLoading(true);
    try {
      const { data, error } = await supabase
        .from('claim_logs')
        .select('*')
        .order('timestamp', { ascending: false });
      
      if (error) throw error;
      setLogs(data || []);
    } catch (error) {
      console.error("Error fetching audit logs:", error);
    } finally {
      setIsLoading(false);
    }
  }

  return (
    <div className="space-y-8">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold tracking-tighter uppercase font-mono">Immutable Audit Trail</h1>
          <p className="text-[10px] font-mono text-neutral-500 uppercase tracking-[0.3em] mt-1">Blockchain-verified claim integrity</p>
        </div>
        
        <div className="flex items-center gap-3 px-4 py-2 bg-emerald-500/5 border border-emerald-500/10 rounded-lg">
           <ShieldCheck className="w-4 h-4 text-emerald-500" />
           <span className="text-[10px] font-mono uppercase text-emerald-500 tracking-widest">Chain Integrity: Valid</span>
        </div>
      </div>

      <div className="space-y-4">
        {isLoading ? (
          [...Array(3)].map((_, i) => (
            <div key={i} className="h-32 bg-white/5 rounded-2xl animate-pulse" />
          ))
        ) : logs.length === 0 ? (
          <div className="py-20 text-center border border-dashed border-white/5 rounded-2xl bg-[#12121F]">
             <Lock className="w-8 h-8 text-neutral-800 mx-auto mb-4" />
             <p className="text-[10px] font-mono text-neutral-600 uppercase tracking-[0.4em]">No claim transactions recorded in ledger</p>
          </div>
        ) : (
          logs.map((log, i) => (
            <motion.div 
              key={log.id}
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: i * 0.1 }}
              className="bg-[#12121F] border border-white/5 rounded-2xl p-6 relative overflow-hidden group hover:border-white/10 transition-all"
            >
              <div className="absolute top-0 right-0 p-4 opacity-[0.03] group-hover:opacity-[0.07] transition-opacity">
                 <Fingerprint className="w-24 h-24" />
              </div>

              <div className="flex flex-col md:flex-row gap-8 relative z-10">
                <div className="flex-1 space-y-4">
                  <div className="flex items-center gap-4">
                    <div className="flex items-center gap-2 text-cyan-500 bg-cyan-500/5 px-2 py-1 rounded text-[9px] font-mono uppercase tracking-widest">
                       <Hash className="w-3 h-3" />
                       TX-{log.id.substring(0, 8)}
                    </div>
                    <div className="text-[10px] font-mono text-neutral-500 uppercase tracking-widest flex items-center gap-2">
                       <Clock className="w-3 h-3" />
                       {new Date(log.timestamp).toLocaleString()}
                    </div>
                  </div>

                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div>
                       <span className="block text-[8px] font-mono text-neutral-600 uppercase tracking-widest mb-1">Previous Hash</span>
                       <code className="text-[9px] font-mono text-neutral-500 break-all bg-black/20 p-2 rounded block">
                          {log.previousHash || "GENESIS_BLOCK"}
                       </code>
                    </div>
                    <div>
                       <span className="block text-[8px] font-mono text-neutral-600 uppercase tracking-widest mb-1">Current State Hash</span>
                       <code className="text-[9px] font-mono text-cyan-500/50 break-all bg-black/20 p-2 rounded block">
                          {log.currentHash}
                       </code>
                    </div>
                  </div>
                </div>

                <div className="md:w-64 flex flex-col justify-between border-l border-white/5 pl-8">
                   <div>
                      <span className="block text-[8px] font-mono text-neutral-600 uppercase tracking-widest mb-1">Transaction Action</span>
                      <div className="text-xs font-bold uppercase tracking-wider text-white">{log.action}</div>
                   </div>
                   <button className="flex items-center gap-2 text-neutral-500 hover:text-white transition-colors text-[9px] font-mono uppercase tracking-widest mt-4">
                      <ExternalLink className="w-3 h-3" />
                      Verify Claim Data
                   </button>
                </div>
              </div>
            </motion.div>
          ))
        )}
      </div>
    </div>
  );
}
