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
  ArrowLeft,
  Shield
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
          className="flex items-center gap-3 text-jade-primary/60 hover:text-jade-primary transition-colors group px-6 py-3 bg-jade-primary/5 rounded-2xl font-bold text-xs uppercase tracking-widest"
        >
          <ArrowLeft className="w-4 h-4 group-hover:-translate-x-1 transition-transform" />
          <span>Back to Feed</span>
        </button>

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-12">
          <div className="space-y-8">
             <div className="bg-[var(--card-bg)] border border-[var(--border-color)] rounded-[40px] p-2 aspect-square relative overflow-hidden group shadow-2xl">
                {selectedPost.imageUrl ? (
                  <img src={selectedPost.imageUrl} alt={selectedPost.title} className="w-full h-full object-cover rounded-[32px]" />
                ) : (
                  <div className="w-full h-full bg-jade-primary/5 rounded-[32px] flex items-center justify-center">
                    <MessageSquare className="w-20 h-20 text-jade-primary/20" />
                  </div>
                )}
                <div className="absolute top-8 right-8">
                   <div className={`px-5 py-2 rounded-full text-[10px] font-black uppercase tracking-widest shadow-lg ${selectedPost.type === 'lost' ? 'bg-red-500 text-white' : 'bg-jade-primary text-white'}`}>
                      {selectedPost.type}
                   </div>
                </div>
             </div>
          </div>

          <div className="space-y-10">
             <div>
                <h1 className="text-4xl font-black tracking-tighter uppercase text-[var(--foreground)] mb-4">{selectedPost.title}</h1>
                <div className="flex flex-wrap items-center gap-6 text-[10px] font-bold text-sage-secondary uppercase tracking-widest">
                   <span className="flex items-center gap-2 px-3 py-1 bg-jade-primary/5 rounded-lg border border-jade-primary/10"><UserIcon className="w-4 h-4" /> {selectedPost.userId.substring(0, 12)}...</span>
                   <span className="flex items-center gap-2 px-3 py-1 bg-jade-primary/5 rounded-lg border border-jade-primary/10"><Calendar className="w-4 h-4" /> {new Date(selectedPost.timestamp).toLocaleDateString()}</span>
                </div>
             </div>

             <div className="p-8 bg-jade-primary/5 border border-jade-primary/10 rounded-[32px]">
                <h4 className="text-[10px] font-black text-jade-primary/40 uppercase tracking-[0.2em] mb-4">Post Description</h4>
                <p className="text-sm text-[var(--foreground)] leading-relaxed font-medium italic">
                   "{selectedPost.description || "No description provided."}"
                </p>
             </div>

             <div className="grid grid-cols-2 gap-4">
                <button 
                  onClick={() => updateStatus(selectedPost.id, 'open', 'Verified by Admin')}
                  className="py-5 bg-jade-primary text-white rounded-2xl text-[10px] font-black uppercase tracking-widest hover:bg-jade-deep transition-all shadow-lg shadow-jade-primary/20"
                >
                  Approve Post
                </button>
                <button 
                  onClick={() => updateStatus(selectedPost.id, 'rejected', 'Violation of Terms')}
                  className="py-5 bg-red-500 text-white rounded-2xl text-[10px] font-black uppercase tracking-widest hover:bg-red-600 transition-all shadow-lg shadow-red-500/20"
                >
                  Reject Post
                </button>
                <button 
                  onClick={() => deletePost(selectedPost.id)}
                  className="col-span-2 py-5 bg-[var(--background)] border border-red-500/20 text-red-500 rounded-2xl text-[10px] font-black uppercase tracking-widest hover:bg-red-500/5 transition-all flex items-center justify-center gap-3"
                >
                  <Trash2 className="w-4 h-4" />
                  Permanently Delete
                </button>
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
          <h1 className="text-4xl font-black tracking-tighter uppercase text-[var(--foreground)]">Posts <span className="text-jade-primary">Feed</span></h1>
          <p className="text-sm text-jade-primary/60 font-bold uppercase tracking-widest mt-2">Moderation & Quality Control</p>
        </div>
        
        <div className="flex flex-col sm:flex-row items-center gap-4">
          <div className="relative group w-full sm:w-72">
            <Search className="absolute left-5 top-1/2 -translate-y-1/2 w-4 h-4 text-jade-primary/40 group-focus-within:text-jade-primary transition-colors" />
            <input 
              type="text" 
              placeholder="Search ID or Title..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-full bg-[var(--card-bg)] border border-[var(--border-color)] rounded-2xl pl-14 pr-6 py-4 text-xs font-bold uppercase tracking-widest focus:outline-none focus:border-jade-primary/30 transition-all text-[var(--foreground)]"
            />
          </div>
          <div className="flex bg-jade-primary/5 p-1.5 rounded-2xl border border-jade-primary/10">
            <button onClick={() => setFilter("all")} className={`px-8 py-2.5 text-[10px] font-black uppercase tracking-widest rounded-xl transition-all ${filter === "all" ? "bg-jade-primary text-white shadow-md" : "text-jade-primary/40 hover:text-jade-primary"}`}>All Posts</button>
            <button onClick={() => setFilter("reported")} className={`px-8 py-2.5 text-[10px] font-black uppercase tracking-widest rounded-xl transition-all ${filter === "reported" ? "bg-red-500 text-white shadow-md" : "text-jade-primary/40 hover:text-red-500"}`}>Reported</button>
          </div>
        </div>
      </div>

      <div className="grid grid-cols-1 gap-6">
        <AnimatePresence mode="popLayout">
          {filteredPosts.map(post => (
            <motion.div 
              key={post.id}
              layout
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, scale: 0.95 }}
              className={`bg-[var(--card-bg)] border p-5 md:p-8 rounded-[40px] group transition-all hover:border-jade-primary/30 flex flex-col md:flex-row md:items-center justify-between gap-6 shadow-xl shadow-black/5 ${post.isReported ? 'border-red-500/30' : 'border-[var(--border-color)]'}`}
            >
              <div className="flex items-center gap-6 flex-1 min-w-0">
                <div className={`w-16 h-16 rounded-2xl border flex items-center justify-center shrink-0 transition-all overflow-hidden ${post.type === 'lost' ? 'bg-red-500/5 border-red-500/10' : 'bg-jade-primary/5 border-jade-primary/10'}`}>
                  {post.imageUrl ? (
                    <img src={post.imageUrl} className="w-full h-full object-cover group-hover:scale-110 transition-transform duration-500" />
                  ) : (
                    <MessageSquare className={`w-7 h-7 ${post.type === 'lost' ? 'text-red-500' : 'text-jade-primary'} opacity-20`} />
                  )}
                </div>
                <div className="min-w-0">
                  <div className="flex items-center gap-3 mb-2">
                     <h3 className="text-lg font-black tracking-tight truncate text-[var(--foreground)] uppercase">{post.title}</h3>
                     <span className={`text-[8px] font-black px-3 py-1 rounded-full uppercase tracking-widest ${post.status === 'open' ? 'bg-jade-primary text-white' : 'bg-red-500 text-white'} shadow-sm`}>{post.status}</span>
                  </div>
                  <div className="text-[9px] font-bold text-sage-secondary uppercase tracking-[0.1em] flex flex-wrap items-center gap-x-6 gap-y-2">
                     <span className="flex items-center gap-1.5"><Shield className="w-3 h-3" /> {post.id.substring(0, 8)}</span>
                     <span className="flex items-center gap-1.5"><UserIcon className="w-3 h-3" /> {post.userId.substring(0, 8)}</span>
                     <span className="flex items-center gap-1.5"><Calendar className="w-3 h-3" /> {new Date(post.timestamp).toLocaleDateString()}</span>
                  </div>
                </div>
              </div>

              <div className="flex items-center gap-3 ml-auto md:ml-0">
                 <button 
                  onClick={() => setSelectedPost(post)}
                  className="p-4 bg-jade-primary/5 text-jade-primary rounded-2xl hover:bg-jade-primary hover:text-white transition-all shadow-sm"
                 >
                    <Eye className="w-5 h-5" />
                 </button>
                 <button 
                  onClick={() => deletePost(post.id)}
                  className="p-4 bg-red-500/5 text-red-500 rounded-2xl hover:bg-red-500 hover:text-white transition-all shadow-sm"
                 >
                    <Trash2 className="w-5 h-5" />
                 </button>
              </div>
            </motion.div>
          ))}
        </AnimatePresence>
      </div>
    </div>
  );
}
