"use client";

import { motion } from "framer-motion";
import { Download, Search, Shield, Zap, MapPin, MessageSquare } from "lucide-react";
import Link from "next/link";

export default function LandingPage() {
  return (
    <div className="min-h-screen bg-[#0A0F1E] text-white overflow-hidden">
      {/* Navbar */}
      <nav className="fixed top-0 w-full z-50 bg-[#0A0F1E]/80 backdrop-blur-md border-b border-white/10">
        <div className="max-w-7xl mx-auto px-6 h-20 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <div className="w-10 h-10 bg-blue-600 rounded-xl flex items-center justify-center shadow-lg shadow-blue-500/20">
              <Search className="w-6 h-6 text-white" />
            </div>
            <span className="text-xl font-bold tracking-tight">LOST&FOUND</span>
          </div>
          <div className="hidden md:flex items-center gap-8 text-sm font-medium text-gray-400">
            <Link href="#features" className="hover:text-white transition-colors">Features</Link>
            <Link href="#how-it-works" className="hover:text-white transition-colors">How it Works</Link>
            <Link href="/admin" className="hover:text-white transition-colors text-blue-500">Admin Portal</Link>
          </div>
          <button className="bg-blue-600 hover:bg-blue-700 text-white px-6 py-2.5 rounded-full text-sm font-semibold transition-all shadow-lg shadow-blue-500/20 active:scale-95">
            Download APK
          </button>
        </div>
      </nav>

      {/* Hero Section */}
      <section className="relative pt-40 pb-20 px-6">
        <div className="absolute top-0 left-1/2 -translate-x-1/2 w-[1000px] h-[600px] bg-blue-600/10 blur-[120px] rounded-full -z-10" />
        
        <div className="max-w-7xl mx-auto grid lg:grid-cols-2 gap-12 items-center">
          <motion.div 
            initial={{ opacity: 0, x: -30 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ duration: 0.8 }}
          >
            <div className="inline-flex items-center gap-2 bg-white/5 border border-white/10 px-4 py-2 rounded-full mb-6">
              <span className="w-2 h-2 bg-blue-500 rounded-full animate-pulse" />
              <span className="text-xs font-bold tracking-widest uppercase text-blue-400">Exclusive for Bahria University</span>
            </div>
            <h1 className="text-6xl lg:text-7xl font-extrabold leading-tight mb-8">
              Lost it? <br />
              <span className="text-transparent bg-clip-text bg-gradient-to-r from-blue-400 to-cyan-300">Found it.</span>
            </h1>
            <p className="text-lg text-gray-400 mb-10 max-w-lg leading-relaxed">
              The smartest way to recover your lost belongings on campus. Powered by AI location prediction and instant chat.
            </p>
            <div className="flex flex-wrap gap-4">
              <button className="bg-white text-black px-8 py-4 rounded-2xl font-bold flex items-center gap-3 hover:bg-gray-100 transition-all active:scale-95">
                <Download className="w-5 h-5" />
                Download for Android
              </button>
              <Link href="/admin" className="bg-white/5 border border-white/10 px-8 py-4 rounded-2xl font-bold hover:bg-white/10 transition-all active:scale-95">
                View Admin Dashboard
              </Link>
            </div>
          </motion.div>

          <motion.div 
            initial={{ opacity: 0, scale: 0.9, rotateY: -10 }}
            animate={{ opacity: 1, scale: 1, rotateY: 0 }}
            transition={{ duration: 1, delay: 0.2 }}
            className="relative"
          >
            <div className="relative z-10 bg-gradient-to-br from-blue-600 to-cyan-500 p-[1px] rounded-[3rem] shadow-2xl shadow-blue-500/20">
              <div className="bg-[#0A0F1E] rounded-[3rem] overflow-hidden aspect-[9/19] w-full max-w-[320px] mx-auto">
                {/* Mock Phone Content */}
                <div className="h-full w-full bg-[#121829] p-6">
                  <div className="w-12 h-1 bg-white/10 rounded-full mx-auto mb-8" />
                  <div className="space-y-4">
                    {[1,2,3].map(i => (
                      <div key={i} className="p-4 bg-white/5 rounded-2xl border border-white/10">
                        <div className="w-full aspect-video bg-white/10 rounded-xl mb-3 animate-pulse" />
                        <div className="h-4 bg-white/20 rounded w-2/3 mb-2" />
                        <div className="h-3 bg-white/10 rounded w-1/2" />
                      </div>
                    ))}
                  </div>
                </div>
              </div>
            </div>
            {/* Floating Elements */}
            <div className="absolute -top-10 -right-10 bg-white/5 backdrop-blur-xl border border-white/10 p-6 rounded-3xl shadow-2xl">
              <div className="flex items-center gap-4">
                <div className="w-12 h-12 bg-green-500/20 rounded-2xl flex items-center justify-center">
                  <Shield className="w-6 h-6 text-green-500" />
                </div>
                <div>
                  <div className="text-sm font-bold">Item Recovered!</div>
                  <div className="text-xs text-gray-400">Safe handover confirmed</div>
                </div>
              </div>
            </div>
          </motion.div>
        </div>
      </section>

      {/* Features */}
      <section id="features" className="py-24 px-6 bg-white/[0.02]">
        <div className="max-w-7xl mx-auto">
          <div className="text-center mb-20">
            <h2 className="text-4xl font-bold mb-4">Smarter Recovery</h2>
            <p className="text-gray-400">Everything you need to get your stuff back.</p>
          </div>
          
          <div className="grid md:grid-cols-3 gap-8">
            <FeatureCard 
              icon={<Zap className="w-6 h-6 text-yellow-500" />}
              title="AI Location Prediction"
              description="Our AI analyzes class schedules and campus flow to predict where you might have left your item."
            />
            <FeatureCard 
              icon={<MapPin className="w-6 h-6 text-blue-500" />}
              title="Indoor Campus Map"
              description="Detailed floor-by-floor maps of all Bahria University buildings to pinpoint exact locations."
            />
            <FeatureCard 
              icon={<MessageSquare className="w-6 h-6 text-purple-500" />}
              title="Secure Instant Chat"
              description="Coordinate handovers through our built-in encrypted chat system without sharing personal numbers."
            />
          </div>
        </div>
      </section>

      {/* Footer */}
      <footer className="py-12 border-t border-white/10 px-6">
        <div className="max-w-7xl mx-auto flex flex-col md:row items-center justify-between gap-8">
          <div className="flex items-center gap-2">
            <div className="w-8 h-8 bg-blue-600 rounded-lg flex items-center justify-center">
              <Search className="w-5 h-5 text-white" />
            </div>
            <span className="text-lg font-bold">LOST&FOUND</span>
          </div>
          <p className="text-sm text-gray-500">© 2026 Lost&Found Campus. For Educational Purposes Only.</p>
          <div className="flex gap-6 text-sm text-gray-400">
            <Link href="/admin" className="hover:text-white">Admin Portal</Link>
            <Link href="#" className="hover:text-white">Privacy Policy</Link>
          </div>
        </div>
      </footer>
    </div>
  );
}

function FeatureCard({ icon, title, description }: { icon: any, title: string, description: string }) {
  return (
    <div className="bg-white/5 border border-white/10 p-8 rounded-3xl hover:bg-white/[0.08] transition-all group">
      <div className="w-14 h-14 bg-white/5 rounded-2xl flex items-center justify-center mb-6 group-hover:scale-110 transition-transform">
        {icon}
      </div>
      <h3 className="text-xl font-bold mb-3">{title}</h3>
      <p className="text-gray-400 leading-relaxed text-sm">{description}</p>
    </div>
  );
}
