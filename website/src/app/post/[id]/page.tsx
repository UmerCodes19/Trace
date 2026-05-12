import { supabase } from "@/lib/supabase";
import { Metadata, ResolvingMetadata } from "next";
import { MapPin, Calendar, ShieldAlert, Camera, Link2, User, Video } from "lucide-react";

export const revalidate = 3600; // Retain caching for performance

interface Props {
  params: Promise<{ id: string }>;
}

async function getPost(id: string) {
  const { data, error } = await supabase.from('posts').select('*').eq('id', id).single();
  if (error || !data) return null;
  return data;
}

export async function generateMetadata({ params }: Props, parent: ResolvingMetadata): Promise<Metadata> {
  const { id } = await params;
  const post = await getPost(id);
  if (!post) return { title: "Report Missing | Trace", description: "Resource unavailable." };

  const typeTag = post.type?.toUpperCase() === 'LOST' ? 'LOST' : 'FOUND';
  const desc = `[${typeTag}] ${post.title} - Reported on Trace App`;

  let metaImg = 'https://trace-self.vercel.app/og-default.png';
  if (post.imageUrl) {
      metaImg = typeof post.imageUrl === 'string' ? post.imageUrl.replace(/[\[\]\"]/g, '').split(',')[0] : (post.imageUrl[0] || metaImg);
  }

  return {
    title: `${typeTag}: ${post.title}`,
    description: desc,
    openGraph: {
      title: `${typeTag} | ${post.title}`,
      description: desc,
      images: [{ url: metaImg, width: 1200, height: 630 }],
      type: 'website',
    },
    twitter: { card: 'summary_large_image', title: post.title, images: [metaImg] },
  };
}

export default async function SharedPostPage({ params }: Props) {
  const { id } = await params;
  const post = await getPost(id);

  if (!post) {
    return (
      <div className="min-h-screen bg-[var(--background)] text-[var(--foreground)] flex flex-col items-center justify-center p-6 text-center">
        <ShieldAlert className="w-16 h-16 text-red-500/50 mb-6" />
        <h1 className="text-2xl font-black uppercase tracking-tight mb-2">Not Found</h1>
        <p className="text-sage-secondary text-xs font-bold tracking-wider mb-8">This post could not be found.</p>
        <a href="/" className="px-6 py-3 bg-jade-primary text-white font-bold text-xs uppercase tracking-widest rounded-xl shadow-md hover:bg-jade-deep transition-all">Back to Home</a>
      </div>
    );
  }

  const isLost = post.type?.toLowerCase() === 'lost';
  const location = post.buildingName || post.location_building || "Unknown Location";
  
  let videoUrl: string | null = null;
  let displayImage: string | null = null;
  let cleanDescription = post.description || "";

  // Parse Description for Video
  if (cleanDescription && cleanDescription.includes('[video:')) {
     const start = cleanDescription.indexOf('[video:');
     const end = cleanDescription.indexOf(']', start);
     if (end !== -1) {
        videoUrl = cleanDescription.substring(start + 7, end).trim();
        cleanDescription = cleanDescription.substring(0, start).trim();
     }
  }

  // Check explicit imageUrl column
  if (post.imageUrl) {
      const rawUrl = typeof post.imageUrl === 'string' ? post.imageUrl.replace(/[\[\]\"]/g, '').split(',')[0] : post.imageUrl[0];
      if (rawUrl) {
         if (rawUrl.toLowerCase().includes('.mp4') || rawUrl.toLowerCase().includes('quicktime')) {
            if (!videoUrl) videoUrl = rawUrl;
         } else {
            displayImage = rawUrl;
         }
      }
  }

  return (
    <div className="min-h-screen bg-[var(--background)] text-[var(--foreground)] px-4 flex justify-center items-start pt-32 pb-16 font-sans transition-colors">
      
      {/* Soft dynamic glow background */}
      <div className="fixed inset-0 overflow-hidden pointer-events-none opacity-30">
        <div className="absolute top-[15%] left-1/2 -translate-x-1/2 w-[70vw] h-[40vh] bg-jade-primary/10 blur-[120px] rounded-full" />
      </div>

      <main className="relative z-10 w-full max-w-lg">
        
        {/* Simple Breadcrumb */}
        <div className="flex justify-between items-center mb-6 px-2">
          <a href="/" className="flex items-center gap-2 text-jade-primary hover:opacity-70 transition-all font-bold text-xs tracking-wide">
            <Link2 className="w-4 h-4" /> Trace
          </a>
          <span className={`text-[10px] font-bold uppercase tracking-wider px-3 py-1.5 border rounded-full ${
            isLost ? 'text-red-500 bg-red-500/10 border-red-500/20' : 'text-jade-primary bg-jade-primary/10 border-jade-primary/20'
          }`}>
            {isLost ? 'Lost Item' : 'Found Item'}
          </span>
        </div>

        {/* Clean Presentation Card */}
        <div className="bg-[var(--card-bg)] border border-[var(--border-color)] rounded-3xl overflow-hidden shadow-xl shadow-black/5">
          
          {/* User Strip */}
          <div className="p-5 border-b border-[var(--border-color)] flex items-center justify-between bg-[var(--background)]/50">
            <div className="flex items-center gap-3">
               <div className="w-10 h-10 rounded-full bg-[var(--background)] flex items-center justify-center overflow-hidden border border-[var(--border-color)]">
                  {post.posterAvatarUrl ? <img src={post.posterAvatarUrl} className="w-full h-full object-cover" /> : <User className="w-5 h-5 text-sage-secondary" />}
               </div>
               <div>
                  <span className="block text-sm font-bold text-[var(--foreground)]">{post.posterName || "Anonymous User"}</span>
                  <span className="block text-[10px] font-bold text-sage-secondary uppercase tracking-wider">Verified User</span>
               </div>
            </div>
            <div className="px-3 py-1.5 bg-[var(--background)] border border-[var(--border-color)] flex items-center gap-2 text-[10px] font-bold text-jade-primary rounded-full shadow-sm">
              <div className={`w-2 h-2 rounded-full ${post.status === 'open' ? 'bg-jade-primary animate-pulse' : 'bg-slate-400'}`} />
              {post.status === 'open' ? 'Active' : 'Resolved'}
            </div>
          </div>

          {/* Media Box - supports image AND video */}
          <div className="w-full aspect-video bg-black relative flex items-center justify-center overflow-hidden">
            {videoUrl ? (
              <video controls src={videoUrl} className="w-full h-full object-contain" />
            ) : displayImage ? (
              <img src={displayImage} alt={post.title} className="w-full h-full object-cover" />
            ) : (
              <div className="w-full h-full flex flex-col items-center justify-center gap-3 opacity-40 bg-[var(--card-bg)]">
                <Camera className="w-8 h-8 text-sage-secondary" />
                <span className="text-xs font-bold text-sage-secondary tracking-wide">No Media Found</span>
              </div>
            )}
          </div>

          {/* Details Container */}
          <div className="p-8 space-y-6">
            
            <div>
               <h1 className="text-2xl font-black tracking-tight text-[var(--foreground)] mb-4 leading-tight">
                 {post.title || "Untitled Post"}
               </h1>
               <p className="text-sm text-sage-secondary font-medium leading-relaxed whitespace-pre-wrap">
                 {cleanDescription || "No description provided."}
               </p>
            </div>

            {/* Info Grid */}
            <div className="grid grid-cols-2 gap-4">
               <div className="bg-[var(--background)] border border-[var(--border-color)] p-4 rounded-2xl flex flex-col shadow-sm">
                  <MapPin className="w-4 h-4 text-jade-primary mb-2" />
                  <span className="text-[10px] font-bold text-sage-secondary uppercase tracking-widest mb-1">Location</span>
                  <span className="text-xs font-bold text-[var(--foreground)] truncate">{location}</span>
               </div>
               <div className="bg-[var(--background)] border border-[var(--border-color)] p-4 rounded-2xl flex flex-col shadow-sm">
                  <Calendar className="w-4 h-4 text-jade-primary mb-2" />
                  <span className="text-[10px] font-bold text-sage-secondary uppercase tracking-widest mb-1">Date Posted</span>
                  <span className="text-xs font-bold text-[var(--foreground)]">
                    {new Date(post.timestamp).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })}
                  </span>
               </div>
            </div>

            <a 
              href="https://trace-self.vercel.app"
              className="block w-full py-4 bg-jade-primary text-white text-center font-bold uppercase tracking-widest text-xs hover:bg-jade-deep transition-all shadow-lg shadow-jade-primary/10 rounded-xl active:scale-95"
            >
              Open App
            </a>

          </div>
        </div>

        <div className="mt-10 text-center opacity-40">
           <span className="text-xs font-bold text-sage-secondary uppercase tracking-widest">Trace App</span>
        </div>

      </main>
    </div>
  );
}




