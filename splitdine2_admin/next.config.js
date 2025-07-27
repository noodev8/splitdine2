/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  
  // Configuration for deployment to /admin path
  // basePath: '/admin',  // TEMPORARILY DISABLED FOR LOCAL DEV
  
  // Enable standalone output for easier deployment
  // output: 'standalone',
  
  // Ensure trailing slashes work correctly
  // trailingSlash: true,
  
  // Production optimizations
  compress: true,
  
  // Image optimization settings for VPS deployment
  images: {
    unoptimized: true, // Disable Next.js image optimization for static hosting
  },
}

module.exports = nextConfig