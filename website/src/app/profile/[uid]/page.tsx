"use client";

import { useEffect, useState } from "react";
import { useParams } from "next/navigation";
import { motion } from "framer-motion";
import { createClient } from "@supabase/supabase-js";
import { User, Shield, MapPin, GraduationCap, Calendar, Mail, Phone, ChevronLeft } from "lucide-react";
import Link from "next/link";

// Initialize Supabase
const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!;
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!;
const supabase = createClient(supabaseUrl, supabaseAnonKey);

export default function ProfilePage() {
  const { uid } = useParams();
  const [user, setUser] = useState<any>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
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

  if (loading) {
    return (
      <div className="min-h-screen bg-[#0A0F12] flex items-center justify-center">
        <div className="w-12 h-12 border-4 border-emerald-500/20 border-t-emerald-500 rounded-full animate-spin"></div>
      </div>
    );
  }

  if (!user) {
    return (
      <div className="min-h-screen bg-[#0A0F12] flex flex-col items-center justify-center p-6 text-center">
        <div className="w-20 h-20 bg-red-500/10 rounded-full flex items-center justify-center mb-6">
          <User className="w-10 h-10 text-red-500" />
        </div>
        <h1 className="text-2xl font-bold mb-2">Profile Not Found</h1>
        <p className="text-gray-400 mb-8 max-w-xs">We couldn't find a student profile associated with this ID.</p>
        <Link href="/" className="px-6 py-3 bg-white/5 border border-white/10 rounded-xl hover:bg-white/10 transition-colors">
          Back to Home
        </Link>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-[#0A0F12] text-white selection:bg-emerald-500/30">
      {/* Background Gradients */}
      <div className="fixed inset-0 overflow-hidden pointer-events-none">
        <div className="absolute -top-[20%] -right-[10%] w-[70vw] h-[70vw] bg-emerald-500/10 blur-[120px] rounded-full"></div>
        <div className="absolute -bottom-[20%] -left-[10%] w-[60vw] h-[60vw] bg-blue-500/5 blur-[120px] rounded-full"></div>
      </div>

      <main className="relative z-10 max-w-2xl mx-auto px-6 pt-24 pb-20">
        {/* Header Navigation */}
        <Link href="/" className="inline-flex items-center gap-2 text-gray-400 hover:text-white transition-colors mb-8 group">
          <ChevronLeft className="w-4 h-4 group-hover:-translate-x-1 transition-transform" />
          <span>Back</span>
        </Link>

        {/* Profile Card */}
        <motion.div 
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="bg-white/[0.03] backdrop-blur-2xl border border-white/[0.08] rounded-[32px] p-8 md:p-12 relative overflow-hidden"
        >
          {/* Verified Badge */}
          <div className="absolute top-8 right-8 px-4 py-1.5 bg-emerald-500 text-white rounded-full text-[10px] font-black uppercase tracking-wider flex items-center gap-1.5 shadow-lg shadow-emerald-500/20">
            <Shield className="w-3 h-3 fill-current" />
            Verified
          </div>

          {/* Profile Header */}
          <div className="flex flex-col items-center text-center mb-10">
            <div className="relative mb-6">
              <img 
                src={user.photoURL || `https://ui-avatars.com/api/?name=${encodeURIComponent(user.name)}&background=10B981&color=fff`} 
                alt={user.name}
                className="w-32 h-32 rounded-[40px] object-cover border-4 border-white/5 shadow-2xl"
              />
              <div className="absolute -bottom-2 -right-2 w-8 h-8 bg-emerald-500 border-4 border-[#0A0F12] rounded-full flex items-center justify-center">
                <div className="w-2 h-2 bg-white rounded-full animate-pulse"></div>
              </div>
            </div>
            
            <h1 className="text-3xl md:text-4xl font-extrabold tracking-tight mb-2 font-[var(--font-jakarta)]">
              {user.name}
            </h1>
            <p className="text-emerald-500 font-bold tracking-wide uppercase text-sm">
              {user.cmsStudentId || user.registrationNo || "Student"}
            </p>
          </div>

          <div className="h-px bg-white/[0.08] w-full mb-10"></div>

          {/* Info Sections */}
          <div className="grid gap-8">
            <InfoSection label="Campus Identity">
              <InfoItem icon={User} label="Father Name" value={user.fatherName || "—"} />
              <InfoItem icon={GraduationCap} label="Department" value={user.department || "Computing"} />
              <InfoItem icon={Calendar} label="Intake Semester" value={user.intakeSemester || "Fall 2022"} />
            </InfoSection>

            <InfoSection label="Contact & Address">
              <InfoItem icon={Mail} label="University Email" value={user.email} />
              <InfoItem icon={Phone} label="Mobile Number" value={user.contactNumber || "—"} />
              <InfoItem icon={MapPin} label="Current Address" value={user.currentAddress || "Islamabad, Pakistan"} />
            </InfoSection>
          </div>

          {/* Action Button */}
          <motion.button
            whileHover={{ scale: 1.02 }}
            whileTap={{ scale: 0.98 }}
            className="w-full mt-12 py-4 bg-emerald-500 hover:bg-emerald-400 text-white font-bold rounded-2xl transition-all shadow-xl shadow-emerald-500/20"
          >
            Contact via Trace App
          </motion.button>
        </motion.div>

        {/* Footer */}
        <div className="mt-12 text-center opacity-40">
            <div className="text-lg font-black tracking-tighter">TRACE<span className="text-emerald-500">.</span></div>
            <p className="text-xs uppercase tracking-widest mt-2">Official Digital Identity Portal</p>
        </div>
      </main>
    </div>
  );
}

function InfoSection({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <div>
      <h3 className="text-[10px] font-black uppercase tracking-[0.2em] text-gray-500 mb-6 px-1">
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
    <div className="flex items-start gap-4 group">
      <div className="w-10 h-10 rounded-xl bg-white/5 border border-white/5 flex items-center justify-center shrink-0 group-hover:bg-emerald-500/10 group-hover:border-emerald-500/20 transition-colors">
        <Icon className="w-5 h-5 text-gray-400 group-hover:text-emerald-500 transition-colors" />
      </div>
      <div className="flex flex-col gap-0.5">
        <span className="text-[11px] text-gray-500 font-medium uppercase tracking-wider">{label}</span>
        <span className="text-base font-semibold text-gray-200">{value}</span>
      </div>
    </div>
  );
}
