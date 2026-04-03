import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import { VitePWA } from 'vite-plugin-pwa';

export default defineConfig({
  plugins: [
    react(),
    VitePWA({
      registerType: 'autoUpdate',
      includeAssets: ['assets/logo.jpg'],
      manifest: {
        name: 'ITCM Emprende: Tu Mercado Académico en un Click',
        short_name: 'ITCM Emprende',
        description: 'Marketplace exclusivo del Instituto Tecnológico de Ciudad Madero.',
        theme_color: '#E5B300',
        background_color: '#FAFBFC',
        display: 'standalone',
        orientation: 'portrait',
        lang: 'es-MX',
        start_url: '/',
        icons: [
          { src: '/assets/logo.jpg', sizes: '192x192', type: 'image/jpeg', purpose: 'any' },
          { src: '/assets/logo.jpg', sizes: '512x512', type: 'image/jpeg', purpose: 'any maskable' },
        ],
      },
      workbox: {
        globPatterns: ['**/*.{js,css,html,ico,png,jpg,svg,woff2}'],
        runtimeCaching: [
          {
            urlPattern: /^https:\/\/.*\.supabase\.co\/.*/i,
            handler: 'NetworkFirst',
            options: {
              cacheName: 'supabase-api',
              expiration: { maxEntries: 50, maxAgeSeconds: 300 },
            },
          },
        ],
      },
    }),
  ],
});
