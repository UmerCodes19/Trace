"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { auth } from "@/lib/firebase";
import { onAuthStateChanged } from "firebase/auth";
import { supabase } from "@/lib/supabase";
import Sidebar from "@/components/admin/Sidebar";
import { Loader2, ShieldAlert } from "lucide-react";

export default function AdminLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const [authorized, setAuthorized] = useState<boolean | null>(null);
  const router = useRouter();

  useEffect(() => {
    // Satisfy Next.js smooth scroll warning
    document.documentElement.setAttribute("data-scroll-behavior", "smooth");

    const unsubscribe = onAuthStateChanged(auth, async (user) => {
      if (!user) {
        setAuthorized(false);
        router.push("/login");
        return;
      }

      try {
        const { data: profile, error } = await supabase
          .from("users")
          .select("role")
          .eq("uid", user.uid)
          .single();

        if (error || !profile || (profile.role !== "admin" && profile.role !== "staff")) {
          setAuthorized(false);
          setTimeout(() => router.push("/"), 3000);
          return;
        }

        setAuthorized(true);
      } catch (err) {
        setAuthorized(false);
      }
    });

    return () => unsubscribe();
  }, [router]);

  if (authorized === null) {
    return (
      <div className="min-h-screen bg-[#0A0A14] flex items-center justify-center">
        <div className="flex flex-col items-center gap-4">
          <Loader2 className="w-8 h-8 text-cyan-500 animate-spin" />
          <span className="text-[10px] font-mono uppercase tracking-[0.3em] text-neutral-500">Decrypting...</span>
        </div>
      </div>
    );
  }

  if (authorized === false) {
    return (
      <div className="min-h-screen bg-[#0A0A14] flex items-center justify-center p-6 text-center">
        <div className="max-w-md bg-red-500/5 border border-red-500/20 p-10 rounded-3xl">
          <ShieldAlert className="w-16 h-16 text-red-500 mx-auto mb-6" />
          <h2 className="text-2xl font-bold text-white mb-2 uppercase font-mono tracking-tighter">Access Denied</h2>
          <p className="text-sm text-neutral-400 mb-8 font-mono uppercase tracking-widest">Unauthorized Personnel. Protocol initiated.</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-[#0A0A14] text-white flex flex-col md:flex-row font-sans selection:bg-cyan-500/30">
      {/* Sidebar - Stays fixed on large screens */}
      <Sidebar />
      
      {/* Main Content Area - Scrollable */}
      <div className="flex-1 min-h-screen relative overflow-x-hidden">
        {/* Animated Grid Background */}
        <div className="absolute inset-0 bg-[linear-gradient(to_right,#ffffff05_1px,transparent_1px),linear-gradient(to_bottom,#ffffff05_1px,transparent_1px)] bg-[size:40px_40px] [mask-image:radial-gradient(ellipse_60%_50%_at_50%_0%,#000_70%,transparent_100%)] pointer-events-none"></div>
        
        {/* Content Wrapper */}
        <div className="p-6 md:p-12 lg:p-16 max-w-7xl mx-auto relative z-10">
          {children}
        </div>
      </div>
    </div>
  );
}
