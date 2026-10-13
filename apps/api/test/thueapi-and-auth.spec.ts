import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { PrismaService } from '../src/prisma/prisma.service.js';
import { ThueApiService } from '../src/thueapi/thueapi.service.js';
import { AuthService } from '../src/auth/auth.service.js';
import { OrdersService } from '../src/orders/orders.service.js';

describe('ThueApi.Pro & Google Auth & Subscription Activation Test Suite', () => {
  let prisma: PrismaService;
  let thueApiService: ThueApiService;
  let authService: AuthService;
  let ordersService: OrdersService;

  const testEmail = 'tester_subscription_2026@gmail.com';
  const testOrderCode = 'ORD_THUEAPI_TEST_01';

  let originalConfig: any;

  beforeAll(async () => {
    prisma = new PrismaService();
    await prisma.$connect();
    thueApiService = new ThueApiService(prisma);
    authService = new AuthService(prisma);
    ordersService = new OrdersService(prisma);

    // Lưu backup cấu hình gốc của người dùng
    originalConfig = await prisma.systemConfig.findUnique({ where: { id: 'default' } });

    // Dọn dẹp dữ liệu test cũ
    await prisma.webhookLog.deleteMany({
      where: { orderCode: testOrderCode },
    });
    await prisma.transaction.deleteMany({
      where: { orderCode: testOrderCode },
    });
    await prisma.order.deleteMany({
      where: { orderCode: testOrderCode },
    });
    await prisma.appDeviceUser.deleteMany({
      where: { email: testEmail },
    });
  });

  afterAll(async () => {
    // Dọn dẹp sau khi kiểm thử
    await prisma.webhookLog.deleteMany({
      where: { orderCode: testOrderCode },
    });
    await prisma.transaction.deleteMany({
      where: { orderCode: testOrderCode },
    });
    await prisma.order.deleteMany({
      where: { orderCode: testOrderCode },
    });
    await prisma.appDeviceUser.deleteMany({
      where: { email: testEmail },
    });

    // Khôi phục chính xác cấu hình gốc của người dùng
    if (originalConfig) {
      await prisma.systemConfig.update({
        where: { id: 'default' },
        data: {
          thueApiEnabled: originalConfig.thueApiEnabled,
          thueApiKey: originalConfig.thueApiKey,
          thueApiSecret: originalConfig.thueApiSecret,
          thueApiBankAcc: originalConfig.thueApiBankAcc,
          thueApiBankCode: originalConfig.thueApiBankCode,
          bankAcc: originalConfig.bankAcc,
          bankCode: originalConfig.bankCode,
          bankName: originalConfig.bankName,
        },
      });
    }

    await prisma.$disconnect();
  });

  describe('1. Cấu hình ThueApi.Pro & Kiểm tra trạng thái kết nối', () => {
    it('Nếu chưa có API Key -> Trả về trạng thái BLOCKED', async () => {
      // Tạm thời tắt hoặc xóa key
      await prisma.systemConfig.upsert({
        where: { id: 'default' },
        update: { thueApiKey: '', thueApiEnabled: false },
        create: {
          id: 'default',
          brandName: 'Test Brand',
          brandSlogan: 'Test Slogan',
          chplayLink: '',
          youtubeLink: '',
          thueApiKey: '',
          thueApiEnabled: false,
        },
      });

      const config = await thueApiService.getConfig();
      expect(config.status).toContain('BLOCKED: CHƯA CÓ CẤU HÌNH NHÀ CUNG CẤP');
      expect(config.hasKey).toBe(false);

      const testRes = await thueApiService.testConnection();
      expect(testRes.success).toBe(false);
      expect(testRes.status).toContain('BLOCKED');
    });

    it('Lưu cấu hình an toàn & Che API key khi hiển thị', async () => {
      const updated = await thueApiService.updateConfig({
        enabled: true,
        apiKey: 'thueapi_live_secret_key_8899aabb',
        webhookSecret: 'secret_hash_webhook_2026',
        bankAcc: '0869226687',
        bankCode: 'MB',
      });

      expect(updated.enabled).toBe(true);
      expect(updated.hasKey).toBe(true);
      expect(updated.apiKeyMasked).toContain('thue...aabb');
      expect(updated.status).toContain('ACTIVE');
    });
  });

  describe('2. Xác thực JWT Session & Google Auth', () => {
    it('Ký và xác thực JWT session token chuẩn RFC 7519', () => {
      const payload = {
        email: 'user@autobank.pro',
        sub: 'usr_123456',
        name: 'Trần Quốc Vũ',
        role: 'USER',
      };

      const token = authService.signToken(payload, 3600);
      expect(typeof token).toBe('string');
      expect(token.split('.').length).toBe(3);

      const verified = authService.verifyToken(token);
      expect(verified.email).toBe(payload.email);
      expect(verified.sub).toBe(payload.sub);
    });

    it('Từ chối token giả mạo hoặc chữ ký sai', () => {
      const fakeToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJlbWFpbCI6ImhhY2tlckBnbWFpbC5jb20ifQ.invalid_signature';
      expect(() => authService.verifyToken(fakeToken)).toThrow();
    });
  });

  describe('3. Xử lý Webhook ThueApi.Pro & Kích hoạt gói tự động', () => {
    it('Tạo đơn hàng gói 1 năm và tài khoản người dùng dùng thử', async () => {
      // 1. Tạo user với hạn dùng sắp hết
      const user = await prisma.appDeviceUser.create({
        data: {
          name: 'Tester AutoBank',
          email: testEmail,
          device: 'Pixel 8',
          version: '1.2.0',
          packagePlan: 'Dùng thử 3 ngày',
          hasUsedTrial: true,
          expiresAt: new Date(Date.now() + 86400000), // Còn 1 ngày
          status: 'ACTIVE',
        },
      });
      expect(user.email).toBe(testEmail);

      // 2. Tạo đơn hàng gói 1 năm (299.000đ)
      const order = await ordersService.create({
        orderCode: testOrderCode,
        totalAmount: 299000,
        description: 'Gói 1 năm (365 ngày)',
        customerName: testEmail,
      });
      expect(order.orderCode).toBe(testOrderCode);
      expect(order.status).toBe('PENDING');
    });

    it('Từ chối Webhook khi chữ ký sai hoặc thiếu', async () => {
      const webhookPayload = {
        gateway: 'MB',
        accountNumber: '0869226687',
        amount: 299000,
        transferType: 'in',
        transactionNumber: 'FT_THUEAPI_998811',
        content: `Thanh toan don hang ${testOrderCode} AutoBank Pro`,
      };

      // 1. Thiếu chữ ký
      await expect(thueApiService.handleWebhook(webhookPayload)).rejects.toThrow('Webhook thiếu chữ ký xác thực');

      // 2. Chữ ký sai
      await expect(thueApiService.handleWebhook(webhookPayload, 'invalid_fake_signature_hash')).rejects.toThrow('Chữ ký Webhook không hợp lệ');
    });

    it('Nhận Webhook từ ThueApi.Pro có chữ ký hợp lệ -> Tự động khớp đơn và gia hạn gói thành công', async () => {
      const userBefore = await prisma.appDeviceUser.findUnique({
        where: { email: testEmail },
      });
      const expiryBefore = new Date(userBefore!.expiresAt).getTime();

      const webhookPayload = {
        gateway: 'MB',
        accountNumber: '0869226687',
        amount: 299000,
        transferType: 'in',
        transactionNumber: 'FT_THUEAPI_998811',
        content: `Thanh toan don hang ${testOrderCode} AutoBank Pro`,
        transferDate: new Date().toISOString(),
      };

      const crypto = await import('node:crypto');
      const validSig = crypto
        .createHmac('sha256', 'secret_hash_webhook_2026')
        .update(JSON.stringify(webhookPayload))
        .digest('hex');

      const res = await thueApiService.handleWebhook(webhookPayload, validSig);
      expect(res.success).toBe(true);
      expect(res.data.subscriptionActivated).toBe(true);

      // Kiểm tra trạng thái đơn hàng đã thành PAID
      const updatedOrder = await ordersService.findByCode(testOrderCode);
      expect(updatedOrder.status).toBe('PAID');
      expect(Number(updatedOrder.paidAmount)).toBe(299000);

      // Kiểm tra tài khoản đã được tự động cộng thêm ít nhất 365 ngày
      const userAfter = await prisma.appDeviceUser.findUnique({
        where: { email: testEmail },
      });
      const expiryAfter = new Date(userAfter!.expiresAt).getTime();
      const diffDays = Math.round((expiryAfter - expiryBefore) / (86400000));

      expect(diffDays).toBeGreaterThanOrEqual(365);
    });

    it('Xử lý Idempotency: Webhook gửi lặp lại -> Bị chặn, không cộng thời hạn lần 2', async () => {
      const userBefore = await prisma.appDeviceUser.findUnique({
        where: { email: testEmail },
      });

      const duplicatePayload = {
        gateway: 'MB',
        accountNumber: '0869226687',
        amount: 299000,
        transferType: 'in',
        transactionNumber: 'FT_THUEAPI_998811', // Cùng mã giao dịch
        content: `Thanh toan don hang ${testOrderCode} AutoBank Pro`,
        transferDate: new Date().toISOString(),
      };

      const crypto = await import('node:crypto');
      const validSig = crypto
        .createHmac('sha256', 'secret_hash_webhook_2026')
        .update(JSON.stringify(duplicatePayload))
        .digest('hex');

      const res = await thueApiService.handleWebhook(duplicatePayload, validSig);
      expect(res.isDuplicate).toBe(true);

      const userAfter = await prisma.appDeviceUser.findUnique({
        where: { email: testEmail },
      });

      // Thời hạn phải giữ nguyên không đổi
      expect(new Date(userAfter!.expiresAt).getTime()).toBe(new Date(userBefore!.expiresAt).getTime());
    });
  });
});
