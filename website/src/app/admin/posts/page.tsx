"use client";

import { useEffect, useState } from "react";
import { supabase } from "@/lib/supabase";
import { motion, AnimatePresence } from "framer-motion";
import { 
  Search,
  MessageSquare,
  Loader2,
  Calendar,
  User as UserIcon,
  Trash2,
  Eye,
  ArrowLeft,
  PlayCircle,
  Video
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

  function extractMedia(post: Post) {
    let videoUrl: string | null = null;
    let imageUrl: string | null = null;

    // 1. Check description parsing
    if (post.description && post.description.includes('[video:')) {
       const start = post.description.indexOf('[video:');
       const end = post.description.indexOf(']', start);
       if (end !== -1) {
          videoUrl = post.description.substring(start + 7, end).trim();
       }
    }

    // 2. Check standard imageUrl column for video extensions
    if (post.imageUrl) {
       // Standard cleanup
       let raw = typeof post.imageUrl === 'string' ? post.imageUrl.replace(/[\[\]\"]/g, '').split(',')[0] : (post.imageUrl as any)[0];
       if (raw) {
          if (raw.toLowerCase().includes('.mp4') || raw.toLowerCase().includes('quicktime') || raw.toLowerCase().includes('video')) {
             videoUrl = raw;
          } else {
             imageUrl = raw;
          }
       }
    }

    // Re-check description again just in case fallback
    const cleanDesc = post.description ? post.description.split('[video:')[0].trim() : '';

    return { videoUrl, imageUrl, cleanDesc };
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
      alert("Action Error: " + (error as any).message);
    } finally {
      setProcessingId(null);
    }
  }

  async function deletePost(postId: string) {
    if (!confirm("Are you sure you want to delete this post permanently?")) return;
    
    setProcessingId(postId);
    try {
      const { error } = await supabase.from('posts').delete().eq('id', postId);
      if (error) throw error;
      setPosts(posts.filter(p => p.id !== postId));
      setSelectedPost(null);
    } catch (error) {
      alert("Delete Error: " + (error as any).message);
    } finally {
      setProcessingId(null);
    }
  }

  const filteredPosts = posts.filter(p => 
    p.title.toLowerCase().includes(searchQuery.toLowerCase()) || 
    p.id.includes(searchQuery)
  );

  if (selectedPost) {
    const media = extractMedia(selectedPost);
    
    return (
      <div className="space-y-10 pb-20 font-sans">
        <button 
          onClick={() => setSelectedPost(null)}
          className="flex items-center gap-2 text-sage-secondary hover:text-jade-primary transition-colors text-sm font-bold"
        >
          <ArrowLeft className="w-4 h-4" />
          Back to list
        </button>

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
          <div className="space-y-8">
             <div className="bg-[var(--card-bg)] border border-[var(--border-color)] rounded-2xl p-2 aspect-square relative overflow-hidden shadow-md flex items-center justify-center">
                
                {media.videoUrl ? (
                  <video 
                    controls 
                    src={media.videoUrl} 
                    className="w-full h-full object-contain rounded-xl bg-black"
                  />
                ) : media.imageUrl ? (
                  <img src={media.imageUrl} alt={selectedPost.title} className="w-full h-full object-contain rounded-xl" />
                ) : (
                  <div className="w-full h-full flex items-center justify-center bg-[var(--background)] rounded-xl">
                    <MessageSquare className="w-16 h-16 text-sage-secondary opacity-20" />
                  </div>
                )}

                <div className="absolute top-6 right-6">
                   <div className={`px-3 py-1 rounded-full font-bold text-[10px] uppercase tracking-wider shadow-md ${selectedPost.type === 'lost' ? 'bg-red-500 text-white' : 'bg-jade-primary text-white'}`}>
                      {selectedPost.type}
                   </div>
                </div>
             </div>
          </div>

          <div className="flex flex-col justify-center space-y-8">
             <div>
                <div className="text-[10px] font-bold text-jade-primary uppercase tracking-widest mb-1">View Post</div>
                <h1 className="text-3xl font-black tracking-tight text-[var(--foreground)] mb-4 leading-tight">{selectedPost.title}</h1>
                 <div className="flex flex-wrap items-center gap-4 text-xs font-medium text-neutral-500">
                    <span className="flex items-center gap-2 px-3 py-1.5 bg-[var(--card-bg)] border border-[var(--border-color)] rounded-lg font-mono text-[11px] select-all"><UserIcon className="w-3.5 h-3.5 text-jade-primary" /> UID: {selectedPost.userId}</span>
                    <span className="flex items-center gap-2 px-3 py-1.5 bg-[var(--card-bg)] border border-[var(--border-color)] rounded-lg"><Calendar className="w-3.5 h-3.5" /> {new Date(selectedPost.timestamp).toLocaleDateString()}</span>
                 </div>
             </div>

             <div className="p-6 bg-[var(--card-bg)] border border-[var(--border-color)] rounded-2xl">
                <h4 className="text-xs font-bold text-neutral-500 mb-3 uppercase tracking-wider">Description</h4>
                <p className="text-sm text-[var(--foreground)] leading-relaxed font-medium">
                   {media.cleanDesc || "No details provided."}
                </p>
             </div>

             <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                <button 
                  onClick={() => updateStatus(selectedPost.id, 'open', 'Verified')}
                  className="py-4 bg-jade-primary text-white rounded-xl font-bold text-sm hover:bg-jade-deep transition-all shadow-md shadow-jade-primary/10"
                >
                  Approve Post
                </button>
                <button 
                  onClick={() => updateStatus(selectedPost.id, 'rejected', 'Rejected')}
                  className="py-4 border border-red-500/30 text-red-500 rounded-xl font-bold text-sm hover:bg-red-500 hover:text-white transition-all"
                >
                  Reject Post
                </button>
                <button 
                  onClick={() => deletePost(selectedPost.id)}
                  className="sm:col-span-2 py-4 bg-[var(--background)] border border-[var(--border-color)] text-red-500 hover:bg-red-500/5 rounded-xl font-bold text-sm transition-all flex items-center justify-center gap-2 mt-2"
                >
                  <Trash2 className="w-4 h-4" />
                  Delete Permanently
                </button>
             </div>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-10 pb-20 font-sans">
      <div className="flex flex-col lg:flex-row lg:items-end justify-between gap-8 border-b border-[var(--border-color)] pb-8">
        <div>
          <h1 className="text-4xl font-black tracking-tight text-[var(--foreground)]">Post <span className="text-jade-primary">Manager</span></h1>
          <p className="text-sm font-medium text-neutral-500 mt-1">Review user reported items</p>
        </div>
        
        <div className="flex flex-col sm:flex-row items-center gap-3">
          <div className="relative group w-full sm:w-64">
            <Search className="absolute left-4 top-1/2 -translate-y-1/2 w-4 h-4 text-neutral-400 group-focus-within:text-jade-primary transition-colors" />
            <input 
              type="text" 
              placeholder="Search title or ID..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-full bg-[var(--card-bg)] border border-[var(--border-color)] rounded-xl pl-11 pr-4 py-3 text-sm focus:outline-none focus:border-jade-primary transition-all text-[var(--foreground)]"
            />
          </div>
          <div className="flex border border-[var(--border-color)] bg-[var(--card-bg)] rounded-xl p-1">
            <button onClick={() => setFilter("all")} className={`px-5 py-2 text-xs font-bold rounded-lg transition-all ${filter === "all" ? "bg-jade-primary text-white shadow-sm" : "text-neutral-500 hover:text-[var(--foreground)]"}`}>All</button>
            <button onClick={() => setFilter("reported")} className={`px-5 py-2 text-xs font-bold rounded-lg transition-all ${filter === "reported" ? "bg-red-500 text-white shadow-sm" : "text-neutral-500 hover:text-red-500"}`}>Reported</button>
          </div>
        </div>
      </div>

      {isLoading ? (
         <div className="py-20 flex flex-col items-center gap-3">
            <Loader2 className="w-6 h-6 text-jade-primary animate-spin" />
            <span className="text-xs text-neutral-500">Loading posts...</span>
         </div>
      ) : (
        <div className="grid grid-cols-1 gap-3">
          <AnimatePresence mode="popLayout">
            {filteredPosts.length === 0 ? (
               <div className="py-16 text-center border border-[var(--border-color)] bg-[var(--card-bg)] rounded-2xl">
                  <span className="text-sm font-medium text-neutral-500">No posts found.</span>
               </div>
            ) : (
              filteredPosts.map(post => {
                const media = extractMedia(post);
                const hasVideo = !!media.videoUrl;

                return (
                  <motion.div 
                    key={post.id}
                    layout
                    initial={{ opacity: 0, y: 5 }}
                    animate={{ opacity: 1, y: 0 }}
                    exit={{ opacity: 0, scale: 0.98 }}
                    className={`bg-[var(--card-bg)] border ${post.isReported ? 'border-red-500/30 bg-red-500/[0.02]' : 'border-[var(--border-color)]'} p-4 rounded-2xl shadow-sm transition-all hover:border-jade-primary flex flex-col sm:flex-row items-center justify-between gap-6`}
                  >
                    <div className="flex items-center gap-5 flex-1 min-w-0 w-full">
                      <div className={`w-14 h-14 rounded-xl border flex items-center justify-center shrink-0 overflow-hidden bg-[var(--background)] ${post.type === 'lost' ? 'border-red-500/20' : 'border-jade-primary/20'} relative`}>
                        {hasVideo ? (
                          <>
                             <Video className="w-5 h-5 text-jade-primary" />
                             <div className="absolute top-1 right-1 w-1.5 h-1.5 bg-red-500 rounded-full shadow-sm" />
                          </>
                        ) : media.imageUrl ? (
                          <img src={media.imageUrl} className="w-full h-full object-cover" />
                        ) : (
                          <MessageSquare className={`w-5 h-5 opacity-30`} />
                        )}
                      </div>
                      <div className="min-w-0 flex-1">
                        <div className="flex items-center gap-3 mb-1">
                           <h3 className="text-md font-bold tracking-tight truncate text-[var(--foreground)]">{post.title}</h3>
                           <span className={`text-[9px] font-bold px-2 py-0.5 rounded-full uppercase border ${post.status === 'open' || post.status === 'approved' ? 'text-emerald-600 border-emerald-200 bg-emerald-50' : 'text-amber-600 border-amber-200 bg-amber-50'}`}>{post.status}</span>
                        </div>
                        <div className="text-xs font-medium text-neutral-500 flex flex-wrap items-center gap-x-5 gap-y-1">
                           <span className="flex items-center gap-1 font-mono text-[11px]"><UserIcon className="w-3.5 h-3.5 text-jade-primary" /> UID: {post.userId.substring(0, 12)}...</span>
                           <span className="flex items-center gap-1"><Calendar className="w-3.5 h-3.5 text-jade-primary" /> {new Date(post.timestamp).toLocaleDateString()}</span>
                           {hasVideo && <span className="text-jade-primary flex items-center gap-1"><PlayCircle className="w-3 h-3" /> Has Video</span>}
                        </div>
                      </div>
                    </div>

                    <div className="flex items-center gap-2 w-full sm:w-auto shrink-0">
                       <button 
                        onClick={() => setSelectedPost(post)}
                        className="flex-1 sm:flex-none px-5 py-2 bg-[var(--background)] border border-[var(--border-color)] text-[var(--foreground)] hover:border-jade-primary transition-all rounded-xl flex items-center justify-center gap-2 text-xs font-bold"
                       >
                          <Eye className="w-4 h-4" /> View Detail
                       </button>
                       <button 
                        onClick={() => deletePost(post.id)}
                        className="px-3 py-2 text-neutral-400 hover:text-red-500 transition-all rounded-xl"
                       >
                          <Trash2 className="w-4 h-4" />
                       </button>
                    </div>
                  </motion.div>
                );
              })
            )}
          </AnimatePresence>
        </div>
      )}
    </div>
  );
}


