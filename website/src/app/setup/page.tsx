"use client";

import { useState } from "react";
import { supabase } from "@/lib/supabase";
import { Shield, Loader2 } from "lucide-react";

export default function SetupAdminPage() {
  const [email, setEmail] = useState("");
  const [passcode, setPasscode] = useState("");
  const [status, setStatus] = useState<{ type: 'error' | 'success' | null, msg: string }>({ type: null, msg: "" });
  const [isLoading, setIsLoading] = useState(false);

  const handlePromote = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);
    setStatus({ type: null, msg: "" });

    // Simple master passcode for initial setup
    if (passcode !== "trace2026") {
      setStatus({ type: 'error', msg: "Invalid Setup Passcode" });
      setIsLoading(false);
      return;
    }

    try {
      const { data: user, error: fetchError } = await supabase
        .from('users')
        .select('*')
        .eq('email', email)
        .single();

      if (fetchError || !user) {
        setStatus({ type: 'error', msg: "User not found. They must log in to the mobile app or web app at least once first." });
        setIsLoading(false);
        return;
      }

      const { error: updateError } = await supabase
        .from('users')
        .update({ role: 'admin' })
        .eq('email', email);

      if (updateError) throw updateError;

      setStatus({ type: 'success', msg: `Success! ${email} is now an Admin.` });
    } catch (err: any) {
      setStatus({ type: 'error', msg: err.message || "Failed to update role" });
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-black text-white flex items-center justify-center p-6 font-mono">
      <div className="w-full max-w-md bg-neutral-950 border border-neutral-800 rounded-lg p-8 shadow-2xl">
        <div className="flex flex-col items-center mb-8 text-center space-y-4">
          <Shield className="w-10 h-10 text-green-500" />
          <div>
            <h1 className="text-xl font-bold uppercase tracking-widest text-neutral-200">Admin Setup</h1>
            <p className="text-[10px] text-neutral-500 uppercase tracking-widest mt-1">First-time Role Assignment</p>
          </div>
        </div>

        <form onSubmit={handlePromote} className="space-y-4">
          <div className="space-y-2">
            <label className="text-[10px] text-neutral-500 uppercase tracking-widest">User Email</label>
            <input 
              type="email" 
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="user@trace.app" 
              className="w-full bg-black border border-neutral-800 rounded px-4 py-3 text-sm outline-none focus:border-green-500/50 transition-all text-neutral-200"
              required
            />
          </div>
          <div className="space-y-2">
            <label className="text-[10px] text-neutral-500 uppercase tracking-widest">Setup Passcode</label>
            <input 
              type="password" 
              value={passcode}
              onChange={(e) => setPasscode(e.target.value)}
              placeholder="Master Setup Passcode" 
              className="w-full bg-black border border-neutral-800 rounded px-4 py-3 text-sm outline-none focus:border-green-500/50 transition-all text-neutral-200"
              required
            />
          </div>

          {status.type === 'error' && (
            <div className="bg-red-500/10 border border-red-500/20 rounded p-3 text-[10px] text-red-500 uppercase tracking-wider text-center">
              {status.msg}
            </div>
          )}
          {status.type === 'success' && (
            <div className="bg-green-500/10 border border-green-500/20 rounded p-3 text-[10px] text-green-500 uppercase tracking-wider text-center">
              {status.msg}
            </div>
          )}

          <button 
            type="submit" 
            disabled={isLoading}
            className="w-full bg-neutral-800 text-neutral-200 font-bold py-3 rounded hover:bg-neutral-700 transition-all flex items-center justify-center gap-2 text-xs uppercase tracking-[0.2em] disabled:opacity-50"
          >
            {isLoading ? <Loader2 className="w-4 h-4 animate-spin" /> : "Make Admin"}
          </button>
        </form>

        <div className="mt-6 pt-6 border-t border-neutral-800/50 text-center">
           <a href="/login" className="text-[10px] text-neutral-500 uppercase tracking-widest hover:text-white transition-colors">
              &rarr; Back to Login
           </a>
        </div>
      </div>
    </div>
  );
}
