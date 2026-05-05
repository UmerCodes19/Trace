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
  claim_id: string;
  prev_hash: string;
  current_hash: string;
  timestamp: number;
  data: {
    action: string;
    claimId: string;
    itemId: string;
    itemTitle: string;
    claimerId: string;
    finderId: string;
    timestamp: number;
  };
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
    <div className="space-y-10 pb-20">
      <div className="flex flex-col md:flex-row md:items-end justify-between gap-6 border-b border-[var(--border-color)] pb-10">
        <motion.div initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }}>
          <h1 className="text-4xl font-black tracking-tighter uppercase text-[var(--foreground)]">Activity <span className="text-jade-primary">Logs</span></h1>
          <p className="text-sm text-jade-primary/60 font-bold uppercase tracking-widest mt-2">Historical Record of Claims & Operations</p>
        </motion.div>
        
        <div className="flex items-center gap-3 px-5 py-2.5 bg-jade-primary/5 border border-jade-primary/10 rounded-2xl shadow-sm">
           <ShieldCheck className="w-5 h-5 text-jade-primary" />
           <span className="text-[10px] font-black uppercase text-jade-primary tracking-widest">System Integrity Verified</span>
        </div>
      </div>

      <div className="grid grid-cols-1 gap-6">
        {isLoading ? (
          [...Array(3)].map((_, i) => (
            <div key={i} className="h-40 bg-jade-primary/5 rounded-[40px] animate-pulse" />
          ))
        ) : logs.length === 0 ? (
          <div className="py-24 text-center border border-dashed border-jade-primary/20 rounded-[40px] bg-jade-primary/5">
             <Lock className="w-12 h-12 text-jade-primary/20 mx-auto mb-6" />
             <p className="text-xs font-bold text-jade-primary/40 uppercase tracking-[0.3em]">No activity logs found in system registry</p>
          </div>
        ) : (
          logs.map((log, i) => (
            <motion.div 
              key={log.id}
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: i * 0.05 }}
              className="bg-[var(--card-bg)] border border-[var(--border-color)] rounded-[40px] p-8 relative overflow-hidden group hover:border-jade-primary/30 transition-all shadow-xl shadow-black/5"
            >
              <div className="absolute top-0 right-0 p-6 opacity-[0.03] group-hover:opacity-[0.08] transition-opacity">
                 <Fingerprint className="w-32 h-32" />
              </div>

              <div className="flex flex-col lg:flex-row gap-8 relative z-10">
                <div className="flex-1 space-y-6">
                  <div className="flex flex-wrap items-center gap-4">
                    <div className="flex items-center gap-2 text-jade-primary bg-jade-primary/10 border border-jade-primary/10 px-4 py-1.5 rounded-full text-[10px] font-black uppercase tracking-widest">
                       <Hash className="w-3.5 h-3.5" />
                       LOG-{log.id.substring(0, 8)}
                    </div>
                    <div className="text-[10px] font-bold text-sage-secondary uppercase tracking-widest flex items-center gap-2">
                       <Clock className="w-4 h-4" />
                       {new Date(log.timestamp).toLocaleString()}
                    </div>
                  </div>

                  <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                    <div>
                       <span className="block text-[9px] font-black text-jade-primary/30 uppercase tracking-widest mb-2">Previous Checksum</span>
                       <code className="text-[10px] font-bold text-jade-primary/60 break-all bg-jade-primary/5 p-3 rounded-2xl block border border-jade-primary/5">
                          {log.prev_hash || "INITIAL_STATE"}
                       </code>
                    </div>
                    <div>
                       <span className="block text-[9px] font-black text-jade-primary/30 uppercase tracking-widest mb-2">Operation Hash</span>
                       <code className="text-[10px] font-bold text-jade-primary break-all bg-jade-primary/10 p-3 rounded-2xl block border border-jade-primary/10">
                          {log.current_hash}
                       </code>
                    </div>
                  </div>
                </div>

                <div className="lg:w-72 flex flex-row lg:flex-col justify-between items-center lg:items-start border-t lg:border-t-0 lg:border-l border-[var(--border-color)] pt-8 lg:pt-0 lg:pl-10">
                   <div>
                      <span className="block text-[9px] font-black text-jade-primary/30 uppercase tracking-widest mb-2">Action Performed</span>
                      <div className="text-xl font-black uppercase tracking-tighter text-[var(--foreground)]">{log.data?.action || "ITEM_RECOVERED"}</div>
                      {log.data?.itemTitle && (
                         <span className="block text-[10px] font-bold text-jade-primary mt-1 uppercase tracking-wider">
                            Item: {log.data.itemTitle}
                         </span>
                      )}
                   </div>
                   <button className="flex items-center gap-2 text-jade-primary/60 hover:text-jade-primary transition-all text-xs font-bold uppercase tracking-widest lg:mt-6 bg-jade-primary/5 px-4 py-2 rounded-xl border border-jade-primary/10">
                      <ExternalLink className="w-4 h-4" />
                      <span>Verify Record</span>
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
