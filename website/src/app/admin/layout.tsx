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
    } else {
      document.documentElement.setAttribute("data-theme", "dark");
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
      <div className="min-h-screen bg-[var(--background)] text-[var(--foreground)] flex items-center justify-center font-mono transition-colors duration-300">
        <div className="flex flex-col items-center gap-4">
          <Loader2 className="w-8 h-8 text-green-500 animate-spin" />
          <span className="text-[10px] font-bold uppercase tracking-[0.3em] text-neutral-500">Securing Session...</span>
        </div>
      </div>
    );
  }

  if (authorized === false) {
    return (
      <div className="min-h-screen bg-[var(--background)] text-[var(--foreground)] flex items-center justify-center p-6 text-center font-mono transition-colors duration-300">
        <div className="max-w-md bg-[var(--card-bg)] border border-red-500/20 p-10 rounded-lg shadow-2xl">
          <ShieldAlert className="w-16 h-16 text-red-500 mx-auto mb-6" />
          <h2 className="text-2xl font-black mb-2 uppercase tracking-tighter">Access Denied</h2>
          <p className="text-sm text-neutral-500 mb-8 font-bold uppercase tracking-widest">Unauthorized Personnel. Redirection in progress.</p>
        </div>
      </div>
    );
  }

  return (
    <div className="admin-theme min-h-screen bg-[var(--background)] text-[var(--foreground)] flex flex-col md:flex-row font-mono selection:bg-white/10 overflow-x-hidden transition-colors duration-300">
      {/* Mobile Header */}
      <MobileNav onOpenSidebar={() => setIsSidebarOpen(true)} />

      {/* Sidebar */}
      <Sidebar
        isOpen={isSidebarOpen}
        onClose={() => setIsSidebarOpen(false)}
        theme={theme}
        onToggleTheme={toggleTheme}
      />

      {/* Main Content Area */}
      <div className="flex-1 min-h-screen relative overflow-x-hidden">
        {/* Content Wrapper */}
        <div className="p-4 md:p-12 lg:p-16 max-w-7xl mx-auto relative z-10">
          {children}
        </div>
      </div>
    </div>
  );
}
