"use client";

import { useState, useEffect } from "react";
import { auth } from "@/lib/firebase";
import { 
  signInWithEmailAndPassword, 
  GoogleAuthProvider, 
  signInWithPopup,
  onAuthStateChanged
} from "firebase/auth";
import { useRouter } from "next/navigation";
import { Terminal, Shield, LogIn, Loader2 } from "lucide-react";
import { motion } from "framer-motion";

export default function LoginPage() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [isLoading, setIsLoading] = useState(true);
  const router = useRouter();

  useEffect(() => {
    // If already logged in, go to admin
    const unsubscribe = onAuthStateChanged(auth, (user) => {
      if (user) {
        router.push("/admin");
      } else {
        setIsLoading(false);
      }
    });

    return () => unsubscribe();
  }, [router]);

  const handleEmailLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);
    setError("");
    try {
      await signInWithEmailAndPassword(auth, email, password);
      router.push("/admin");
    } catch (err: any) {
      setError(err.message || "Authentication failed");
      setIsLoading(false);
    }
  };

  const handleGoogleLogin = async () => {
    setIsLoading(true);
    setError("");
    try {
      const provider = new GoogleAuthProvider();
      // Switched back to signInWithPopup as requested
      await signInWithPopup(auth, provider);
      router.push("/admin");
    } catch (err: any) {
      console.error("Login Error:", err);
      if (err.code === "auth/popup-closed-by-user") {
        setError("Login cancelled: Popup was closed.");
      } else if (err.code === "auth/popup-blocked") {
        setError("Login blocked: Please allow popups for this site.");
      } else {
        setError(err.message || "Google Authentication failed");
      }
      setIsLoading(false);
    }
  };

  if (isLoading) {
    return (
      <div className="min-h-screen bg-[#0A0A14] flex items-center justify-center">
        <div className="flex flex-col items-center gap-4">
          <Loader2 className="w-8 h-8 text-cyan-500 animate-spin" />
          <span className="text-[10px] font-mono uppercase tracking-widest text-neutral-600">Checking Uplink...</span>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-[#0A0A14] flex items-center justify-center p-6 relative overflow-hidden">
      {/* Visual background grid */}
      <div className="absolute inset-0 bg-[linear-gradient(to_right,#ffffff03_1px,transparent_1px),linear-gradient(to_bottom,#ffffff03_1px,transparent_1px)] bg-[size:40px_40px] pointer-events-none"></div>
      <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[500px] h-[500px] bg-cyan-500/10 blur-[120px] rounded-full pointer-events-none"></div>

      <motion.div 
        initial={{ opacity: 0, scale: 0.95 }}
        animate={{ opacity: 1, scale: 1 }}
        className="w-full max-w-[420px] relative z-10"
      >
        <div className="bg-[#12121F]/80 backdrop-blur-xl border border-white/5 rounded-[40px] p-10 md:p-12 shadow-2xl">
          <div className="flex flex-col items-center mb-12">
            <div className="w-20 h-20 bg-cyan-500/10 border border-cyan-500/20 rounded-3xl flex items-center justify-center mb-6 relative group">
              <div className="absolute inset-0 bg-cyan-500/20 blur-2xl opacity-0 group-hover:opacity-100 transition-opacity"></div>
              <Terminal className="w-10 h-10 text-cyan-500 relative z-10" />
            </div>
            <h1 className="text-3xl font-black tracking-tighter uppercase font-mono italic text-white">Trace Login</h1>
            <p className="text-[10px] font-mono text-neutral-500 uppercase tracking-[0.4em] mt-3 text-center">Protocol Verification Required</p>
          </div>

          <form onSubmit={handleEmailLogin} className="space-y-5">
            <div className="space-y-2">
              <label className="text-[10px] font-mono text-neutral-600 uppercase tracking-widest ml-1">Terminal_ID</label>
              <input 
                type="email" 
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="operator@campus.edu" 
                className="w-full bg-black/40 border border-white/5 rounded-2xl px-5 py-4 text-sm outline-none focus:border-cyan-500/30 transition-all placeholder:text-neutral-800"
                required
              />
            </div>
            <div className="space-y-2">
              <label className="text-[10px] font-mono text-neutral-600 uppercase tracking-widest ml-1">Access_Code</label>
              <input 
                type="password" 
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="••••••••" 
                className="w-full bg-black/40 border border-white/5 rounded-2xl px-5 py-4 text-sm outline-none focus:border-cyan-500/30 transition-all placeholder:text-neutral-800"
                required
              />
            </div>

            {error && (
              <motion.div 
                initial={{ opacity: 0, x: -10 }}
                animate={{ opacity: 1, x: 0 }}
                className="bg-red-500/10 border border-red-500/20 rounded-2xl p-4 text-[10px] font-mono text-red-500 uppercase tracking-wider leading-relaxed"
              >
                Critical_Error: {error}
              </motion.div>
            )}

            <button 
              type="submit" 
              className="w-full bg-cyan-500 text-black font-black py-5 rounded-2xl hover:scale-[1.02] active:scale-[0.98] transition-all flex items-center justify-center gap-3 group shadow-[0_0_20px_rgba(6,182,212,0.3)]"
            >
              <LogIn className="w-5 h-5 group-hover:translate-x-1 transition-transform" />
              <span className="text-xs uppercase tracking-[0.2em]">Initiate Uplink</span>
            </button>
          </form>

          <div className="relative my-10">
            <div className="absolute inset-0 flex items-center">
              <div className="w-full border-t border-white/5"></div>
            </div>
            <div className="relative flex justify-center text-[8px] font-mono uppercase tracking-[0.4em] bg-[#12121F] px-4 text-neutral-700">
              External_Service_Gate
            </div>
          </div>

          <button 
            onClick={handleGoogleLogin}
            className="w-full bg-white/5 border border-white/10 text-white py-5 rounded-2xl hover:bg-white/10 transition-all flex items-center justify-center gap-3 group"
          >
            <Shield className="w-5 h-5 text-cyan-500 group-hover:rotate-12 transition-transform" />
            <span className="text-[10px] font-mono uppercase tracking-widest">Authorize via Google</span>
          </button>
        </div>
      </motion.div>
    </div>
  );
}
