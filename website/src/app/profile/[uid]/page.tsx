"use client";

import { useEffect, useState } from "react";
import { useParams } from "next/navigation";
import { motion } from "framer-motion";
import { createClient } from "@supabase/supabase-js";
import { User, Shield, MapPin, GraduationCap, Calendar, Mail, Phone, ChevronLeft, Moon, Sun } from "lucide-react";
import Link from "next/link";

// Initialize Supabase
const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!;
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!;
const supabase = createClient(supabaseUrl, supabaseAnonKey);

export default function ProfilePage() {
  const { uid } = useParams();
  const [user, setUser] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [theme, setTheme] = useState<"light" | "dark">("dark");

  useEffect(() => {
    // Initial theme setup from system or localStorage
    const savedTheme = localStorage.getItem("trace-theme") as "light" | "dark";
    const systemTheme = window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light";
    const initialTheme = savedTheme || systemTheme;
    setTheme(initialTheme);
    document.documentElement.setAttribute("data-theme", initialTheme);

    async function fetchUser() {
      if (!uid) return;
      
      const { data, error } = await supabase
        .from("users")
        .select("*")
        .eq("uid", uid)
        .single();

      if (data) {
        setUser(data);
      }
      setLoading(false);
    }

    fetchUser();
  }, [uid]);

  const toggleTheme = () => {
    const newTheme = theme === "light" ? "dark" : "light";
    setTheme(newTheme);
    document.documentElement.setAttribute("data-theme", newTheme);
    localStorage.setItem("trace-theme", newTheme);
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-[var(--background)] flex items-center justify-center">
        <div className="w-12 h-12 border-4 border-foreground/20 border-t-foreground rounded-full animate-spin"></div>
      </div>
    );
  }

  if (!user) {
    return (
      <div className="min-h-screen bg-[var(--background)] flex flex-col items-center justify-center p-6 text-center">
        <div className="w-20 h-20 bg-red-500/10 rounded-full flex items-center justify-center mb-6">
          <User className="w-10 h-10 text-red-500" />
        </div>
        <h1 className="text-2xl font-black mb-2 uppercase tracking-tighter text-[var(--foreground)]">Profile Not Found</h1>
        <p className="text-foreground/40 mb-8 max-w-xs font-bold uppercase tracking-widest text-xs">Verification failed. ID record missing.</p>
        <Link href="/" className="px-8 py-4 bg-foreground text-background rounded-2xl hover:opacity-90 transition-opacity font-bold text-xs uppercase tracking-widest">
          Return to Portal
        </Link>
      </div>
    );
  }

  // Parse privacy settings (assume they exist in user object)
  const privacy = user.privacy_settings || {
    showFatherName: true,
    showContactNumber: true,
    showAddress: true,
    showRegistrationNo: true,
    showDepartment: true
  };

  return (
    <div className="min-h-screen bg-[var(--background)] text-[var(--foreground)] selection:bg-foreground/10 transition-colors duration-500">
      {/* Background Accents */}
      <div className="fixed inset-0 overflow-hidden pointer-events-none opacity-50">
        <div className="absolute -top-[20%] -right-[10%] w-[70vw] h-[70vw] bg-foreground/5 blur-[120px] rounded-full"></div>
        <div className="absolute -bottom-[20%] -left-[10%] w-[60vw] h-[60vw] bg-foreground/5 blur-[120px] rounded-full"></div>
      </div>

      <main className="relative z-10 max-w-2xl mx-auto px-6 pt-24 pb-20">
        {/* Header Navigation */}
        <div className="flex items-center justify-between mb-8">
          <Link href="/" className="inline-flex items-center gap-2 text-foreground/40 hover:text-foreground transition-colors group">
            <ChevronLeft className="w-4 h-4 group-hover:-translate-x-1 transition-transform" />
            <span className="text-xs font-bold uppercase tracking-widest">Back</span>
          </Link>
          <button 
            onClick={toggleTheme}
            className="p-3 bg-foreground/5 rounded-2xl text-foreground hover:bg-foreground/10 transition-all"
          >
            {theme === "light" ? <Moon className="w-5 h-5" /> : <Sun className="w-5 h-5" />}
          </button>
        </div>

        {/* Profile Card */}
        <motion.div 
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="bg-[var(--card-bg)] backdrop-blur-2xl border border-[var(--border-color)] rounded-[40px] p-8 md:p-12 relative overflow-hidden shadow-2xl shadow-black/5"
        >
          {/* Verified Badge */}
          <div className="absolute top-8 right-8 px-5 py-2 bg-foreground text-background rounded-full text-[10px] font-black uppercase tracking-wider flex items-center gap-2 shadow-xl shadow-black/10">
            <Shield className="w-3.5 h-3.5 fill-current" />
            Verified
          </div>

          {/* Profile Header */}
          <div className="flex flex-col items-center text-center mb-10">
            <div className="relative mb-8">
              <img 
                src={user.photoURL || `https://ui-avatars.com/api/?name=${encodeURIComponent(user.name)}&background=000&color=fff`} 
                alt={user.name}
                className="w-36 h-36 rounded-[48px] object-cover border-4 border-foreground/5 shadow-2xl"
              />
              <div className="absolute -bottom-2 -right-2 w-10 h-10 bg-foreground border-4 border-[var(--card-bg)] rounded-2xl flex items-center justify-center shadow-lg">
                <Shield className="w-5 h-5 text-background" />
              </div>
            </div>
            
            <h1 className="text-4xl font-black tracking-tighter mb-2 text-[var(--foreground)] uppercase">
              {user.name}
            </h1>
            <p className="text-foreground/60 font-bold tracking-[0.2em] uppercase text-xs">
              {(privacy.showRegistrationNo ? (user.cmsStudentId || user.registrationNo) : null) || "Student Identity"}
            </p>
          </div>

          <div className="h-px bg-foreground/5 w-full mb-10"></div>

          {/* Info Sections */}
          <div className="grid gap-10">
            <InfoSection label="Campus Identity">
              {privacy.showFatherName && <InfoItem icon={User} label="Father Name" value={user.fatherName || "—"} />}
              {privacy.showDepartment && <InfoItem icon={GraduationCap} label="Department" value={user.department || "Computing"} />}
              <InfoItem icon={Calendar} label="Intake Semester" value={user.intakeSemester || "Fall 2022"} />
            </InfoSection>

            <InfoSection label="Secure Contact">
              <InfoItem icon={Mail} label="University Email" value={user.email} />
              {privacy.showContactNumber && <InfoItem icon={Phone} label="Mobile Number" value={user.contactNumber || "—"} />}
              {privacy.showAddress && <InfoItem icon={MapPin} label="Current Address" value={user.currentAddress || "Islamabad, Pakistan"} />}
            </InfoSection>
          </div>

          {/* Action Button */}
          <motion.button
            whileHover={{ scale: 1.02 }}
            whileTap={{ scale: 0.98 }}
            className="w-full mt-12 py-5 bg-foreground hover:opacity-90 text-background font-black rounded-[24px] transition-all shadow-2xl shadow-black/10 uppercase tracking-widest text-xs"
          >
            Contact via Trace App
          </motion.button>
        </motion.div>

        {/* Footer */}
        <div className="mt-12 text-center">
            <div className="text-2xl font-black tracking-tighter text-[var(--foreground)] uppercase">TRACE<span className="text-foreground/20">.</span></div>
            <p className="text-[9px] font-bold text-foreground/20 uppercase tracking-[0.4em] mt-3">Official Digital Identity Portal</p>
        </div>
      </main>
    </div>
  );
}

function InfoSection({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <div className="space-y-6">
      <h3 className="text-[10px] font-black uppercase tracking-[0.3em] text-foreground/20 px-1">
        {label}
      </h3>
      <div className="grid gap-6">
        {children}
      </div>
    </div>
  );
}

function InfoItem({ icon: Icon, label, value }: { icon: any; label: string; value: string }) {
  return (
    <div className="flex items-start gap-5 group">
      <div className="w-12 h-12 rounded-2xl bg-foreground/5 border border-foreground/10 flex items-center justify-center shrink-0 group-hover:bg-foreground group-hover:text-background transition-all duration-300">
        <Icon className="w-6 h-6 text-foreground group-hover:text-background transition-colors" />
      </div>
      <div className="flex flex-col gap-1">
        <span className="text-[10px] text-foreground/30 font-bold uppercase tracking-wider">{label}</span>
        <span className="text-base font-black text-[var(--foreground)] tracking-tight">{value}</span>
      </div>
    </div>
  );
}
