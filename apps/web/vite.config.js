import { defineConfig } from 'vite';
import { resolve } from 'path';

export default defineConfig({
  plugins: [
    {
      name: 'admin-route-rewrite',
      configureServer(server) {
        server.middlewares.use((req, res, next) => {
          const url = req.url ? req.url.split('?')[0] : '';
          const query = req.url && req.url.includes('?') ? req.url.substring(req.url.indexOf('?')) : '';

          if (url === '/admin') {
            res.writeHead(301, { Location: `/admin/${query}` });
            res.end();
            return;
          }

          const adminPages = ['login', 'config', 'banks', 'users', 'notifications', 'orders', 'keys', 'payment-autobank'];
          for (const page of adminPages) {
            if (url === `/admin/${page}`) {
              res.writeHead(301, { Location: `/admin/${page}.html${query}` });
              res.end();
              return;
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
    },
  },
  build: {
    outDir: 'dist',
    assetsDir: 'assets',
    rollupOptions: {
      input: {
        main: resolve(__dirname, 'index.html'),
        live: resolve(__dirname, 'live.html'),
        admin: resolve(__dirname, 'admin/index.html'),
        adminLogin: resolve(__dirname, 'admin/login.html'),
        adminConfig: resolve(__dirname, 'admin/config.html'),
        adminBanks: resolve(__dirname, 'admin/banks.html'),
        adminUsers: resolve(__dirname, 'admin/users.html'),
        adminNotifications: resolve(__dirname, 'admin/notifications.html'),
        adminOrders: resolve(__dirname, 'admin/orders.html'),
        adminKeys: resolve(__dirname, 'admin/keys.html'),
        adminPaymentAutobank: resolve(__dirname, 'admin/payment-autobank.html'),
      },
    },
  },
});

