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

  // Allow popups for Firebase Auth
  async headers() {
    return [
      {
        source: '/(.*)',
        headers: [
          {
            key: 'Cross-Origin-Opener-Policy',
            value: 'same-origin-allow-popups',
          },
        ],
      },
    ];
  },
};

export default nextConfig;