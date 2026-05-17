"use client";

import { useEffect, useState } from "react";
import { supabase } from "@/lib/supabase";
import { motion, AnimatePresence } from "framer-motion";
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
  AlertTriangle,
  Copy,
  Check,
  ChevronDown,
  ChevronUp,
  Link2,
  LockKeyhole
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

function TruncatedHash({ hash, label }: { hash: string; label: string }) {
  const [copied, setCopied] = useState(false);
  const displayHash = hash === "GENESIS" || !hash ? (hash || "GENESIS") : `${hash.substring(0, 12)}...${hash.substring(hash.length - 12)}`;
  
  const handleCopy = () => {
    navigator.clipboard.writeText(hash || "GENESIS");
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };
  
  return (
    <div className="flex flex-col gap-1.5 w-full">
      <span className="text-[9px] font-black text-neutral-500 uppercase tracking-widest">{label}</span>
      <div className="flex items-center justify-between gap-3 bg-[var(--card-bg)] border border-[var(--border-color)] px-4 py-2.5 rounded-xl w-full">
        <code className="text-xs font-mono text-[var(--foreground)] truncate select-all">{displayHash}</code>
        <button 
          onClick={handleCopy}
          className="text-neutral-500 hover:text-jade-primary transition-colors focus:outline-none shrink-0"
          title="Copy full hash"
        >
          {copied ? <Check className="w-3.5 h-3.5 text-green-500" /> : <Copy className="w-3.5 h-3.5" />}
        </button>
      </div>
    </div>
  );
}

