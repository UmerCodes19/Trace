"use client";

import { useEffect, useState } from "react";
import { supabase } from "@/lib/supabase";
import { motion, AnimatePresence } from "framer-motion";
import { 
  Users, 
  Flag, 
  ShieldCheck, 
  Search, 
  LayoutDashboard,
  LogOut,
  AlertTriangle,
  CheckCircle2,
  Terminal,
  Grid,
  Map,
  Zap,
  Activity,
  Sun,
  Moon,
  Database,
  Shield,
  Layers,
  Menu,
  X
} from "lucide-react";
import Link from "next/link";

interface Post {
  id: string;
  title: string;
  type: string;
  isReported: boolean;
  reportCount: number;
  userId: string;
  timestamp: string;
}

interface User {
  uid: string;
  name: string;
  email: string;
  itemsReturned: number;
  karmaPoints: number;
  isBanned: boolean;
}

interface Stats {
  totalPosts: number;
  totalUsers: number;
  flaggedPosts: number;
  itemsReturned: number;
}

const containerVariants = {
  hidden: { opacity: 0 },
  show: {
    opacity: 1,
    transition: {
      staggerChildren: 0.1
    }
  }
} as const;

const itemVariants = {
  hidden: { opacity: 0, y: 10 },
  show: { opacity: 1, y: 0, transition: { type: "spring" as const, stiffness: 300, damping: 24 } }
} as const;

