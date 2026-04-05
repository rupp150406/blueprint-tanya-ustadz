// nuxt.config.ts
export default defineNuxtConfig({
  devtools: { enabled: true },

  modules: [
    '@nuxtjs/supabase',
    '@nuxtjs/tailwindcss',
    '@pinia/nuxt',
  ],

  css: ['~/assets/css/main.css'],

  supabase: {
    redirect: false, // We handle redirects manually via middleware
  },

  security: {
    headers: {
      contentSecurityPolicy: {
        'img-src': ["'self'", 'data:', 'https://lh3.googleusercontent.com'],
      },
    },
    rateLimiter: {
      tokensPerInterval: 100,
      interval: 'hour',
    },
  },

  app: {
    head: {
      titleTemplate: '%s | Tanya Ustadz',
      title: 'Tanya Ustadz',
      link: [{ rel: 'icon', type: 'image/x-icon', href: '/favicon.ico' }],
      meta: [
        { name: 'description', content: 'Platform tanya-jawab islami antara jamaah dan ustadz AhsanTV.' },
        { property: 'og:title', content: 'Tanya Ustadz — AhsanTV' },
        { property: 'og:description', content: 'Ajukan pertanyaan islamimu secara anonim kepada ustadz.' },
        { property: 'og:image', content: '/og-image.png' },
        { property: 'og:type', content: 'website' },
        { name: 'theme-color', content: '#059669' },
      ],
    },
  },

  runtimeConfig: {
    adminGatePassword: process.env.ADMIN_GATE_PASSWORD,
    public: {
      supabaseUrl: process.env.SUPABASE_URL,
      supabaseAnonKey: process.env.SUPABASE_ANON_KEY,
    },
  },

  typescript: {
    strict: true,
  },

  compatibilityDate: '2024-11-01',
})
