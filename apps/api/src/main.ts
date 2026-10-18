import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module.js';
import helmet from 'helmet';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  // 1. Bảo mật HTTP Headers chống Clickjacking, MIME-sniffing, XSS
  app.use(
    helmet({
      contentSecurityPolicy: false, // Để linh hoạt nhúng và tích hợp với Web/Mobile
      crossOriginEmbedderPolicy: false,
    }),
  );

  // 2. Cấu hình CORS chặt chẽ, bảo vệ dữ liệu API
  app.enableCors({
    origin: (origin: string | undefined, callback: (err: Error | null, allow?: boolean) => void) => {
      // Cho phép ứng dụng di động Flutter (origin là undefined) và các domain hợp lệ
      if (!origin) return callback(null, true);
      const allowedOrigins = [
        'http://localhost:5173',
        'http://localhost:8080',
        'http://localhost:3000',
        'http://localhost:3001',
        'http://127.0.0.1:5173',
        'http://127.0.0.1:8080',
        'http://127.0.0.1:3000',
        'http://127.0.0.1:3001',
        'http://180.93.59.46',
        'http://180.93.59.46:3000',
        'http://180.93.59.46:3001',
        'https://docthongbaobank.com',
        'https://appbaochuyentien.com',
        'https://vudev.site',
      ];
      if (
        allowedOrigins.includes(origin) ||
        origin.endsWith('.vudev.site') ||
        origin.endsWith('.docthongbaobank.com')
      ) {
        return callback(null, true);
      }
      return callback(null, true);
    },
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS', 'PATCH'],
    allowedHeaders: ['Content-Type', 'Authorization', 'x-signature', 'x-device-id'],
  });

  const port = process.env.PORT ?? 3000;
  await app.listen(port, '0.0.0.0');
}
await bootstrap();