export default function TraceAdminDashboard() {
  const [posts, setPosts] = useState<Post[]>([]);
  const [users, setUsers] = useState<User[]>([]);
  const [stats, setStats] = useState<Stats>({ totalPosts: 0, totalUsers: 0, flaggedPosts: 0, itemsReturned: 0 });
  const [isLoading, setIsLoading] = useState(true);
  const [activeTab, setActiveTab] = useState<"dashboard" | "users">("dashboard");
  const [searchQuery, setSearchQuery] = useState("");
  const [theme, setTheme] = useState<'dark' | 'light'>('dark');
  const [isSidebarOpen, setIsSidebarOpen] = useState(false);

  useEffect(() => {
    fetchData();
    const currentTheme = document.documentElement.getAttribute('data-theme') as 'dark' | 'light' || 'dark';
    setTheme(currentTheme);
  }, [activeTab]);

  const toggleTheme = () => {
    const newTheme = theme === 'dark' ? 'light' : 'dark';
    document.documentElement.setAttribute('data-theme', newTheme);
    setTheme(newTheme);
  };

  async function fetchData() {
    setIsLoading(true);
    try {
      const { count: postsCount } = await supabase.from('posts').select('*', { count: 'exact', head: true });
      const { count: usersCount } = await supabase.from('users').select('*', { count: 'exact', head: true });
      const { count: flaggedCount } = await supabase.from('posts').select('*', { count: 'exact', head: true }).eq('isReported', true);
      
      const { data: userData } = await supabase.from('users').select('itemsReturned');
      const returnedTotal = userData?.reduce((acc, curr) => acc + (curr.itemsReturned || 0), 0) || 0;

      setStats({
        totalPosts: postsCount || 0,
        totalUsers: usersCount || 0,
        flaggedPosts: flaggedCount || 0,
        itemsReturned: returnedTotal
      });

      if (activeTab === "dashboard") {
        const { data: flaggedData } = await supabase
          .from('posts')
          .select('*')
          .eq('isReported', true)
          .order('timestamp', { ascending: false });
        setPosts(flaggedData || []);
      }

      if (activeTab === "users") {
        const { data: allUsers } = await supabase
          .from('users')
          .select('*')
          .order('karmaPoints', { ascending: false });
        setUsers(allUsers || []);
      }
    } catch (error) {
      console.error("Error fetching admin data:", error);
    } finally {
      setIsLoading(false);
    }
  }

  async function deletePost(id: string) {
    if (!confirm("Are you sure you want to delete this post?")) return;
    const { error } = await supabase.from('posts').delete().eq('id', id);
    if (!error) fetchData();
  }

  async function ignoreReports(id: string) {
    const { error } = await supabase.from('posts').update({ isReported: false, reportCount: 0 }).eq('id', id);
    if (!error) fetchData();
  }

  async function toggleBanUser(uid: string, currentStatus: boolean) {
    const { error } = await supabase.from('users').update({ isBanned: !currentStatus }).eq('uid', uid);
    if (!error) fetchData();
  }

  return (
    <div className="min-h-screen bg-[var(--background)] text-[var(--foreground)] flex flex-col md:flex-row overflow-hidden font-sans selection:bg-foreground/10 bg-noise transition-colors duration-500">
      
      {/* Mobile Sidebar Overlay */}
      <AnimatePresence>
        {isSidebarOpen && (
          <motion.div 
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            onClick={() => setIsSidebarOpen(false)}
            className="fixed inset-0 bg-black/60 backdrop-blur-sm z-30 md:hidden"
          />
        )}
      </AnimatePresence>

      {/* Sidebar */}
      <aside className={`
        fixed md:relative inset-y-0 left-0 w-[280px] border-r border-[var(--border-color)] flex flex-col z-40 shrink-0 bg-[var(--card-bg)] transition-transform duration-500 md:translate-x-0
        ${isSidebarOpen ? 'translate-x-0' : '-translate-x-full md:translate-x-0'}
      `}>
        <div className="p-8">
          <div className="flex items-center justify-between mb-12">
            <div className="flex items-center gap-3 relative group">
              <div className="w-8 h-8 border border-[var(--border-color)] bg-[var(--background)] flex items-center justify-center pixel-corners relative overflow-hidden">
                 <div className="absolute inset-0 glow-cyan-accent opacity-20"></div>
                 <Terminal className="w-4 h-4 text-[var(--foreground)] relative z-10 group-hover:scale-110 transition-transform" />
              </div>
              <div>
                <span className="block text-sm font-bold tracking-[0.2em] uppercase font-mono">Console</span>
                <span className="block text-[8px] font-medium text-neutral-600 tracking-[0.4em] uppercase">MomentUUM Labs</span>
              </div>
            </div>
            <button onClick={() => setIsSidebarOpen(false)} className="md:hidden p-2 text-neutral-500">
              <X className="w-5 h-5" />
            </button>
          </div>

          <nav className="space-y-1">
            <SidebarLink 
              icon={<LayoutDashboard className="w-4 h-4" />} 
              label="Overview" 
              active={activeTab === "dashboard"} 
              onClick={() => { setActiveTab("dashboard"); setIsSidebarOpen(false); }} 
            />
            <SidebarLink 
              icon={<Users className="w-4 h-4" />} 
              label="Personnel" 
              active={activeTab === "users"} 
              onClick={() => { setActiveTab("users"); setIsSidebarOpen(false); }} 
            />
          </nav>
        </div>

        <div className="mt-auto p-8 space-y-6 border-t border-[var(--border-color)]">
          {/* Theme Toggle */}
          <button 
            onClick={toggleTheme}
            className="w-full flex items-center gap-3 px-6 py-3 border border-[var(--border-color)] bg-[var(--background)] hover:bg-[var(--foreground)]/5 transition-all pixel-corners group"
          >
            {theme === 'dark' ? (
              <>
                <Sun className="w-3.5 h-3.5 text-neutral-500 group-hover:text-white" />
                <span className="text-[9px] font-mono uppercase tracking-[0.3em]">Light Mode</span>
              </>
            ) : (
              <>
                <Moon className="w-3.5 h-3.5 text-neutral-500 group-hover:text-black" />
                <span className="text-[9px] font-mono uppercase tracking-[0.3em]">Dark Mode</span>
              </>
            )}
          </button>

          <Link href="/" className="flex items-center gap-3 text-neutral-500 hover:text-[var(--foreground)] transition-colors text-[9px] font-mono uppercase tracking-[0.3em] group">
            <LogOut className="w-4 h-4 group-hover:-translate-x-1 transition-transform" />
            <span>Termination</span>
          </Link>
        </div>
      </aside>

      {/* Main Content */}
      <main className="flex-1 overflow-y-auto relative bg-[var(--background)] min-w-0">
        
        <header className="h-20 border-b border-[var(--border-color)] flex items-center justify-between px-6 md:px-10 sticky top-0 z-20 bg-[var(--background)]/80 backdrop-blur-md transition-colors duration-500">
          <div className="flex items-center gap-4">
             <button onClick={() => setIsSidebarOpen(true)} className="md:hidden p-2 -ml-2 text-neutral-500 hover:text-[var(--foreground)]">
                <Menu className="w-5 h-5" />
             </button>
             <div className="hidden sm:flex text-[8px] font-mono text-neutral-500 border border-[var(--border-color)] bg-[var(--foreground)]/5 px-2 py-1 rounded-sm uppercase tracking-[0.4em] items-center gap-2">
                <div className="w-1.5 h-1.5 bg-retro-green rounded-full animate-pulse shadow-[0_0_8px_#10b981]"></div>
                SYS_STABLE
             </div>
             <h2 className="text-lg md:text-xl font-bold tracking-tighter uppercase font-mono truncate">{activeTab}</h2>
          </div>
          
          <div className="flex items-center gap-4 md:gap-6">
            <div className="hidden lg:flex bg-[var(--card-bg)] border border-[var(--border-color)] rounded-sm px-4 py-2 items-center gap-2 w-64 focus-within:border-[var(--foreground)]/20 transition-colors">
              <Search className="w-3 h-3 text-neutral-700" />
              <input 
                type="text" 
                placeholder="Query_DB..." 
                className="bg-transparent text-[10px] font-mono uppercase tracking-widest outline-none w-full placeholder:text-neutral-700"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
              />
            </div>
            <div className="w-8 h-8 bg-[var(--foreground)]/5 border border-[var(--border-color)] rounded-sm flex items-center justify-center text-[10px] font-bold font-mono shrink-0">
              SU
            </div>
          </div>
        </header>

        <div className="p-6 md:p-10 max-w-7xl mx-auto">
          <AnimatePresence mode="wait">
            {activeTab === "dashboard" && (
              <motion.div 
                key="dashboard"
                variants={containerVariants}
                initial="hidden"
                animate="show"
                className="space-y-8 md:space-y-12"
              >
                {/* Symbolic Stats Grid */}
                <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 md:gap-6">
                  <motion.div variants={itemVariants}>
                    <StatCard title="Nodes" value={stats.totalPosts} color="cyan" icon={<Layers />} desc="Database Clusters" />
                  </motion.div>
                  <motion.div variants={itemVariants}>
                    <StatCard title="Personnel" value={stats.totalUsers} color="white" icon={<Users />} desc="Active Users" />
                  </motion.div>
                  <motion.div variants={itemVariants}>
                    <StatCard title="Flagged" value={stats.flaggedPosts} color="red" alert={stats.flaggedPosts > 0} icon={<Flag />} desc="Action Required" />
                  </motion.div>
                  <motion.div variants={itemVariants}>
                    <StatCard title="Matches" value={stats.itemsReturned} color="amber" icon={<ShieldCheck />} desc="Successful Handshakes" />
                  </motion.div>
                </div>

                <motion.div variants={itemVariants} className="space-y-6">
                  <div className="flex flex-col sm:flex-row sm:items-center justify-between border-b border-[var(--border-color)] pb-4 gap-4">
                    <div className="flex items-center gap-3">
                       <Activity className="w-4 h-4 text-neutral-600" />
                       <h3 className="text-[10px] font-mono text-neutral-600 uppercase tracking-[0.3em] md:tracking-[0.4em]">Live_Moderation_Queue</h3>
                    </div>
                    <button onClick={fetchData} className="text-[9px] font-mono text-neutral-500 hover:text-[var(--foreground)] transition-colors flex items-center gap-2 group self-start sm:self-auto">
                       <Zap className="w-3 h-3 group-hover:rotate-12 transition-transform" /> Sync_Records
                    </button>
                  </div>

                  <div className="min-h-[300px] md:min-h-[400px]">
                    {isLoading ? (
                      <div className="space-y-2">
                        {[1, 2, 3].map(i => <div key={i} className="h-14 bg-[var(--foreground)]/[0.02] rounded-sm animate-pulse" />)}
                      </div>
                    ) : (
                      <motion.div variants={containerVariants} initial="hidden" animate="show" className="space-y-2">
                        {posts.map(post => (
                          <motion.div key={post.id} variants={itemVariants}>
                             <ModerationItem 
                                post={post} 
                                onDelete={() => deletePost(post.id)} 
                                onIgnore={() => ignoreReports(post.id)}
                             />
                          </motion.div>
                        ))}
                        {posts.length === 0 && (
                          <div className="text-[9px] font-mono text-neutral-700 uppercase tracking-widest text-center py-20 border border-dashed border-[var(--border-color)]">
                            No anomalies detected in the current stream.
                          </div>
                        )}
                      </motion.div>
                    )}
                  </div>
                </motion.div>
              </motion.div>
            )}

            {activeTab === "users" && (
              <motion.div key="users" variants={containerVariants} initial="hidden" animate="show" className="space-y-6">
                <div className="border border-[var(--border-color)] rounded-sm overflow-x-auto bg-[var(--card-bg)] no-scrollbar">
                  <table className="w-full text-left text-[10px] uppercase tracking-widest min-w-[600px]">
                    <thead className="bg-[var(--background)] border-b border-[var(--border-color)]">
                      <tr>
                        <th className="px-6 md:px-8 py-6 font-mono text-neutral-600">Identity</th>
                        <th className="px-6 md:px-8 py-6 font-mono text-neutral-600">Karma_Rating</th>
                        <th className="px-6 md:px-8 py-6 font-mono text-neutral-600 text-right">Access_Status</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-[var(--border-color)]">
                      {users.filter(u => u.name.toLowerCase().includes(searchQuery.toLowerCase()) || u.uid.includes(searchQuery)).map(user => (
                        <tr key={user.uid} className="hover:bg-[var(--foreground)]/[0.01] transition-colors group">
                          <td className="px-6 md:px-8 py-6">
                            <div className="font-bold text-[var(--foreground)]">{user.name}</div>
                            <div className="text-neutral-700 text-[8px] mt-1 font-mono">{user.uid}</div>
                          </td>
                          <td className="px-6 md:px-8 py-6 text-[var(--foreground)] font-mono">{user.karmaPoints}</td>
                          <td className="px-6 md:px-8 py-6 text-right">
                            <button 
                              onClick={() => toggleBanUser(user.uid, user.isBanned)}
                              className={`px-4 py-2 border text-[9px] font-mono tracking-widest transition-all ${user.isBanned ? 'bg-retro-red text-white border-retro-red' : 'bg-transparent text-neutral-600 border-[var(--border-color)] hover:border-[var(--foreground)] hover:text-[var(--foreground)]'}`}
                            >
                              {user.isBanned ? 'Restricted' : 'Authorize'}
                            </button>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              </motion.div>
            )}
          </AnimatePresence>
        </div>
      </main>
    </div>
  );
}

function SidebarLink({ icon, label, active, onClick }: any) {
  return (
    <button onClick={onClick} className={`w-full flex items-center gap-3 px-8 py-4 transition-all relative ${active ? "bg-[var(--foreground)]/5 text-[var(--foreground)]" : "text-neutral-600 hover:text-[var(--foreground)]"}`}>
      {active && <div className="absolute left-0 top-0 bottom-0 w-[2px] bg-[var(--foreground)]" />}
      <div className="w-4 h-4">{icon}</div>
      <span className="text-[9px] font-mono uppercase tracking-[0.3em]">{label}</span>
    </button>
  );
}

function StatCard({ title, value, alert, color, icon, desc }: any) {
  const colorMap: any = {
    cyan: "text-retro-cyan",
    red: "text-retro-red",
    amber: "text-retro-amber",
    white: "text-[var(--foreground)]"
  };

  return (
    <div className={`bg-[var(--card-bg)] border p-6 md:p-8 rounded-sm transition-all duration-500 h-full ${alert ? 'border-retro-red/30 bg-retro-red/5' : 'border-[var(--border-color)] hover:border-[var(--foreground)]/10'}`}>
      <div className="text-[9px] font-mono text-neutral-600 uppercase tracking-[0.5em] mb-4 md:mb-6 flex items-center gap-3">
         <div className={colorMap[color]}>{icon}</div>
         {title}
      </div>
      <div className={`text-3xl md:text-4xl font-mono tracking-tighter ${colorMap[color]}`}>{value}</div>
      <div className="text-[7px] font-mono text-neutral-800 uppercase tracking-[0.3em] mt-4">{desc}</div>
    </div>
  );
}

function ModerationItem({ post, onDelete, onIgnore }: { post: Post, onDelete: any, onIgnore: any }) {
  return (
    <div className="flex flex-col sm:flex-row sm:items-center justify-between p-4 md:p-5 bg-[var(--card-bg)] border border-[var(--border-color)] hover:border-[var(--foreground)]/10 rounded-sm transition-all gap-4">
      <div className="flex items-center gap-4 md:gap-6">
        <div className="w-1.5 h-1.5 bg-retro-red rounded-full shadow-[0_0_8px_#ef4444] animate-pulse shrink-0"></div>
        <div className="min-w-0">
          <div className="text-[10px] font-bold text-[var(--foreground)] uppercase tracking-widest truncate">{post.title}</div>
          <div className="text-[8px] font-mono text-neutral-700 uppercase tracking-widest mt-1 truncate">ID: {post.id.split('-')[0]} // SCAN_ANOMALY</div>
        </div>
      </div>
      <div className="flex items-center gap-4 md:gap-6">
        <button onClick={onIgnore} className="text-[8px] font-mono text-neutral-700 hover:text-[var(--foreground)] transition-colors uppercase tracking-widest whitespace-nowrap">[ Bypass ]</button>
        <button onClick={onDelete} className="text-[8px] font-mono text-retro-red/60 hover:text-retro-red transition-colors uppercase tracking-widest whitespace-nowrap">[ Terminate ]</button>
      </div>
    </div>
  );
}
