import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // Important: This ensures proper static file serving
  distDir: '.next',

  // For images if you use any
  images: {
    unoptimized: true, // Temporarily disable image optimization
  },

  // Output configuration
  output: 'standalone', // Better for Vercel deployment
};

export default nextConfig;