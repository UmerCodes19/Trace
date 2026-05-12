"use client";

import { useEffect, useState } from "react";
import { useParams } from "next/navigation";
import { motion } from "framer-motion";
import { createClient } from "@supabase/supabase-js";
import { User, Shield, MapPin, GraduationCap, Calendar, Mail, Phone, ChevronLeft, Hash, Activity } from "lucide-react";
import Link from "next/link";

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
      const { data, error } = await supabase.from("users").select("*").eq("uid", uid).single();
      if (data) setUser(data);
      setLoading(false);
    }
    fetchUser();
  }, [uid]);

  if (loading) {
    return (
      <div className="min-h-screen bg-[var(--background)] flex flex-col items-center justify-center gap-4">
        <Activity className="w-8 h-8 text-jade-primary animate-pulse" />
        <span className="text-xs font-bold text-sage-secondary uppercase tracking-widest">Loading Profile...</span>
      </div>
    );
  }

  if (!user) {
    return (
      <div className="min-h-screen bg-[var(--background)] flex flex-col items-center justify-center p-6 text-center">
        <div className="w-16 h-16 bg-[var(--card-bg)] border border-red-500/20 rounded-2xl flex items-center justify-center mb-6 shadow-sm">
          <Shield className="w-6 h-6 text-red-500" />
        </div>
        <h1 className="text-2xl font-black mb-2 uppercase tracking-tight text-[var(--foreground)]">Not Found</h1>
        <p className="text-sage-secondary mb-8 max-w-xs text-xs font-bold uppercase tracking-wider">This user could not be found.</p>
        <Link href="/" className="px-8 py-3 bg-jade-primary text-white font-bold text-xs uppercase tracking-widest rounded-xl shadow-md hover:bg-jade-deep transition-all">
          Go Back
        </Link>
      </div>
    );
  }

  const privacy = user.privacy_settings || {
    showFatherName: true,
    showContactNumber: true,
    showAddress: true,
    showRegistrationNo: true,
    showDepartment: true
  };

  return (
    <div className="min-h-screen bg-[var(--background)] text-[var(--foreground)] transition-colors selection:bg-jade-primary/30 font-sans overflow-x-hidden pt-12">
      
      {/* Dynamic Background Glow */}
      <div className="fixed inset-0 overflow-hidden pointer-events-none opacity-30">
        <div className="absolute top-0 left-1/2 -translate-x-1/2 w-[80vw] h-[40vh] bg-jade-primary/10 blur-[120px] rounded-full" />
      </div>

      <main className="relative z-10 max-w-xl mx-auto px-6 pt-20 pb-20">
        
        {/* Branded Navigation */}
        <div className="flex items-center justify-between mb-8">
          <Link href="/" className="flex items-center gap-2 text-jade-primary font-bold text-xs uppercase tracking-wider hover:opacity-70 transition-opacity">
            <ChevronLeft className="w-4 h-4" /> Back to Home
          </Link>
          <div className="flex items-center gap-2 px-4 py-2 border border-[var(--border-color)] bg-[var(--card-bg)] rounded-xl font-bold text-[10px] text-sage-secondary uppercase tracking-widest shadow-sm">
             <div className="w-2 h-2 bg-jade-primary rounded-full animate-pulse" />
             User Profile
          </div>
        </div>

        {/* Core Digital ID Frame */}
        <motion.div 
          initial={{ opacity: 0, y: 15 }}
          animate={{ opacity: 1, y: 0 }}
          className="bg-[var(--card-bg)] border border-[var(--border-color)] rounded-3xl p-8 md:p-10 relative shadow-xl shadow-black/5"
        >
          {/* Absolute Verified Badge */}
          <div className="absolute top-8 right-8">
             <div className="px-3 py-1.5 bg-jade-primary/10 border border-jade-primary/20 text-jade-primary text-[10px] font-bold uppercase tracking-wider flex items-center gap-2 rounded-full">
               <Shield className="w-3.5 h-3.5" />
               Verified
             </div>
          </div>

          {/* Profile Details */}
          <div className="flex flex-col items-center text-center mb-10 pt-4">
            <div className="relative mb-6">
               <div className="w-28 h-28 bg-[var(--background)] border-2 border-[var(--border-color)] p-1 rounded-full overflow-hidden shadow-sm">
                  <img 
                    src={user.photoURL || `https://ui-avatars.com/api/?name=${encodeURIComponent(user.name)}&background=00796B&color=ffffff`} 
                    alt={user.name}
                    className="w-full h-full object-cover rounded-full"
                  />
               </div>
            </div>
            
            <h1 className="text-3xl font-black tracking-tight mb-2 text-[var(--foreground)] capitalize leading-tight">
              {user.name}
            </h1>
            <div className="flex items-center gap-2 text-xs text-sage-secondary font-bold uppercase tracking-wider">
              <Hash className="w-3.5 h-3.5 text-jade-primary" />
              {(privacy.showRegistrationNo ? (user.cmsStudentId || user.registrationNo) : null) || "No ID Linked"}
            </div>
          </div>

          <div className="h-px bg-[var(--border-color)] w-full mb-10" />

          {/* Details Section */}
          <div className="space-y-10">
            <DataCluster label="Campus Information">
              {privacy.showFatherName && <DataItem icon={User} label="Father Name" value={user.fatherName || "Not Provided"} />}
              {privacy.showDepartment && <DataItem icon={GraduationCap} label="Department" value={user.department || "General"} />}
              <DataItem icon={Calendar} label="Enrollment" value={user.intakeSemester || "Student"} />
            </DataCluster>

            <DataCluster label="Contact Info">
              <DataItem icon={Mail} label="Email" value={user.email} />
              {privacy.showContactNumber && <DataItem icon={Phone} label="Phone" value={user.contactNumber || "Hidden"} />}
              {privacy.showAddress && <DataItem icon={MapPin} label="Address" value={user.currentAddress || "Islamabad"} />}
            </DataCluster>
          </div>

          {/* Main Button */}
          <motion.button
            whileHover={{ scale: 1.01 }}
            whileTap={{ scale: 0.98 }}
            className="w-full mt-12 py-4 bg-jade-primary hover:bg-jade-deep text-white font-bold uppercase tracking-widest text-xs transition-all shadow-lg shadow-jade-primary/10 rounded-xl"
          >
            Send Message
          </motion.button>
        </motion.div>

        <div className="mt-12 text-center opacity-40">
            <div className="text-xl font-black tracking-wide text-[var(--foreground)]">Trace<span className="text-jade-primary">.</span></div>
        </div>
      </main>
    </div>
  );
}

function DataCluster({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <div className="space-y-5">
      <h3 className="text-xs font-bold uppercase tracking-widest text-sage-secondary px-1">
        {label}
      </h3>
      <div className="grid gap-5 pl-2">
        {children}
      </div>
    </div>
  );
}

function DataItem({ icon: Icon, label, value }: { icon: any; label: string; value: string }) {
  return (
    <div className="flex items-center gap-4 group bg-[var(--background)] p-4 rounded-2xl border border-[var(--border-color)] hover:border-jade-primary/30 transition-colors shadow-sm">
      <div className="w-10 h-10 border border-[var(--border-color)] bg-[var(--card-bg)] flex items-center justify-center shrink-0 rounded-xl shadow-sm">
        <Icon className="w-4 h-4 text-jade-primary group-hover:scale-110 transition-transform" />
      </div>
      <div className="flex flex-col justify-center">
        <span className="text-[10px] text-sage-secondary font-bold uppercase tracking-wider">{label}</span>
        <span className="text-sm font-bold text-[var(--foreground)] tracking-tight">{value}</span>
      </div>
    </div>
  );
}

