"use client";

import { useEffect, useState } from "react";
import { supabase } from "@/lib/supabase";
import { motion, AnimatePresence } from "framer-motion";
import { 
  Users, 
  Shield, 
  Search,
  CheckCircle2,
  Bell,
  BellOff,
  Ban,
  MoreVertical,
  Award,
  FileText,
  UserPlus,
  UserMinus,
  ArrowLeft,
  Loader2
} from "lucide-react";

interface UserProfile {
  uid: string;
  name: string;
  email: string;
  role: string;
  fcm_token?: string;
  isBanned?: boolean;
  itemsReturned?: number;
  postCount?: number;
}

export default function PersonnelManagement() {
  const [users, setUsers] = useState<UserProfile[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState("");
  const [selectedUser, setSelectedUser] = useState<UserProfile | null>(null);
  const [processingId, setProcessingId] = useState<string | null>(null);

  useEffect(() => {
    fetchUsers();
  }, []);

  async function fetchUsers() {
    setIsLoading(true);
    try {
      // Fetch users and their post counts
      const [usersRes, postsRes] = await Promise.all([
        supabase.from('users').select('*').order('name', { ascending: true }),
        supabase.from('posts').select('userId')
      ]);
      
      if (usersRes.error) throw usersRes.error;

      const userList = usersRes.data.map(user => ({
        ...user,
        postCount: postsRes.data?.filter(p => p.userId === user.uid).length || 0
      }));

      setUsers(userList);
    } catch (error) {
      console.error("Error fetching users:", error);
    } finally {
      setIsLoading(false);
    }
  }

  async function updateUserRole(uid: string, newRole: string) {
    setProcessingId(uid);
    try {
      const { error } = await supabase.from('users').update({ role: newRole }).eq('uid', uid);
      if (error) throw error;
      setUsers(users.map(u => u.uid === uid ? { ...u, role: newRole } : u));
      if (selectedUser?.uid === uid) setSelectedUser({ ...selectedUser, role: newRole });
    } catch (error) {
      alert("Role Update Failed: " + (error as any).message);
    } finally {
      setProcessingId(null);
    }
  }

  async function toggleBan(uid: string, currentStatus: boolean) {
    const action = currentStatus ? "unban" : "ban";
    if (!confirm(`Are you sure you want to ${action} this user?`)) return;

    setProcessingId(uid);
    try {
      const { error } = await supabase.from('users').update({ isBanned: !currentStatus }).eq('uid', uid);
      if (error) throw error;
      setUsers(users.map(u => u.uid === uid ? { ...u, isBanned: !currentStatus } : u));
      if (selectedUser?.uid === uid) setSelectedUser({ ...selectedUser, isBanned: !currentStatus });
    } catch (error) {
      alert("Status Update Failed: " + (error as any).message);
    } finally {
      setProcessingId(null);
    }
  }

  const filteredUsers = users.filter(u => 
    u.name.toLowerCase().includes(searchQuery.toLowerCase()) || 
    u.email.toLowerCase().includes(searchQuery.toLowerCase())
  );

  if (selectedUser) {
    return (
      <div className="space-y-12 pb-20">
        <button 
          onClick={() => setSelectedUser(null)}
          className="flex items-center gap-2 text-neutral-500 hover:text-white transition-colors group"
        >
          <ArrowLeft className="w-4 h-4 group-hover:-translate-x-1 transition-transform" />
          <span className="text-[10px] font-mono uppercase tracking-[0.3em]">Back to Registry</span>
        </button>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-12">
           <div className="lg:col-span-1 space-y-8">
              <div className="bg-[#12121F] border border-white/5 rounded-[40px] p-12 text-center relative overflow-hidden">
                 <div className="absolute top-0 left-0 w-full h-1 bg-cyan-500/20"></div>
                 <div className="w-24 h-24 rounded-full bg-cyan-500/10 border border-cyan-500/20 flex items-center justify-center mx-auto mb-6 text-3xl font-mono text-cyan-500">
                    {selectedUser.name.charAt(0)}
                 </div>
                 <h2 className="text-2xl font-bold uppercase tracking-tighter text-white mb-2">{selectedUser.name}</h2>
                 <p className="text-[10px] font-mono text-neutral-600 uppercase tracking-widest mb-8">{selectedUser.email}</p>
                 
                 <div className="flex justify-center gap-3">
                    <div className={`px-4 py-2 rounded-xl text-[9px] font-mono uppercase tracking-widest border ${selectedUser.role === 'admin' ? 'bg-cyan-500/10 border-cyan-500/20 text-cyan-500' : 'bg-white/5 border-white/5 text-neutral-500'}`}>
                       {selectedUser.role}
                    </div>
                    {selectedUser.isBanned && (
                      <div className="px-4 py-2 rounded-xl bg-red-500/10 border border-red-500/20 text-red-500 text-[9px] font-mono uppercase tracking-widest">
                         Banned
                      </div>
                    )}
                 </div>
              </div>

              <div className="grid grid-cols-2 gap-4">
                 <div className="bg-[#12121F] border border-white/5 p-6 rounded-3xl text-center">
                    <Award className="w-5 h-5 text-emerald-500 mx-auto mb-3" />
                    <div className="text-xl font-mono text-white">{selectedUser.itemsReturned || 0}</div>
                    <div className="text-[8px] font-mono text-neutral-600 uppercase tracking-widest mt-1">Returned</div>
                 </div>
                 <div className="bg-[#12121F] border border-white/5 p-6 rounded-3xl text-center">
                    <FileText className="w-5 h-5 text-cyan-500 mx-auto mb-3" />
                    <div className="text-xl font-mono text-white">{selectedUser.postCount || 0}</div>
                    <div className="text-[8px] font-mono text-neutral-600 uppercase tracking-widest mt-1">Reports</div>
                 </div>
              </div>
           </div>

           <div className="lg:col-span-2 space-y-8">
              <div className="bg-[#12121F] border border-white/5 rounded-[40px] p-10">
                 <h3 className="text-[12px] font-mono text-neutral-500 uppercase tracking-[0.3em] mb-10">Administrative Actions</h3>
                 
                 <div className="space-y-6">
                    <div className="flex items-center justify-between p-6 bg-white/[0.02] border border-white/5 rounded-3xl group hover:border-white/10 transition-all">
                       <div>
                          <div className="text-[10px] font-bold uppercase tracking-widest text-white mb-1">Access Elevation</div>
                          <div className="text-[9px] font-mono text-neutral-600 uppercase">Change user's security clearance</div>
                       </div>
                       <div className="flex gap-2">
                          <button 
                            disabled={processingId === selectedUser.uid}
                            onClick={() => updateUserRole(selectedUser.uid, 'user')}
                            className={`px-4 py-2 rounded-xl text-[9px] font-mono uppercase tracking-widest transition-all ${selectedUser.role === 'user' ? 'bg-white/20 text-white' : 'hover:bg-white/10 text-neutral-500'}`}
                          >
                            User
                          </button>
                          <button 
                            disabled={processingId === selectedUser.uid}
                            onClick={() => updateUserRole(selectedUser.uid, 'staff')}
                            className={`px-4 py-2 rounded-xl text-[9px] font-mono uppercase tracking-widest transition-all ${selectedUser.role === 'staff' ? 'bg-cyan-500 text-black' : 'hover:bg-white/10 text-neutral-500'}`}
                          >
                            Staff
                          </button>
                          <button 
                            disabled={processingId === selectedUser.uid}
                            onClick={() => updateUserRole(selectedUser.uid, 'admin')}
                            className={`px-4 py-2 rounded-xl text-[9px] font-mono uppercase tracking-widest transition-all ${selectedUser.role === 'admin' ? 'bg-cyan-500 text-black shadow-[0_0_15px_rgba(6,182,212,0.4)]' : 'hover:bg-white/10 text-neutral-500'}`}
                          >
                            Admin
                          </button>
                       </div>
                    </div>

                    <div className="flex items-center justify-between p-6 bg-white/[0.02] border border-white/5 rounded-3xl group hover:border-red-500/20 transition-all">
                       <div>
                          <div className="text-[10px] font-bold uppercase tracking-widest text-white mb-1">Terminal Restriction</div>
                          <div className="text-[9px] font-mono text-neutral-600 uppercase">Suspend or restore account access</div>
                       </div>
                       <button 
                        disabled={processingId === selectedUser.uid}
                        onClick={() => toggleBan(selectedUser.uid, !!selectedUser.isBanned)}
                        className={`px-6 py-3 rounded-xl text-[9px] font-mono uppercase tracking-widest transition-all ${selectedUser.isBanned ? 'bg-emerald-500 text-black' : 'bg-red-500/10 text-red-500 hover:bg-red-500 hover:text-white'}`}
                       >
                          {selectedUser.isBanned ? 'Restore Access' : 'Terminate Link'}
                       </button>
                    </div>
                 </div>
              </div>

              <div className="bg-cyan-500/5 border border-cyan-500/10 rounded-3xl p-8">
                 <div className="flex items-start gap-4">
                    <Shield className="w-5 h-5 text-cyan-500 shrink-0 mt-1" />
                    <div>
                       <h4 className="text-[10px] font-bold uppercase tracking-widest text-cyan-500 mb-2">Surveillance Note</h4>
                       <p className="text-[9px] font-mono text-cyan-500/50 uppercase leading-relaxed tracking-wider">
                          User history and metadata are synchronized across the Trace network. Any role changes will take effect immediately upon the next terminal uplink.
                       </p>
                    </div>
                 </div>
              </div>
           </div>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-12 pb-20">
      <div className="flex flex-col lg:flex-row lg:items-end justify-between gap-8 border-b border-white/5 pb-10">
        <div>
          <h1 className="text-3xl font-black tracking-tighter uppercase font-mono italic">Personnel Registry</h1>
          <p className="text-[10px] font-mono text-neutral-500 uppercase tracking-[0.3em] mt-2">Identify and manage all authorized nodes in the system</p>
        </div>
        
        <div className="relative group w-full lg:w-96">
          <Search className="absolute left-4 top-1/2 -translate-y-1/2 w-4 h-4 text-neutral-600 group-focus-within:text-cyan-500 transition-colors" />
          <input 
            type="text" 
            placeholder="Search by name/email..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full bg-[#12121F] border border-white/5 rounded-2xl pl-12 pr-4 py-4 text-[10px] font-mono uppercase tracking-widest focus:outline-none focus:border-cyan-500/30 transition-all"
          />
        </div>
      </div>

      <div className="bg-[#12121F] border border-white/5 rounded-[40px] overflow-hidden">
        <table className="w-full text-left border-collapse">
          <thead>
            <tr className="bg-white/[0.02] border-b border-white/5">
              <th className="px-8 py-6 text-[9px] font-mono text-neutral-500 uppercase tracking-widest">Identification</th>
              <th className="px-8 py-6 text-[9px] font-mono text-neutral-500 uppercase tracking-widest">Clearance</th>
              <th className="px-8 py-6 text-[9px] font-mono text-neutral-500 uppercase tracking-widest">Telemetry</th>
              <th className="px-8 py-6 text-[9px] font-mono text-neutral-500 uppercase tracking-widest">Status</th>
              <th className="px-8 py-6 text-[9px] font-mono text-neutral-500 uppercase tracking-widest text-right">Terminal</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-white/[0.03]">
            {isLoading ? (
              [...Array(5)].map((_, i) => (
                <tr key={i} className="animate-pulse">
                  <td colSpan={5} className="px-8 py-6"><div className="h-6 bg-white/5 rounded-xl w-full"></div></td>
                </tr>
              ))
            ) : filteredUsers.map((user) => (
              <tr key={user.uid} className="hover:bg-white/[0.01] transition-all group">
                <td className="px-8 py-8">
                  <div className="flex items-center gap-4">
                    <div className="w-10 h-10 rounded-xl bg-white/5 border border-white/10 flex items-center justify-center font-mono text-xs text-cyan-500 group-hover:scale-110 transition-transform">
                      {user.name.charAt(0)}
                    </div>
                    <div>
                      <div className="text-xs font-bold uppercase tracking-wide text-white group-hover:text-cyan-400 transition-colors">{user.name}</div>
                      <div className="text-[9px] font-mono text-neutral-600 mt-1 uppercase">{user.email}</div>
                    </div>
                  </div>
                </td>
                <td className="px-8 py-8">
                   <div className={`inline-flex items-center gap-2 px-3 py-1.5 rounded-xl bg-white/5 border border-white/5 text-[9px] font-mono uppercase tracking-widest ${user.role === 'admin' ? 'text-cyan-500 border-cyan-500/20' : 'text-neutral-500'}`}>
                      <Shield className="w-3.5 h-3.5" />
                      {user.role}
                   </div>
                </td>
                <td className="px-8 py-8">
                   <div className="flex items-center gap-3">
                      {user.fcm_token ? (
                        <div className="flex items-center gap-1.5 text-emerald-500 bg-emerald-500/5 px-2.5 py-1 rounded-lg text-[8px] font-mono uppercase tracking-widest border border-emerald-500/10">
                           <Bell className="w-3 h-3" />
                           Link Active
                        </div>
                      ) : (
                        <div className="flex items-center gap-1.5 text-neutral-600 bg-white/5 px-2.5 py-1 rounded-lg text-[8px] font-mono uppercase tracking-widest">
                           <BellOff className="w-3 h-3" />
                           Offline
                        </div>
                      )}
                   </div>
                </td>
                <td className="px-8 py-8">
                   {user.isBanned ? (
                     <span className="text-[9px] font-mono text-red-500 uppercase tracking-widest flex items-center gap-2">
                        <Ban className="w-3.5 h-3.5 animate-pulse" />
                        Blacklisted
                     </span>
                   ) : (
                     <span className="text-[9px] font-mono text-emerald-500 uppercase tracking-widest flex items-center gap-2">
                        <CheckCircle2 className="w-3.5 h-3.5" />
                        Operational
                     </span>
                   )}
                </td>
                <td className="px-8 py-8 text-right">
                   <button 
                    onClick={() => setSelectedUser(user)}
                    className="p-3 bg-white/5 text-neutral-500 rounded-xl hover:text-white hover:bg-white/10 transition-all"
                   >
                      <MoreVertical className="w-4 h-4" />
                   </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
