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
          className="flex items-center gap-3 text-jade-primary/60 hover:text-jade-primary transition-colors group px-6 py-3 bg-jade-primary/5 rounded-2xl font-bold text-xs uppercase tracking-widest"
        >
          <ArrowLeft className="w-4 h-4 group-hover:-translate-x-1 transition-transform" />
          <span>Back to Directory</span>
        </button>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-12">
           <div className="lg:col-span-1 space-y-8">
              <div className="bg-[var(--card-bg)] border border-[var(--border-color)] rounded-[40px] p-12 text-center relative overflow-hidden shadow-2xl shadow-black/5">
                 <div className="absolute top-0 left-0 w-full h-1.5 bg-jade-primary/20"></div>
                 <div className="w-28 h-28 rounded-[32px] bg-jade-primary/10 border border-jade-primary/20 flex items-center justify-center mx-auto mb-8 text-4xl font-black text-jade-primary shadow-inner">
                    {selectedUser.name.charAt(0)}
                 </div>
                 <h2 className="text-3xl font-black tracking-tighter text-[var(--foreground)] mb-2 uppercase">{selectedUser.name}</h2>
                 <p className="text-[10px] font-bold text-sage-secondary uppercase tracking-[0.2em] mb-10">{selectedUser.email}</p>
                 
                 <div className="flex justify-center gap-4">
                    <div className={`px-5 py-2.5 rounded-2xl text-[10px] font-black uppercase tracking-widest border shadow-sm ${selectedUser.role === 'admin' ? 'bg-jade-primary text-white border-jade-primary' : 'bg-jade-primary/5 border-jade-primary/10 text-jade-primary'}`}>
                       {selectedUser.role}
                    </div>
                    {selectedUser.isBanned && (
                      <div className="px-5 py-2.5 rounded-2xl bg-red-500 text-white shadow-lg shadow-red-500/20 text-[10px] font-black uppercase tracking-widest">
                         Banned
                      </div>
                    )}
                 </div>
              </div>

              <div className="grid grid-cols-2 gap-4">
                 <div className="bg-[var(--card-bg)] border border-[var(--border-color)] p-8 rounded-[32px] text-center shadow-xl shadow-black/5">
                    <Award className="w-6 h-6 text-jade-primary mx-auto mb-4" />
                    <div className="text-2xl font-black text-[var(--foreground)]">{selectedUser.itemsReturned || 0}</div>
                    <div className="text-[9px] font-bold text-sage-secondary uppercase tracking-widest mt-2">Items Returned</div>
                 </div>
                 <div className="bg-[var(--card-bg)] border border-[var(--border-color)] p-8 rounded-[32px] text-center shadow-xl shadow-black/5">
                    <FileText className="w-6 h-6 text-sage-secondary mx-auto mb-4" />
                    <div className="text-2xl font-black text-[var(--foreground)]">{selectedUser.postCount || 0}</div>
                    <div className="text-[9px] font-bold text-sage-secondary uppercase tracking-widest mt-2">Active Posts</div>
                 </div>
              </div>
           </div>

           <div className="lg:col-span-2 space-y-8">
              <div className="bg-[var(--card-bg)] border border-[var(--border-color)] rounded-[40px] p-10 shadow-2xl shadow-black/5">
                 <h3 className="text-sm font-black text-jade-primary uppercase tracking-[0.2em] mb-10 border-b border-[var(--border-color)] pb-6">Account Management</h3>
                 
                 <div className="space-y-6">
                    <div className="flex flex-col sm:flex-row sm:items-center justify-between p-8 bg-jade-primary/5 border border-jade-primary/10 rounded-[32px] group hover:border-jade-primary/30 transition-all gap-6">
                       <div>
                          <div className="text-xs font-black uppercase tracking-widest text-[var(--foreground)] mb-2">Security Clearance</div>
                          <div className="text-[10px] font-bold text-sage-secondary uppercase tracking-widest">Modify administrative privileges</div>
                       </div>
                       <div className="flex flex-wrap gap-3">
                          <button 
                            disabled={processingId === selectedUser.uid}
                            onClick={() => updateUserRole(selectedUser.uid, 'user')}
                            className={`px-6 py-3 rounded-xl text-[10px] font-black uppercase tracking-widest transition-all ${selectedUser.role === 'user' ? 'bg-jade-primary text-white shadow-lg' : 'bg-[var(--background)] text-jade-primary/40 hover:text-jade-primary hover:bg-jade-primary/5'}`}
                          >
                            User
                          </button>
                          <button 
                            disabled={processingId === selectedUser.uid}
                            onClick={() => updateUserRole(selectedUser.uid, 'staff')}
                            className={`px-6 py-3 rounded-xl text-[10px] font-black uppercase tracking-widest transition-all ${selectedUser.role === 'staff' ? 'bg-jade-primary text-white shadow-lg' : 'bg-[var(--background)] text-jade-primary/40 hover:text-jade-primary hover:bg-jade-primary/5'}`}
                          >
                            Staff
                          </button>
                          <button 
                            disabled={processingId === selectedUser.uid}
                            onClick={() => updateUserRole(selectedUser.uid, 'admin')}
                            className={`px-6 py-3 rounded-xl text-[10px] font-black uppercase tracking-widest transition-all ${selectedUser.role === 'admin' ? 'bg-jade-primary text-white shadow-xl shadow-jade-primary/40' : 'bg-[var(--background)] text-jade-primary/40 hover:text-jade-primary hover:bg-jade-primary/5'}`}
                          >
                            Admin
                          </button>
                       </div>
                    </div>

                    <div className="flex flex-col sm:flex-row sm:items-center justify-between p-8 bg-red-500/5 border border-red-500/10 rounded-[32px] group hover:border-red-500/30 transition-all gap-6">
                       <div>
                          <div className="text-xs font-black uppercase tracking-widest text-[var(--foreground)] mb-2">Access Control</div>
                          <div className="text-[10px] font-bold text-sage-secondary uppercase tracking-widest">Suspend or reactivate user access</div>
                       </div>
                       <button 
                        disabled={processingId === selectedUser.uid}
                        onClick={() => toggleBan(selectedUser.uid, !!selectedUser.isBanned)}
                        className={`px-8 py-4 rounded-2xl text-[10px] font-black uppercase tracking-widest transition-all ${selectedUser.isBanned ? 'bg-jade-primary text-white shadow-lg shadow-jade-primary/20' : 'bg-red-500 text-white shadow-lg shadow-red-500/20 hover:bg-red-600'}`}
                       >
                          {selectedUser.isBanned ? 'Reactivate User' : 'Suspend Account'}
                       </button>
                    </div>
                 </div>
              </div>

              <div className="bg-jade-primary/5 border border-jade-primary/10 rounded-[32px] p-8">
                 <div className="flex items-start gap-5">
                    <Shield className="w-6 h-6 text-jade-primary shrink-0 mt-1" />
                    <div>
                       <h4 className="text-xs font-black uppercase tracking-widest text-jade-primary mb-2">Administrative Note</h4>
                       <p className="text-[10px] font-bold text-sage-secondary uppercase leading-relaxed tracking-wider">
                          Role modifications are processed immediately across the Trace ecosystem. System logs will be updated to reflect any changes in security clearance.
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
      <div className="flex flex-col lg:flex-row lg:items-end justify-between gap-8 border-b border-[var(--border-color)] pb-10">
        <div>
          <h1 className="text-4xl font-black tracking-tighter uppercase text-[var(--foreground)]">User <span className="text-jade-primary">Directory</span></h1>
          <p className="text-sm text-jade-primary/60 font-bold uppercase tracking-widest mt-2">Personnel & Access Management</p>
        </div>
        
        <div className="relative group w-full lg:w-[400px]">
          <Search className="absolute left-5 top-1/2 -translate-y-1/2 w-4 h-4 text-jade-primary/40 group-focus-within:text-jade-primary transition-colors" />
          <input 
            type="text" 
            placeholder="Search by name or email..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full bg-[var(--card-bg)] border border-[var(--border-color)] rounded-2xl pl-14 pr-6 py-4 text-xs font-bold uppercase tracking-widest focus:outline-none focus:border-jade-primary/30 transition-all text-[var(--foreground)]"
          />
        </div>
      </div>

      <div className="bg-[var(--card-bg)] border border-[var(--border-color)] rounded-[40px] overflow-hidden shadow-2xl shadow-black/5">
        {/* Desktop Table View */}
        <div className="hidden md:block overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="bg-jade-primary/5 border-b border-[var(--border-color)]">
                <th className="px-10 py-8 text-[10px] font-black text-jade-primary/40 uppercase tracking-widest">User Details</th>
                <th className="px-10 py-8 text-[10px] font-black text-jade-primary/40 uppercase tracking-widest">Role</th>
                <th className="px-10 py-8 text-[10px] font-black text-jade-primary/40 uppercase tracking-widest">App Connection</th>
                <th className="px-10 py-8 text-[10px] font-black text-jade-primary/40 uppercase tracking-widest">Account Status</th>
                <th className="px-10 py-8 text-[10px] font-black text-jade-primary/40 uppercase tracking-widest text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-[var(--border-color)]">
              {isLoading ? (
                [...Array(5)].map((_, i) => (
                  <tr key={i} className="animate-pulse">
                    <td colSpan={5} className="px-10 py-8"><div className="h-10 bg-jade-primary/5 rounded-2xl w-full"></div></td>
                  </tr>
                ))
              ) : filteredUsers.map((user) => (
                <tr key={user.uid} className="hover:bg-jade-primary/5 transition-all group">
                  <td className="px-10 py-10">
                    <div className="flex items-center gap-5">
                      <div className="w-12 h-12 rounded-2xl bg-jade-primary/10 border border-jade-primary/10 flex items-center justify-center font-black text-sm text-jade-primary group-hover:scale-110 transition-transform shadow-inner">
                        {user.name.charAt(0)}
                      </div>
                      <div>
                        <div className="text-sm font-black uppercase tracking-tight text-[var(--foreground)] group-hover:text-jade-primary transition-colors">{user.name}</div>
                        <div className="text-[10px] font-bold text-sage-secondary mt-1 uppercase tracking-widest">{user.email}</div>
                      </div>
                    </div>
                  </td>
                  <td className="px-10 py-10">
                     <div className={`inline-flex items-center gap-2.5 px-4 py-2 rounded-xl bg-jade-primary/5 border border-jade-primary/10 text-[10px] font-black uppercase tracking-widest ${user.role === 'admin' ? 'text-jade-primary border-jade-primary' : 'text-jade-primary/40'}`}>
                        <Shield className="w-4 h-4" />
                        {user.role}
                     </div>
                  </td>
                  <td className="px-10 py-10">
                     <div className="flex items-center gap-3">
                        {user.fcm_token ? (
                          <div className="flex items-center gap-2 text-jade-primary bg-jade-primary/10 px-4 py-1.5 rounded-xl text-[9px] font-black uppercase tracking-widest border border-jade-primary/10">
                             <Bell className="w-3.5 h-3.5" />
                             Connected
                          </div>
                        ) : (
                          <div className="flex items-center gap-2 text-jade-primary/20 bg-jade-primary/5 px-4 py-1.5 rounded-xl text-[9px] font-black uppercase tracking-widest">
                             <BellOff className="w-3.5 h-3.5" />
                             Offline
                          </div>
                        )}
                     </div>
                  </td>
                  <td className="px-10 py-10">
                     {user.isBanned ? (
                       <span className="text-[10px] font-black text-red-500 uppercase tracking-widest flex items-center gap-2.5">
                          <Ban className="w-4 h-4" />
                          Suspended
                       </span>
                     ) : (
                       <span className="text-[10px] font-black text-jade-primary uppercase tracking-widest flex items-center gap-2.5">
                          <CheckCircle2 className="w-4 h-4" />
                          Active
                       </span>
                     )}
                  </td>
                  <td className="px-10 py-10 text-right">
                     <button 
                      onClick={() => setSelectedUser(user)}
                      className="p-4 bg-jade-primary/5 text-jade-primary/40 rounded-2xl hover:text-jade-primary hover:bg-jade-primary/10 transition-all shadow-sm"
                     >
                        <MoreVertical className="w-5 h-5" />
                     </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

        {/* Mobile Card View */}
        <div className="md:hidden divide-y divide-[var(--border-color)]">
          {isLoading ? (
            [...Array(3)].map((_, i) => (
              <div key={i} className="p-8 animate-pulse space-y-6">
                <div className="flex items-center gap-5">
                  <div className="w-12 h-12 rounded-2xl bg-jade-primary/5"></div>
                  <div className="h-5 bg-jade-primary/5 rounded-xl w-1/2"></div>
                </div>
                <div className="h-16 bg-jade-primary/5 rounded-[24px] w-full"></div>
              </div>
            ))
          ) : filteredUsers.map((user) => (
            <div key={user.uid} className="p-8 space-y-6 hover:bg-jade-primary/5 transition-all">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-4">
                  <div className="w-14 h-14 rounded-2xl bg-jade-primary/10 border border-jade-primary/10 flex items-center justify-center font-black text-lg text-jade-primary">
                    {user.name.charAt(0)}
                  </div>
                  <div>
                    <div className="text-base font-black uppercase tracking-tight text-[var(--foreground)]">{user.name}</div>
                    <div className="text-[10px] font-bold text-sage-secondary mt-1 uppercase truncate max-w-[180px] tracking-widest">{user.email}</div>
                  </div>
                </div>
                <button 
                  onClick={() => setSelectedUser(user)}
                  className="p-3 bg-jade-primary/5 text-jade-primary/40 rounded-2xl shadow-sm"
                >
                  <MoreVertical className="w-5 h-5" />
                </button>
              </div>

              <div className="flex flex-wrap gap-3">
                <div className={`flex items-center gap-2 px-4 py-2 rounded-xl bg-jade-primary/5 border border-jade-primary/10 text-[9px] font-black uppercase tracking-widest ${user.role === 'admin' ? 'text-jade-primary border-jade-primary' : 'text-jade-primary/40'}`}>
                  <Shield className="w-3.5 h-3.5" />
                  {user.role}
                </div>
                {user.fcm_token ? (
                  <div className="flex items-center gap-2 text-jade-primary bg-jade-primary/10 px-4 py-2 rounded-xl text-[9px] font-black uppercase tracking-widest border border-jade-primary/10">
                    <Bell className="w-3.5 h-3.5" />
                    Live
                  </div>
                ) : (
                  <div className="flex items-center gap-2 text-jade-primary/20 bg-jade-primary/5 px-4 py-2 rounded-xl text-[9px] font-black uppercase tracking-widest">
                    <BellOff className="w-3.5 h-3.5" />
                    Off
                  </div>
                )}
                {user.isBanned ? (
                  <span className="text-[9px] font-black text-red-500 uppercase tracking-widest flex items-center gap-2 px-4 py-2 rounded-xl bg-red-500/10 border border-red-500/10">
                    <Ban className="w-3.5 h-3.5" />
                    Banned
                  </span>
                ) : (
                  <span className="text-[9px] font-black text-jade-primary uppercase tracking-widest flex items-center gap-2 px-4 py-2 rounded-xl bg-jade-primary/10 border border-jade-primary/10">
                    <CheckCircle2 className="w-3.5 h-3.5" />
                    Active
                  </span>
                )}
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
