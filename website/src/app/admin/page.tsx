"use client";

import { useEffect, useState } from "react";
import { supabase } from "@/lib/supabase";
import { 
  BarChart3, 
  Users, 
  Flag, 
  Trash2, 
  ShieldCheck, 
  Search, 
  LayoutDashboard,
  LogOut,
  AlertTriangle
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

interface Stats {
  totalPosts: number;
  totalUsers: number;
  flaggedPosts: number;
}

export default function AdminDashboard() {
  const [posts, setPosts] = useState<Post[]>([]);
  const [stats, setStats] = useState<Stats>({ totalPosts: 0, totalUsers: 0, flaggedPosts: 0 });
  const [isLoading, setIsLoading] = useState(true);
  const [activeTab, setActiveTab] = useState<"dashboard" | "moderation" | "users">("dashboard");

  useEffect(() => {
    fetchData();
  }, []);

  async function fetchData() {
    setIsLoading(true);
    try {
      // Fetch stats
      const { count: postsCount } = await supabase.from('posts').select('*', { count: 'exact', head: true });
      const { count: usersCount } = await supabase.from('users').select('*', { count: 'exact', head: true });
      const { count: flaggedCount } = await supabase.from('posts').select('*', { count: 'exact', head: true }).eq('isReported', true);

      setStats({
        totalPosts: postsCount || 0,
        totalUsers: usersCount || 0,
        flaggedPosts: flaggedCount || 0
      });

      // Fetch flagged posts
      const { data: flaggedData } = await supabase
        .from('posts')
        .select('*')
        .eq('isReported', true)
        .order('timestamp', { ascending: false });

      setPosts(flaggedData || []);
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

  return (
    <div className="min-h-screen bg-[#F8FAFC] flex">
      {/* Sidebar */}
      <aside className="w-64 bg-[#0A0F1E] text-white p-6 flex flex-col">
        <div className="flex items-center gap-3 mb-10">
          <div className="w-8 h-8 bg-blue-600 rounded flex items-center justify-center">
            <ShieldCheck className="w-5 h-5" />
          </div>
          <span className="font-bold tracking-tight">ADMIN PORTAL</span>
        </div>

        <nav className="flex-1 space-y-1">
          <SidebarLink 
            icon={<LayoutDashboard className="w-5 h-5" />} 
            label="Dashboard" 
            active={activeTab === "dashboard"} 
            onClick={() => setActiveTab("dashboard")} 
          />
          <SidebarLink 
            icon={<Flag className="w-5 h-5" />} 
            label="Moderation" 
            active={activeTab === "moderation"} 
            onClick={() => setActiveTab("moderation")} 
            badge={stats.flaggedPosts > 0 ? stats.flaggedPosts : undefined}
          />
          <SidebarLink 
            icon={<Users className="w-5 h-5" />} 
            label="Users" 
            active={activeTab === "users"} 
            onClick={() => setActiveTab("users")} 
          />
        </nav>

        <div className="mt-auto pt-6 border-t border-white/10">
          <Link href="/" className="flex items-center gap-3 text-gray-400 hover:text-white transition-colors text-sm">
            <LogOut className="w-5 h-5" />
            Logout to Site
          </Link>
        </div>
      </aside>

      {/* Main Content */}
      <main className="flex-1 overflow-y-auto">
        <header className="h-20 bg-white border-b flex items-center justify-between px-10 sticky top-0 z-10">
          <h2 className="text-xl font-bold text-gray-800 capitalize">{activeTab}</h2>
          <div className="flex items-center gap-4">
            <div className="bg-gray-100 rounded-full px-4 py-2 flex items-center gap-2">
              <Search className="w-4 h-4 text-gray-400" />
              <input type="text" placeholder="Search..." className="bg-transparent text-sm outline-none w-48" />
            </div>
            <div className="w-10 h-10 bg-blue-100 rounded-full flex items-center justify-center text-blue-600 font-bold">
              A
            </div>
          </div>
        </header>

        <div className="p-10">
          {activeTab === "dashboard" && (
            <div className="space-y-8">
              <div className="grid md:grid-cols-3 gap-6">
                <StatCard title="Total Posts" value={stats.totalPosts} icon={<BarChart3 className="text-blue-600" />} />
                <StatCard title="Total Users" value={stats.totalUsers} icon={<Users className="text-green-600" />} />
                <StatCard title="Flagged Content" value={stats.flaggedPosts} icon={<Flag className="text-red-600" />} />
              </div>

              <div className="bg-white rounded-3xl border p-8">
                <h3 className="text-lg font-bold mb-6">Recent Moderation Required</h3>
                {isLoading ? (
                  <div className="animate-pulse space-y-4">
                    {[1, 2].map(i => <div key={i} className="h-16 bg-gray-100 rounded-2xl" />)}
                  </div>
                ) : posts.length === 0 ? (
                  <div className="text-center py-20 bg-gray-50 rounded-3xl">
                    <ShieldCheck className="w-12 h-12 text-green-500 mx-auto mb-4 opacity-20" />
                    <p className="text-gray-500">Everything looks clean! No reports found.</p>
                  </div>
                ) : (
                  <div className="space-y-4">
                    {posts.map(post => (
                      <ModerationItem 
                        key={post.id} 
                        post={post} 
                        onDelete={() => deletePost(post.id)} 
                        onIgnore={() => ignoreReports(post.id)}
                      />
                    ))}
                  </div>
                )}
              </div>
            </div>
          )}

          {activeTab === "moderation" && (
            <div className="bg-white rounded-3xl border p-8">
              <h3 className="text-lg font-bold mb-6">All Flagged Content</h3>
              {/* Similar list as above */}
              <div className="space-y-4">
                {posts.map(post => (
                  <ModerationItem 
                    key={post.id} 
                    post={post} 
                    onDelete={() => deletePost(post.id)} 
                    onIgnore={() => ignoreReports(post.id)}
                  />
                ))}
              </div>
            </div>
          )}

          {activeTab === "users" && (
            <div className="text-center py-40">
              <Users className="w-16 h-16 text-gray-300 mx-auto mb-4" />
              <h3 className="text-xl font-bold">User Management</h3>
              <p className="text-gray-500">View and manage campus users here.</p>
            </div>
          )}
        </div>
      </main>
    </div>
  );
}

function SidebarLink({ icon, label, active, onClick, badge }: any) {
  return (
    <button 
      onClick={onClick}
      className={`w-full flex items-center justify-between px-4 py-3 rounded-xl transition-all ${
        active ? "bg-blue-600 text-white" : "text-gray-400 hover:text-white hover:bg-white/5"
      }`}
    >
      <div className="flex items-center gap-3">
        {icon}
        <span className="text-sm font-semibold">{label}</span>
      </div>
      {badge && (
        <span className="bg-red-500 text-white text-[10px] font-bold px-2 py-0.5 rounded-full">
          {badge}
        </span>
      )}
    </button>
  );
}

function StatCard({ title, value, icon }: any) {
  return (
    <div className="bg-white rounded-3xl border p-8 flex items-center justify-between shadow-sm">
      <div>
        <div className="text-sm text-gray-500 mb-1">{title}</div>
        <div className="text-3xl font-extrabold">{value}</div>
      </div>
      <div className="w-14 h-14 bg-gray-50 rounded-2xl flex items-center justify-center">
        {icon}
      </div>
    </div>
  );
}

function ModerationItem({ post, onDelete, onIgnore }: { post: Post, onDelete: any, onIgnore: any }) {
  return (
    <div className="flex items-center justify-between p-6 bg-gray-50 rounded-2xl hover:bg-gray-100 transition-colors">
      <div className="flex items-center gap-4">
        <div className="w-12 h-12 bg-red-100 rounded-xl flex items-center justify-center">
          <AlertTriangle className="w-6 h-6 text-red-600" />
        </div>
        <div>
          <div className="font-bold text-gray-800">{post.title}</div>
          <div className="text-xs text-red-500 font-bold uppercase tracking-wider">
            {post.reportCount} Reports
          </div>
        </div>
      </div>
      <div className="flex items-center gap-2">
        <button 
          onClick={onIgnore}
          className="px-4 py-2 bg-white border rounded-xl text-sm font-bold text-gray-600 hover:bg-gray-50 transition-all"
        >
          Ignore
        </button>
        <button 
          onClick={onDelete}
          className="px-4 py-2 bg-red-600 rounded-xl text-sm font-bold text-white hover:bg-red-700 transition-all"
        >
          Delete Post
        </button>
      </div>
    </div>
  );
}
