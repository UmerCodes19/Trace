"use client";

import { useEffect, useState } from "react";
import { supabase } from "@/lib/supabase";
import { motion, AnimatePresence } from "framer-motion";
import { 
  AlertTriangle, 
  CheckCircle2, 
  XCircle, 
  Search,
  MessageSquare,
  Loader2,
  Calendar,
  User as UserIcon,
  Trash2,
  Eye,
  ArrowLeft
} from "lucide-react";

interface Post {
  id: string;
  title: string;
  type: string;
  status: string;
  isReported: boolean;
  userId: string;
  timestamp: number;
  description: string;
  location?: string;
  imageUrl?: string;
}

export default function AdminContentManagement() {
  const [posts, setPosts] = useState<Post[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [filter, setFilter] = useState<"all" | "reported">("all");
  const [selectedPost, setSelectedPost] = useState<Post | null>(null);
  const [processingId, setProcessingId] = useState<string | null>(null);
  const [searchQuery, setSearchQuery] = useState("");

  useEffect(() => {
    fetchPosts();
  }, [filter]);

  async function fetchPosts() {
    setIsLoading(true);
    try {
      let query = supabase.from('posts').select('*').order('timestamp', { ascending: false });
      if (filter === "reported") {
        query = query.eq('isReported', true);
      }
      const { data } = await query;
      setPosts(data || []);
    } catch (error) {
      console.error("Error fetching posts:", error);
    } finally {
      setIsLoading(false);
    }
  }

  async function updateStatus(postId: string, status: string, note: string) {
    setProcessingId(postId);
    try {
      const { error } = await supabase
        .from('posts')
        .update({ status, isReported: false, moderatorNote: note })
        .eq('id', postId);

      if (error) throw error;
      
      setPosts(posts.map(p => p.id === postId ? { ...p, status, isReported: false } : p));
      if (selectedPost?.id === postId) setSelectedPost({ ...selectedPost, status, isReported: false });
    } catch (error) {
      alert("Status Update Failed: " + (error as any).message);
    } finally {
      setProcessingId(null);
    }
  }

  async function deletePost(postId: string) {
    if (!confirm("CRITICAL ACTION: Permanently delete this post from the archive?")) return;
    
    setProcessingId(postId);
    try {
      const { error } = await supabase.from('posts').delete().eq('id', postId);
      if (error) throw error;
      setPosts(posts.filter(p => p.id !== postId));
      setSelectedPost(null);
    } catch (error) {
      alert("Deletion Failed: " + (error as any).message);
    } finally {
      setProcessingId(null);
    }
  }

  const filteredPosts = posts.filter(p => 
    p.title.toLowerCase().includes(searchQuery.toLowerCase()) || 
    p.id.includes(searchQuery)
  );

  if (selectedPost) {
    return (
      <div className="space-y-10 pb-20">
        <button 
          onClick={() => setSelectedPost(null)}
          className="flex items-center gap-2 text-neutral-500 hover:text-white transition-colors group"
        >
          <ArrowLeft className="w-4 h-4 group-hover:-translate-x-1 transition-transform" />
          <span className="text-[10px] font-mono uppercase tracking-[0.3em]">Back to Archive</span>
        </button>

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-12">
          <div className="space-y-8">
             <div className="bg-[#12121F] border border-white/5 rounded-[40px] p-2 aspect-square relative overflow-hidden group">
                {selectedPost.imageUrl ? (
                  <img src={selectedPost.imageUrl} alt={selectedPost.title} className="w-full h-full object-cover rounded-[32px]" />
                ) : (
                  <div className="w-full h-full bg-white/5 rounded-[32px] flex items-center justify-center">
                    <MessageSquare className="w-20 h-20 text-neutral-800" />
                  </div>
                )}
                <div className="absolute top-8 right-8">
                   <div className={`px-4 py-2 rounded-full text-[10px] font-bold uppercase tracking-widest ${selectedPost.type === 'lost' ? 'bg-red-500 text-white' : 'bg-emerald-500 text-black'}`}>
                      {selectedPost.type}
                   </div>
                </div>
             </div>
          </div>

          <div className="space-y-10">
             <div>
                <h1 className="text-4xl font-black tracking-tighter uppercase italic text-white mb-4">{selectedPost.title}</h1>
                <div className="flex items-center gap-4 text-[10px] font-mono text-neutral-500 uppercase tracking-widest">
                   <span className="flex items-center gap-2"><UserIcon className="w-4 h-4" /> {selectedPost.userId}</span>
                   <span className="w-1 h-1 rounded-full bg-neutral-800"></span>
                   <span className="flex items-center gap-2"><Calendar className="w-4 h-4" /> {new Date(selectedPost.timestamp).toLocaleString()}</span>
                </div>
             </div>

             <div className="p-8 bg-[#12121F] border border-white/5 rounded-3xl">
                <h4 className="text-[10px] font-mono text-neutral-600 uppercase tracking-widest mb-4">Tactical Description</h4>
                <p className="text-sm text-neutral-400 leading-relaxed font-mono uppercase tracking-wider italic">
                   "{selectedPost.description || "No description provided."}"
                </p>
             </div>

             <div className="grid grid-cols-2 gap-4">
                <button 
                  onClick={() => updateStatus(selectedPost.id, 'open', 'Verified by Command')}
                  className="py-4 bg-emerald-500 text-black rounded-2xl text-[10px] font-black uppercase tracking-widest hover:scale-105 transition-all"
                >
                  Approve Entry
                </button>
                <button 
                  onClick={() => updateStatus(selectedPost.id, 'rejected', 'Violation of Protocol')}
                  className="py-4 bg-red-500 text-white rounded-2xl text-[10px] font-black uppercase tracking-widest hover:scale-105 transition-all"
                >
                  Reject Node
                </button>
                <button 
                  onClick={() => deletePost(selectedPost.id)}
                  className="col-span-2 py-4 bg-white/5 border border-red-500/20 text-red-500 rounded-2xl text-[10px] font-black uppercase tracking-widest hover:bg-red-500/10 transition-all flex items-center justify-center gap-2"
                >
                  <Trash2 className="w-4 h-4" />
                  Purge from Ledger
                </button>
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
          <h1 className="text-3xl font-black tracking-tighter uppercase font-mono italic">Post Registry</h1>
          <p className="text-[10px] font-mono text-neutral-500 uppercase tracking-[0.3em] mt-2">Manage all active and archived nodes on the network</p>
        </div>
        
        <div className="flex flex-col sm:flex-row items-center gap-4">
          <div className="relative group w-full sm:w-64">
            <Search className="absolute left-4 top-1/2 -translate-y-1/2 w-4 h-4 text-neutral-600 group-focus-within:text-cyan-500 transition-colors" />
            <input 
              type="text" 
              placeholder="Search ID/Title..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-full bg-[#12121F] border border-white/5 rounded-2xl pl-12 pr-4 py-3 text-[10px] font-mono uppercase tracking-widest focus:outline-none focus:border-cyan-500/30 transition-all"
            />
          </div>
          <div className="flex bg-white/5 p-1 rounded-2xl border border-white/5">
            <button onClick={() => setFilter("all")} className={`px-6 py-2 text-[9px] font-mono uppercase tracking-widest rounded-xl transition-all ${filter === "all" ? "bg-white/10 text-white" : "text-neutral-500"}`}>Archive</button>
            <button onClick={() => setFilter("reported")} className={`px-6 py-2 text-[9px] font-mono uppercase tracking-widest rounded-xl transition-all ${filter === "reported" ? "bg-red-500/20 text-red-500" : "text-neutral-500"}`}>Anomalies</button>
          </div>
        </div>
      </div>

      <div className="grid grid-cols-1 gap-4">
        <AnimatePresence mode="popLayout">
          {filteredPosts.map(post => (
            <motion.div 
              key={post.id}
              layout
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, scale: 0.95 }}
              className={`bg-[#12121F] border p-6 rounded-[32px] group transition-all hover:bg-white/[0.02] flex items-center justify-between gap-8 ${post.isReported ? 'border-red-500/20 shadow-[0_0_20px_rgba(239,68,68,0.05)]' : 'border-white/5 hover:border-white/20'}`}
            >
              <div className="flex items-center gap-6 flex-1 min-w-0">
                <div className={`w-14 h-14 rounded-2xl border flex items-center justify-center shrink-0 transition-all ${post.type === 'lost' ? 'bg-red-500/5 border-red-500/10 text-red-500' : 'bg-emerald-500/5 border-emerald-500/10 text-emerald-500'}`}>
                  {post.imageUrl ? (
                    <img src={post.imageUrl} className="w-full h-full object-cover rounded-xl" />
                  ) : (
                    <MessageSquare className="w-6 h-6 opacity-30" />
                  )}
                </div>
                <div className="min-w-0">
                  <div className="flex items-center gap-3 mb-1">
                     <h3 className="text-sm font-bold uppercase tracking-tight truncate text-white/90">{post.title}</h3>
                     <span className={`text-[8px] font-mono px-2 py-0.5 rounded-full uppercase tracking-widest ${post.status === 'open' ? 'bg-emerald-500/10 text-emerald-500' : 'bg-red-500/10 text-red-500'}`}>{post.status}</span>
                  </div>
                  <div className="text-[9px] font-mono text-neutral-600 uppercase tracking-widest flex items-center gap-4">
                     <span className="truncate max-w-[100px]">ID: {post.id}</span>
                     <span>User: {post.userId.substring(0, 8)}</span>
                     <span>{new Date(post.timestamp).toLocaleDateString()}</span>
                  </div>
                </div>
              </div>

              <div className="flex items-center gap-2">
                 <button 
                  onClick={() => setSelectedPost(post)}
                  className="p-4 bg-white/5 text-neutral-400 rounded-2xl hover:text-white hover:bg-white/10 transition-all"
                 >
                    <Eye className="w-4 h-4" />
                 </button>
                 <button 
                  onClick={() => deletePost(post.id)}
                  className="p-4 bg-red-500/5 text-red-500 rounded-2xl hover:bg-red-500 hover:text-white transition-all"
                 >
                    <Trash2 className="w-4 h-4" />
                 </button>
              </div>
            </motion.div>
          ))}
        </AnimatePresence>
      </div>
    </div>
  );
}
