"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { auth } from "@/lib/firebase";
import { onAuthStateChanged } from "firebase/auth";
import { supabase } from "@/lib/supabase";
import Sidebar from "@/components/admin/Sidebar";
import MobileNav from "@/components/admin/MobileNav";
import { Loader2, ShieldAlert } from "lucide-react";

export default function AdminLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const [authorized, setAuthorized] = useState<boolean | null>(null);
  const [isSidebarOpen, setIsSidebarOpen] = useState(false);
  const [theme, setTheme] = useState<"light" | "dark">("dark");
  const router = useRouter();

  useEffect(() => {
    // Initial theme setup
    const savedTheme = localStorage.getItem("trace-theme") as "light" | "dark";
    if (savedTheme) {
      setTheme(savedTheme);
      document.documentElement.setAttribute("data-theme", savedTheme);
    }
    
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

  const toggleTheme = () => {
    const newTheme = theme === "light" ? "dark" : "light";
    setTheme(newTheme);
    document.documentElement.setAttribute("data-theme", newTheme);
    localStorage.setItem("trace-theme", newTheme);
  };

  if (authorized === null) {
    return (
      <div className="min-h-screen bg-[var(--background)] flex items-center justify-center">
        <div className="flex flex-col items-center gap-4">
          <Loader2 className="w-8 h-8 text-jade-primary animate-spin" />
          <span className="text-[10px] font-bold uppercase tracking-[0.3em] text-jade-primary/50">Securing Session...</span>
        </div>
      </div>
    );
  }

  if (authorized === false) {
    return (
      <div className="min-h-screen bg-[var(--background)] flex items-center justify-center p-6 text-center">
        <div className="max-w-md bg-red-500/5 border border-red-500/10 p-10 rounded-[32px]">
          <ShieldAlert className="w-16 h-16 text-red-500 mx-auto mb-6" />
          <h2 className="text-2xl font-black text-[var(--foreground)] mb-2 uppercase tracking-tighter">Access Denied</h2>
          <p className="text-sm text-jade-primary/60 mb-8 font-bold uppercase tracking-widest">Unauthorized Personnel. Redirection in progress.</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-[var(--background)] text-[var(--foreground)] flex flex-col md:flex-row font-sans selection:bg-jade-primary/30 overflow-x-hidden transition-colors duration-500">
      {/* Mobile Header */}
      <MobileNav onOpenSidebar={() => setIsSidebarOpen(true)} />

      {/* Sidebar - Fixed on mobile (slide-over), static on desktop */}
      <Sidebar 
        isOpen={isSidebarOpen} 
        onClose={() => setIsSidebarOpen(false)} 
        theme={theme}
        onToggleTheme={toggleTheme}
      />
      
      {/* Main Content Area - Scrollable */}
      <div className="flex-1 min-h-screen relative overflow-x-hidden">
        {/* Animated Background Gradients */}
        <div className="absolute inset-0 overflow-hidden pointer-events-none opacity-50">
           <div className="absolute -top-[10%] -right-[5%] w-[40vw] h-[40vw] bg-jade-primary/10 blur-[100px] rounded-full"></div>
           <div className="absolute -bottom-[10%] -left-[5%] w-[30vw] h-[30vw] bg-sage-secondary/10 blur-[100px] rounded-full"></div>
        </div>
        
        {/* Content Wrapper */}
        <div className="p-4 md:p-12 lg:p-16 max-w-7xl mx-auto relative z-10">
          {children}
        </div>
      </div>
    </div>
  );
}