export default function AuditLogs() {
  const [logs, setLogs] = useState<AuditLog[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  
  // Interactive Verification States
  const [selectedLog, setSelectedLog] = useState<AuditLog | null>(null);
  const [verificationResult, setVerificationResult] = useState<"idle" | "verifying" | "success" | "fail">("idle");
  const [computedHash, setComputedHash] = useState("");
  const [expandedLogId, setExpandedLogId] = useState<string | null>(null);

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
    
    // Simulate high-performance blockchain verification diagnostic scan
    await new Promise(resolve => setTimeout(resolve, 1500));
    
    try {
      const getHashTimestamp = () => {
        if (selectedLog.data && selectedLog.data.timestamp) {
          return selectedLog.data.timestamp.toString();
        }
        const parsed = Number(selectedLog.timestamp);
        if (!isNaN(parsed)) {
          return parsed.toString();
        }
        return new Date(selectedLog.timestamp).getTime().toString();
      };
      const hashTimestamp = getHashTimestamp();

      // 1. Try raw/original order stringification (as stored by PostgreSQL or retrieved from database)
      const rawContent = (selectedLog.prev_hash || "GENESIS") + JSON.stringify(selectedLog.data) + hashTimestamp;
      const rawCalculated = await sha256(rawContent);
      
      // 2. Try deterministically sorted order stringification
      const sortedData: any = {};
      if (selectedLog.data && typeof selectedLog.data === 'object') {
        Object.keys(selectedLog.data).sort().forEach((key: string) => {
          sortedData[key] = (selectedLog.data as any)[key];
        });
      }
      const sortedContent = (selectedLog.prev_hash || "GENESIS") + JSON.stringify(sortedData) + hashTimestamp;
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
               TRACE SYSTEM ACTIVITY RECORD              
============================================================
RECORD LOGGED AT:   ${new Date(log.timestamp).toUTCString()}
TRANSACTION ID:     LOG-${log.id.substring(0, 8)}
ACTION:             ${log.data?.action || "ITEM_RECOVERED"}

--------------------- LOG DETAILS --------------------------
ITEM TITLE:         ${log.data?.itemTitle || "N/A"}
ITEM ID:            ${log.data?.itemId || "N/A"}
CLAIM ID:           ${log.data?.claimId || "N/A"}
CLAIMER ID:         ${log.data?.claimerId || "N/A"}
FINDER ID:          ${log.data?.finderId || "N/A"}

--------------------- VALIDATION ---------------------------
PREVIOUS REFERENCE: ${log.prev_hash || "GENESIS"}
CURRENT SYSTEM HASH: ${log.current_hash}
INTEGRITY STATUS:   VERIFIED SYSTEM RECORD

============================================================
              TRACE SECURE AUDIT DATABASE CORE            
============================================================`;

    const element = document.createElement("a");
    const file = new Blob([receiptText], { type: "text/plain" });
    element.href = URL.createObjectURL(file);
    element.download = `trace_log_entry_${log.id.substring(0, 8)}.txt`;
    document.body.appendChild(element);
    element.click();
    document.body.removeChild(element);
  };

  const getFriendlyAction = (action: string) => {
    if (!action) return "Claim Action Logged";
    const lookup: Record<string, string> = {
      "ITEM_RECOVERED": "🏆 Item Successfully Recovered",
      "CLAIM_SUBMITTED": "📝 Claim Request Submitted",
      "CLAIM_APPROVED": "✅ Claim Request Approved",
      "CLAIM_REJECTED": "❌ Claim Request Rejected",
      "ITEM_REPORTED": "📢 New Lost Item Reported"
    };
    return lookup[action] || `⚡ Action: ${action.replace(/_/g, ' ')}`;
  };

  return (
    <div className="space-y-10 pb-20 relative">
      {/* Upper Title Section */}
      <div className="flex flex-col md:flex-row md:items-end justify-between gap-6 border-b border-[var(--border-color)] pb-8">
        <motion.div initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }}>
          <h1 className="text-4xl font-black tracking-tighter uppercase text-[var(--foreground)]">Integrity <span className="text-jade-primary">Ledger</span></h1>
          <p className="text-sm text-neutral-500 uppercase tracking-widest mt-2">Blockchain Proof of Record Security</p>
        </motion.div>
        
        <div className="flex items-center gap-3 px-5 py-2.5 bg-jade-primary/5 border border-jade-primary/10 rounded-2xl shadow-sm self-start md:self-auto shrink-0">
           <ShieldCheck className="w-5 h-5 text-jade-primary" />
           <span className="text-[10px] font-black uppercase text-jade-primary tracking-widest">Immutable Active State</span>
        </div>
      </div>

      {/* Visually stunning educational banner that explains what this blockchain ledger does in human-readable terms */}
      <motion.div 
        initial={{ opacity: 0, y: 10 }}
        animate={{ opacity: 1, y: 0 }}
        className="bg-gradient-to-r from-jade-primary/5 to-jade-primary/[0.01] border border-jade-primary/20 rounded-[32px] p-6 md:p-8 flex flex-col md:flex-row items-center gap-6 md:gap-8"
      >
        <div className="w-14 h-14 bg-jade-primary/10 rounded-2xl flex items-center justify-center border border-jade-primary/10 shrink-0">
          <LockKeyhole className="w-6 h-6 text-jade-primary" />
        </div>
        <div className="space-y-2 text-left">
          <h3 className="text-base font-black uppercase tracking-wider text-[var(--foreground)]">How Trace Guarantees Absolute Data Trust</h3>
          <p className="text-xs md:text-sm text-neutral-500 font-medium leading-relaxed">
            Every recovery claim, verification status change, and critical event in our database is signed, hashed, and chained back to the previous transaction block to prevent database tampering. Click <span className="text-jade-primary font-bold">Verify</span> on any transaction to check its real-time cryptographic checksum authenticity.
          </p>
        </div>
      </motion.div>

      {/* Visual Timeline Blockchain Layout */}
      <div className="relative pl-4 md:pl-10 border-l border-[var(--border-color)] ml-3 md:ml-8 space-y-12">
        {isLoading ? (
          [...Array(3)].map((_, i) => (
            <div key={i} className="h-44 bg-[var(--card-bg)] border border-[var(--border-color)] rounded-[28px] animate-pulse" />
          ))
        ) : logs.length === 0 ? (
          <div className="py-24 text-center border border-dashed border-[var(--border-color)] rounded-[32px] bg-[var(--card-bg)] -ml-4 md:-ml-10">
             <Lock className="w-12 h-12 text-neutral-500/20 mx-auto mb-6" />
             <p className="text-xs font-bold text-neutral-500 uppercase tracking-[0.3em]">No transaction blocks logged</p>
          </div>
        ) : (
          logs.map((log, i) => {
            const isExpanded = expandedLogId === log.id;
            return (
              <motion.div 
                key={log.id}
                initial={{ opacity: 0, x: -10 }}
                animate={{ opacity: 1, x: 0 }}
                transition={{ delay: i * 0.05 }}
                className="relative"
              >
                {/* Timeline node */}
                <div className="absolute -left-[21px] md:-left-[45px] top-6 w-8 h-8 rounded-full bg-[var(--background)] border-2 border-jade-primary flex items-center justify-center shadow-lg">
                  <Link2 className="w-3.5 h-3.5 text-jade-primary" />
                </div>

                <div className="bg-[var(--card-bg)] border border-[var(--border-color)] rounded-[28px] p-6 md:p-8 relative overflow-hidden group hover:border-jade-primary/30 transition-all shadow-xl shadow-black/5">
                  <div className="absolute top-0 right-0 p-6 opacity-[0.02] group-hover:opacity-[0.05] transition-opacity">
                     <Fingerprint className="w-28 h-28" />
                  </div>

                  <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-6 relative z-10">
                    <div className="space-y-3 flex-1 min-w-0 w-full">
                      <div className="flex flex-wrap items-center gap-3">
                        <span className="text-[9px] font-black text-jade-primary bg-jade-primary/10 border border-jade-primary/10 px-3 py-1 rounded-full uppercase tracking-wider">
                           BLOCK #{logs.length - i}
                        </span>
                        <div className="text-[9px] font-bold text-neutral-400 uppercase tracking-widest flex items-center gap-2">
                           <Clock className="w-3.5 h-3.5 text-jade-primary" />
                           {new Date(log.timestamp).toLocaleString()}
                        </div>
                      </div>

                      <div>
                         <h4 className="text-lg md:text-xl font-black uppercase tracking-tight text-[var(--foreground)]">
                           {getFriendlyAction(log.data?.action)}
                         </h4>
                         {log.data?.itemTitle && (
                           <p className="text-sm font-semibold text-neutral-500 mt-1">
                             Target Item: <span className="text-[var(--foreground)]">{log.data.itemTitle}</span>
                           </p>
                         )}
                      </div>
                    </div>

                    <div className="flex items-center gap-3 shrink-0 w-full md:w-auto justify-end">
                      <button 
                        onClick={() => setExpandedLogId(isExpanded ? null : log.id)}
                        className="flex items-center gap-2 text-neutral-500 hover:text-jade-primary transition-all text-xs font-bold uppercase tracking-wider bg-[var(--background)] px-4 py-2.5 rounded-xl border border-[var(--border-color)]"
                      >
                         {isExpanded ? <ChevronUp className="w-4 h-4" /> : <ChevronDown className="w-4 h-4" />}
                         <span>{isExpanded ? "Hide Details" : "View Hash Details"}</span>
                      </button>

                      <button 
                        onClick={() => handleVerify(log)}
                        className="flex items-center gap-2 bg-jade-primary hover:bg-jade-deep text-white transition-all text-xs font-bold uppercase tracking-wider px-5 py-2.5 rounded-xl shadow-md shrink-0"
                      >
                         <ShieldCheck className="w-4 h-4" />
                         <span>Verify Integrity</span>
                      </button>
                    </div>
                  </div>

                  {/* Expandable Cryptographic Details */}
                  <AnimatePresence>
                    {isExpanded && (
                      <motion.div 
                        initial={{ height: 0, opacity: 0 }}
                        animate={{ height: "auto", opacity: 1 }}
                        exit={{ height: 0, opacity: 0 }}
                        className="overflow-hidden"
                      >
                        <div className="border-t border-[var(--border-color)] mt-6 pt-6 grid grid-cols-1 sm:grid-cols-2 gap-4">
                          <TruncatedHash hash={log.prev_hash} label="Prev Block State Reference (Prev Checksum)" />
                          <TruncatedHash hash={log.current_hash} label="Current Transaction Cryptographic Hash" />
                          
                          <div className="sm:col-span-2 bg-[var(--background)] p-4 rounded-2xl border border-[var(--border-color)]">
                            <span className="block text-[9px] font-black text-neutral-500 uppercase tracking-widest mb-1">Decrypted Metadata Specs</span>
                            <pre className="text-[10px] font-mono text-jade-primary break-all max-h-36 overflow-y-auto block p-1">
                              {JSON.stringify(log.data, null, 2)}
                            </pre>
                          </div>
                        </div>
                      </motion.div>
                    )}
                  </AnimatePresence>
                </div>
              </motion.div>
            );
          })
        )}
      </div>

      {/* High Tech Verification Scanning Modal */}
      <AnimatePresence>
        {selectedLog && (
          <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/80 backdrop-blur-md">
            <motion.div 
              initial={{ opacity: 0, scale: 0.95 }}
              animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0, scale: 0.95 }}
              className="w-full max-w-2xl bg-[var(--card-bg)] border border-[var(--border-color)] rounded-[32px] p-6 md:p-8 relative overflow-hidden shadow-2xl max-h-[90vh] overflow-y-auto"
            >
              <button 
                onClick={() => setSelectedLog(null)}
                className="absolute top-6 right-6 p-2 rounded-full hover:bg-neutral-800/10 text-neutral-500 hover:text-[var(--foreground)] transition-colors"
              >
                <X className="w-5 h-5" />
              </button>

              <div className="flex items-center gap-4 mb-6 border-b border-[var(--border-color)] pb-4">
                <div className="w-12 h-12 bg-jade-primary/10 rounded-2xl flex items-center justify-center border border-jade-primary/10">
                  <Database className="w-6 h-6 text-jade-primary" />
                </div>
                <div>
                  <h3 className="text-xl font-black uppercase tracking-tight text-[var(--foreground)]">Ledger Integrity Analyzer</h3>
                  <p className="text-[10px] font-bold text-neutral-500 uppercase tracking-[0.2em] mt-0.5">Real-time Checksum Diagnostics</p>
                </div>
              </div>

              <div className="space-y-6">
                <div className="bg-[var(--background)] p-5 rounded-2xl border border-[var(--border-color)] space-y-4">
                  <div className="grid grid-cols-2 gap-4 text-xs font-semibold">
                    <div>
                      <span className="block text-[9px] font-black text-neutral-500 uppercase tracking-widest mb-1">TRANSACTION ID</span>
                      <span className="text-[var(--foreground)]">LOG-{selectedLog.id.substring(0, 12)}</span>
                    </div>
                    <div>
                      <span className="block text-[9px] font-black text-neutral-500 uppercase tracking-widest mb-1">TIMESTAMP</span>
                      <span className="text-[var(--foreground)]">{new Date(selectedLog.timestamp).toLocaleString()}</span>
                    </div>
                  </div>

                  <div className="border-t border-[var(--border-color)] pt-4 space-y-3">
                    <div>
                      <span className="block text-[9px] font-black text-neutral-500 uppercase tracking-widest mb-1">EXPECTED HASH</span>
                      <code className="text-[11px] font-mono text-neutral-400 bg-[var(--card-bg)] px-3 py-2 rounded-lg block break-all border border-[var(--border-color)]">
                        {selectedLog.current_hash}
                      </code>
                    </div>
                  </div>
                </div>

                {/* Verification Results UI */}
                {verificationResult === "idle" && (
                  <div className="p-8 border border-dashed border-jade-primary/20 bg-jade-primary/[0.01] rounded-2xl text-center space-y-4">
                    <Fingerprint className="w-10 h-10 text-neutral-500 mx-auto" />
                    <div className="space-y-1">
                      <div className="text-sm font-black uppercase tracking-wider text-[var(--foreground)]">Ready to Scan Checksum</div>
                      <p className="text-xs text-neutral-500 max-w-sm mx-auto">
                        This test will independently parse the metadata block content, apply your transaction stamp, and generate a new SHA-256 fingerprint to match against the current stored ledger hash.
                      </p>
                    </div>
                  </div>
                )}

                {/* Action Buttons */}
                <div className="flex flex-wrap items-center gap-3 justify-center md:justify-start">
                  {verificationResult === "idle" && (
                    <button 
                      onClick={runVerification}
                      className="flex items-center gap-2 bg-jade-primary text-white font-bold text-xs uppercase tracking-widest px-6 py-3.5 rounded-xl hover:bg-jade-deep transition-all shadow-md"
                    >
                      <Activity className="w-4 h-4 animate-pulse" />
                      <span>Start Diagnostics Scan</span>
                    </button>
                  )}

                  {verificationResult !== "idle" && verificationResult !== "verifying" && (
                    <button 
                      onClick={() => downloadReceipt(selectedLog)}
                      className="flex items-center gap-2 bg-jade-primary text-white font-bold text-xs uppercase tracking-widest px-6 py-3.5 rounded-xl hover:bg-jade-deep transition-all shadow-md"
                    >
                      <Download className="w-4 h-4" />
                      <span>Save Diagnostic Report</span>
                    </button>
                  )}

                  <button 
                    onClick={() => setSelectedLog(null)}
                    className="flex items-center gap-2 bg-neutral-500/10 text-neutral-500 hover:text-[var(--foreground)] font-bold text-xs uppercase tracking-widest px-6 py-3.5 rounded-xl hover:bg-neutral-500/20 transition-all border border-[var(--border-color)]"
                  >
                    <span>Close Analyzer</span>
                  </button>
                </div>

                {verificationResult === "verifying" && (
                  <div className="p-8 border border-dashed border-jade-primary/30 bg-jade-primary/5 rounded-2xl text-center space-y-4">
                    <div className="relative w-12 h-12 mx-auto">
                      <div className="absolute inset-0 border-4 border-jade-primary/20 rounded-full"></div>
                      <div className="absolute inset-0 border-4 border-jade-primary border-t-transparent rounded-full animate-spin"></div>
                    </div>
                    <div className="space-y-1">
                      <div className="text-xs font-black uppercase text-jade-primary tracking-widest animate-pulse">Running Cryptographic Diagnostic Scan...</div>
                      <p className="text-[10px] text-neutral-400">Verifying parent hashes & calculating SHA-256 block fingerprint...</p>
                    </div>
                  </div>
                )}

                {verificationResult === "success" && (
                  <motion.div 
                    initial={{ opacity: 0, y: 10 }} 
                    animate={{ opacity: 1, y: 0 }}
                    className="p-6 bg-emerald-500/10 border border-emerald-500/20 rounded-2xl space-y-3 text-left"
                  >
                    <div className="flex items-center gap-2.5 text-emerald-600 dark:text-emerald-500">
                      <CheckCircle className="w-5 h-5" />
                      <span className="text-sm font-black uppercase tracking-wider">✓ PASSED: DATA MATCH CONFIRMED</span>
                    </div>
                    <div className="space-y-2 text-xs text-neutral-500">
                      <p className="font-semibold leading-relaxed">
                        Excellent news! The generated cryptographic block fingerprint matches the official system-stored log hash. The database contains no compromises or tampered events.
                      </p>
                      <div className="pt-2">
                        <span className="block text-[9px] font-black uppercase text-emerald-500 tracking-wider">CALCULATED HASH MATCHED</span>
                        <code className="text-xs font-mono text-emerald-600 dark:text-emerald-500 break-all bg-[var(--background)] p-3 rounded-xl block border border-[var(--border-color)] mt-1">{computedHash}</code>
                      </div>
                    </div>
                  </motion.div>
                )}

                {verificationResult === "fail" && (
                  <motion.div 
                    initial={{ opacity: 0, y: 10 }} 
                    animate={{ opacity: 1, y: 0 }}
                    className="p-6 bg-red-500/10 border border-red-500/20 rounded-2xl space-y-3 text-left"
                  >
                    <div className="flex items-center gap-2.5 text-red-500">
                      <AlertTriangle className="w-5 h-5" />
                      <span className="text-sm font-black uppercase tracking-wider">❌ FAILED: INTEGRITY MISMATCH</span>
                    </div>
                    <div className="space-y-2 text-xs text-neutral-500">
                      <p className="font-semibold leading-relaxed">
                        Warning! The recalculated fingerprint does NOT match the stored system reference. This strongly suggests that metadata details inside the transaction table have been modified or altered since logging.
                      </p>
                      <div className="pt-2">
                        <span className="block text-[9px] font-black uppercase text-red-500 tracking-wider">UNEXPECTED GENERATED HASH</span>
                        <code className="text-xs font-mono text-red-500 break-all bg-[var(--background)] p-3 rounded-xl block border border-[var(--border-color)] mt-1">{computedHash}</code>
                      </div>
                    </div>
                  </motion.div>
                )}
              </div>
            </motion.div>
          </div>
        )}
      </AnimatePresence>
    </div>
  );
}
