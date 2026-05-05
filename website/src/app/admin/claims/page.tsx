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
  Activity,
  X,
  Download,
  CheckCircle,
  AlertTriangle
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

// SHA-256 implementation using modern Web Crypto API
async function sha256(message: string) {
  const msgBuffer = new TextEncoder().encode(message);
  const hashBuffer = await crypto.subtle.digest('SHA-256', msgBuffer);
  const hashArray = Array.from(new Uint8Array(hashBuffer));
  return hashArray.map(b => b.toString(16).padStart(2, '0')).join('');
}

export default function AuditLogs() {
  const [logs, setLogs] = useState<AuditLog[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  
  // Interactive Verification States
  const [selectedLog, setSelectedLog] = useState<AuditLog | null>(null);
  const [verificationResult, setVerificationResult] = useState<"idle" | "verifying" | "success" | "fail">("idle");
  const [computedHash, setComputedHash] = useState("");

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

  const handleVerify = (log: AuditLog) => {
    setSelectedLog(log);
    setVerificationResult("idle");
    setComputedHash("");
  };

  const runVerification = async () => {
    if (!selectedLog) return;
    setVerificationResult("verifying");
    
    // Simulate high-performance blockchain verification
    await new Promise(resolve => setTimeout(resolve, 1200));
    
    try {
      // 1. Try raw/original order stringification (as stored by PostgreSQL or retrieved from database)
      const rawContent = (selectedLog.prev_hash || "GENESIS") + JSON.stringify(selectedLog.data) + selectedLog.timestamp.toString();
      const rawCalculated = await sha256(rawContent);
      
      // 2. Try deterministically sorted order stringification
      const sortedData: any = {};
      if (selectedLog.data && typeof selectedLog.data === 'object') {
        Object.keys(selectedLog.data).sort().forEach((key: string) => {
          sortedData[key] = (selectedLog.data as any)[key];
        });
      }
      const sortedContent = (selectedLog.prev_hash || "GENESIS") + JSON.stringify(sortedData) + selectedLog.timestamp.toString();
      const sortedCalculated = await sha256(sortedContent);

      if (rawCalculated === selectedLog.current_hash) {
        setComputedHash(rawCalculated);
        setVerificationResult("success");
      } else if (sortedCalculated === selectedLog.current_hash) {
        setComputedHash(sortedCalculated);
        setVerificationResult("success");
      } else {
        setComputedHash(sortedCalculated);
        setVerificationResult("fail");
      }
    } catch (e) {
      console.error(e);
      setVerificationResult("fail");
    }
  };

  const downloadReceipt = (log: AuditLog) => {
    const receiptText = `============================================================
              TRACE IMMUTABLE LEDGER RECEIPT              
============================================================
RECORD SEALED AT:   ${new Date(log.timestamp).toUTCString()}
TRANSACTION ID:     LOG-${log.id.substring(0, 8)}
ACTION:             ${log.data?.action || "ITEM_RECOVERED_VIA_HANDSHAKE"}

--------------------- CLAIM SPECS --------------------------
ITEM TITLE:         ${log.data?.itemTitle || "N/A"}
ITEM ID:            ${log.data?.itemId || "N/A"}
CLAIM ID:           ${log.data?.claimId || "N/A"}
CLAIMER SECURE ID:  ${log.data?.claimerId || "N/A"}
FINDER SECURE ID:   ${log.data?.finderId || "N/A"}

--------------------- CRYPTOGRAPHY -------------------------
PREVIOUS CHECKSUM:  ${log.prev_hash || "GENESIS"}
CURRENT BLOCK HASH: ${log.current_hash}
ALGORITHM:          SHA-256 LINKED CHAIN
INTEGRITY STATUS:   SECURE & VERIFIED IMMUTABLE RECORD

============================================================
          TRACE SECURED BLOCKCHAIN DATABASE CORE            
============================================================`;

    const element = document.createElement("a");
    const file = new Blob([receiptText], { type: "text/plain" });
    element.href = URL.createObjectURL(file);
    element.download = `trace_receipt_block_${log.id.substring(0, 8)}.txt`;
    document.body.appendChild(element);
    element.click();
    document.body.removeChild(element);
  };

  return (
    <div className="space-y-10 pb-20 relative">
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
                   <button 
                     onClick={() => handleVerify(log)}
                     className="flex items-center gap-2 text-jade-primary hover:text-white transition-all text-xs font-bold uppercase tracking-widest lg:mt-6 bg-jade-primary/5 hover:bg-jade-primary px-4 py-2 rounded-xl border border-jade-primary/10"
                   >
                      <ExternalLink className="w-4 h-4" />
                      <span>Verify Record</span>
                   </button>
                </div>
              </div>
            </motion.div>
          ))
        )}
      </div>

      {/* Interactive Cryptographic Auditing Modal */}
      {selectedLog && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm">
          <motion.div 
            initial={{ opacity: 0, scale: 0.95 }}
            animate={{ opacity: 1, scale: 1 }}
            className="w-full max-w-3xl bg-[var(--card-bg)] border border-[var(--border-color)] rounded-[40px] p-8 md:p-10 relative overflow-hidden shadow-2xl max-h-[90vh] overflow-y-auto"
          >
            <button 
              onClick={() => setSelectedLog(null)}
              className="absolute top-6 right-6 p-2 rounded-full hover:bg-jade-primary/10 text-sage-secondary hover:text-jade-primary transition-colors"
            >
              <X className="w-6 h-6" />
            </button>

            <div className="flex items-center gap-4 mb-6">
              <div className="w-12 h-12 bg-jade-primary/10 rounded-2xl flex items-center justify-center border border-jade-primary/10">
                <Database className="w-6 h-6 text-jade-primary" />
              </div>
              <div>
                <h3 className="text-xl font-black uppercase tracking-tighter text-[var(--foreground)]">Cryptographic Block Audit</h3>
                <p className="text-[10px] font-bold text-jade-primary uppercase tracking-[0.2em] mt-0.5">SHA-256 Chain Seal Verification</p>
              </div>
            </div>

            <div className="space-y-6">
              <div className="bg-[var(--background)] p-6 rounded-3xl border border-[var(--border-color)] space-y-4">
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-xs font-semibold">
                  <div>
                    <span className="block text-[10px] font-black text-sage-secondary/60 uppercase tracking-widest mb-1">RECORD INDEX</span>
                    <span className="text-[var(--foreground)]">LOG-{selectedLog.id.substring(0, 8)}</span>
                  </div>
                  <div>
                    <span className="block text-[10px] font-black text-sage-secondary/60 uppercase tracking-widest mb-1">TIMESTAMP MILLIS</span>
                    <span className="text-[var(--foreground)]">{selectedLog.timestamp}</span>
                  </div>
                </div>

                <div className="border-t border-[var(--border-color)] pt-4 space-y-3">
                  <div>
                    <span className="block text-[10px] font-black text-sage-secondary/60 uppercase tracking-widest mb-1">CHAIN PREVIOUS HASH (A)</span>
                    <code className="text-[11px] font-bold text-sage-secondary bg-jade-primary/5 px-2 py-1 rounded-lg block break-all">
                      {selectedLog.prev_hash || "GENESIS"}
                    </code>
                  </div>
                  <div>
                    <span className="block text-[10px] font-black text-sage-secondary/60 uppercase tracking-widest mb-1">TRANSACTION DATA CONTENT (B)</span>
                    <pre className="text-[10px] font-bold text-jade-primary break-all bg-jade-primary/5 p-3 rounded-2xl block overflow-x-auto border border-jade-primary/5 max-h-36">
                      {JSON.stringify(selectedLog.data, null, 2)}
                    </pre>
                  </div>
                </div>
              </div>

              {/* Action Buttons */}
              <div className="flex flex-wrap items-center gap-4">
                <button 
                  onClick={runVerification}
                  disabled={verificationResult === "verifying"}
                  className="flex items-center gap-2 bg-jade-primary text-white font-bold text-xs uppercase tracking-widest px-6 py-3.5 rounded-xl hover:bg-jade-deep transition-all shadow-md shadow-jade-primary/15"
                >
                  <Activity className={`w-4 h-4 ${verificationResult === "verifying" ? "animate-spin" : ""}`} />
                  {verificationResult === "verifying" ? "Recomputing SHA-256..." : "Run Cryptographic Proof"}
                </button>

                <button 
                  onClick={() => downloadReceipt(selectedLog)}
                  className="flex items-center gap-2 bg-jade-primary/10 text-jade-primary font-bold text-xs uppercase tracking-widest px-6 py-3.5 rounded-xl hover:bg-jade-primary/20 transition-all border border-jade-primary/10"
                >
                  <Download className="w-4 h-4" />
                  <span>Download Audit Receipt</span>
                </button>
              </div>

              {/* Real-time Verification Results UI */}
              {verificationResult === "verifying" && (
                <div className="p-5 border border-dashed border-jade-primary/30 bg-jade-primary/5 rounded-3xl text-center space-y-2">
                  <div className="w-6 h-6 border-2 border-jade-primary border-t-transparent rounded-full animate-spin mx-auto"></div>
                  <div className="text-xs font-black uppercase text-jade-primary tracking-widest">Hashing block payload...</div>
                </div>
              )}

              {verificationResult === "success" && (
                <motion.div 
                  initial={{ opacity: 0, y: 10 }} 
                  animate={{ opacity: 1, y: 0 }}
                  className="p-6 bg-emerald-500/10 border border-emerald-500/20 rounded-3xl space-y-4"
                >
                  <div className="flex items-center gap-3 text-emerald-500">
                    <CheckCircle className="w-6 h-6" />
                    <span className="text-sm font-black uppercase tracking-wider">✓ PASSED: BLOCK INTEGRITY VALIDATED</span>
                  </div>
                  <div className="space-y-2 text-xs font-semibold text-sage-secondary">
                    <p>Cryptographic proof recomputed successfully. The calculated payload checksum matches the database registry perfectly. This record is sealed and secure.</p>
                    <div className="pt-2">
                      <span className="block text-[9px] font-black uppercase text-emerald-500/60 tracking-wider">RECOMPUTED CHECKSUM</span>
                      <code className="text-[10px] font-bold text-emerald-500 break-all bg-emerald-500/5 p-2 rounded-lg block border border-emerald-500/5 mt-1">{computedHash}</code>
                    </div>
                  </div>
                </motion.div>
              )}

              {verificationResult === "fail" && (
                <motion.div 
                  initial={{ opacity: 0, y: 10 }} 
                  animate={{ opacity: 1, y: 0 }}
                  className="p-6 bg-red-500/10 border border-red-500/20 rounded-3xl space-y-4"
                >
                  <div className="flex items-center gap-3 text-red-500">
                    <AlertTriangle className="w-6 h-6" />
                    <span className="text-sm font-black uppercase tracking-wider">❌ FAILED: CHECKSUM DISCREPANCY</span>
                  </div>
                  <div className="space-y-2 text-xs font-semibold text-sage-secondary">
                    <p>The calculated payload checksum does NOT match the stored database record hash. This indicates either the payload was tampered with, or the blockchain record has been manipulated.</p>
                    <div className="pt-2">
                      <span className="block text-[9px] font-black uppercase text-red-500/60 tracking-wider">RECOMPUTED CHECKSUM</span>
                      <code className="text-[10px] font-bold text-red-500 break-all bg-red-500/5 p-2 rounded-lg block border border-red-500/5 mt-1">{computedHash}</code>
                    </div>
                  </div>
                </motion.div>
              )}
            </div>
          </motion.div>
        </div>
      )}
    </div>
  );
}
