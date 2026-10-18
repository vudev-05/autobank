import { defineConfig } from 'vite';
import { resolve } from 'path';

export default defineConfig({
  plugins: [
    {
      name: 'clean-urls-rewrite-and-redirect',
      configureServer(server) {
        server.middlewares.use((req, res, next) => {
          if (!req.url) return next();
          const [urlPath, queryString] = req.url.split('?');
          const query = queryString ? `?${queryString}` : '';

          // 1. Clean public share URL: /live
          if (urlPath === '/live') {
            req.url = `/live.html${query}`;
            return next();
          }

          // Redirect /live.html -> /live
          if (urlPath === '/live.html') {
            res.writeHead(301, { Location: `/live${query}` });
            res.end();
            return;
          }

          // 2. Clean admin root URL: /admin
          if (urlPath === '/admin' || urlPath === '/admin/') {
            req.url = `/admin/index.html${query}`;
            return next();
          }

          if (urlPath === '/admin/index.html' || urlPath === '/admin/index') {
            res.writeHead(301, { Location: `/admin${query}` });
            res.end();
            return;
          }

          // 3. Clean admin sub-pages
          const adminPages = ['login', 'config', 'banks', 'users', 'notifications', 'orders', 'coupons', 'keys', 'payment-autobank'];
          
          // Redirect legacy .html to clean URLs
          for (const page of adminPages) {
            if (urlPath === `/admin/${page}.html`) {
              res.writeHead(301, { Location: `/admin/${page}${query}` });
              res.end();
              return;
            }
          }

          // Transparently rewrite clean URLs to actual HTML files
          for (const page of adminPages) {
            if (urlPath === `/admin/${page}`) {
              req.url = `/admin/${page}.html${query}`;
              return next();
            }
          }

          next();
        });
      },
    },
  ],
  server: {
    port: 5173,
    open: false,
    host: true,
    proxy: {
      '/api': {
        target: 'http://localhost:3000',
        changeOrigin: true,
      },
      '/tts': {
        target: 'http://localhost:3000',
        changeOrigin: true,
      },
      '^/admin/(phone-status|phone-heartbeat|live-pin|verify-live-pin)': {
        target: 'http://localhost:3000',
        changeOrigin: true,
      },
    },
  },
  build: {
    outDir: 'dist',
    assetsDir: 'assets',
    rollupOptions: {
      input: {
        main: resolve(__dirname, 'index.html'),
        live: resolve(__dirname, 'live.html'),
        privacy: resolve(__dirname, 'privacy.html'),
        admin: resolve(__dirname, 'admin/index.html'),
        adminLogin: resolve(__dirname, 'admin/login.html'),
        adminConfig: resolve(__dirname, 'admin/config.html'),
        adminBanks: resolve(__dirname, 'admin/banks.html'),
        adminUsers: resolve(__dirname, 'admin/users.html'),
        adminNotifications: resolve(__dirname, 'admin/notifications.html'),
        adminCoupons: resolve(__dirname, 'admin/coupons.html'),
        adminOrders: resolve(__dirname, 'admin/orders.html'),
        adminKeys: resolve(__dirname, 'admin/keys.html'),
        adminPaymentAutobank: resolve(__dirname, 'admin/payment-autobank.html'),
      },
    },
  },
});

