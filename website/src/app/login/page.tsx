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
import { LogIn, Loader2 } from "lucide-react";

export default function LoginPage() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [isLoading, setIsLoading] = useState(true);
  const router = useRouter();

  useEffect(() => {
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
      await signInWithPopup(auth, provider);
      router.push("/admin");
    } catch (err: any) {
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
      <div className="min-h-screen bg-black text-white flex items-center justify-center font-mono">
        <div className="flex flex-col items-center gap-4">
          <Loader2 className="w-8 h-8 text-green-500 animate-spin" />
          <span className="text-xs uppercase tracking-widest text-neutral-500">Securing Session...</span>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-black text-white flex items-center justify-center p-6 font-mono">
      <div className="w-full max-w-md bg-neutral-950 border border-neutral-800 rounded-lg p-8 shadow-2xl">
        <div className="flex flex-col items-center mb-8 text-center space-y-4">
          <div className="w-3 h-3 bg-green-500 rounded-full mx-auto animate-pulse"></div>
          <div>
            <h1 className="text-xl font-bold uppercase tracking-widest text-neutral-200">Trace API Core</h1>
            <p className="text-xs text-neutral-500 uppercase tracking-widest mt-1">Admin Access Required</p>
          </div>
        </div>

        <div className="flex flex-col items-center gap-4">
          {error && (
            <div className="bg-red-500/10 border border-red-500/20 rounded p-3 text-[10px] text-red-500 uppercase tracking-wider text-center w-full">
              {error}
            </div>
          )}

          <button 
            onClick={handleGoogleLogin}
            className="w-full bg-neutral-900 border border-neutral-800 text-neutral-200 font-bold py-4 rounded hover:bg-neutral-800 transition-all flex items-center justify-center gap-2"
          >
            <span className="text-[10px] uppercase tracking-widest">Sign in with Google</span>
          </button>
        </div>

        <div className="mt-6 pt-4 text-center">
           <a href="/setup" className="text-[10px] text-neutral-600 hover:text-neutral-400 transition-colors uppercase tracking-[0.2em]">
              &rarr; Initialize Admin Setup
           </a>
        </div>
      </div>
    </div>
  );
}
