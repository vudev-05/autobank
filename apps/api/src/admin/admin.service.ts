import { Injectable, BadRequestException, OnModuleInit, Logger } from '@nestjs/common';
import * as fs from 'fs';
import * as path from 'path';
import { PrismaService } from '../prisma/prisma.service.js';
import { MailService } from '../mail/mail.service.js';

@Injectable()
export class AdminService implements OnModuleInit {
  private readonly logger = new Logger(AdminService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly mailService: MailService,
  ) {}

  async onModuleInit() {
    try {
      // Tự động kiểm tra và khởi tạo mã giảm giá NGUOIMOI tân thủ 10%
      await this.prisma.discountCoupon.upsert({
        where: { code: 'NGUOIMOI' },
        update: {
          description: 'Ưu đãi thành viên mới: Giảm 10% trong vòng 3 ngày dùng thử',
          discountPercent: 10,
          discountAmount: 0,
          minPrice: 0,
          targetAudience: 'NEW_3DAYS',
          autoApply: true,
          isActive: true,
        },
        create: {
          code: 'NGUOIMOI',
          description: 'Ưu đãi thành viên mới: Giảm 10% trong vòng 3 ngày dùng thử',
          discountPercent: 10,
          discountAmount: 0,
          minPrice: 0,
          targetAudience: 'NEW_3DAYS',
          autoApply: true,
          isActive: true,
        },
      });
      this.logger.log('✓ Đã đồng bộ mã giảm giá NGUOIMOI (-10% cho thành viên mới 3 ngày).');
    } catch (e: any) {
      this.logger.warn(`Không thể nạp mã NGUOIMOI tự động: ${e.message}`);
    }

    // Tự động quét gửi mail nhắc nhở sắp hết hạn dùng thử định kỳ mỗi 60 phút
    setInterval(() => {
      this.sendTrialExpiryReminders().catch((err) => {
        this.logger.error(`Lỗi khi quét gửi email dùng thử: ${err.message}`);
      });
    }, 60 * 60 * 1000);
  }

  async getConfig() {
    const config = await this.prisma.systemConfig.findUnique({
      where: { id: 'default' },
    });
    if (!config) return null;
    let parsedPackages = [];
    let parsedAffiliate = null;
    let ratingUrl = config.chplayLink || 'https://play.google.com/store/apps/details?id=com.docthongbaobank.app';
    let liveWebPin = '889922';
    let videoGuideNewbie = '';
    let videoGuideSmooth = '';
    let videoGuideAffiliate = '';
    let videoGuideHistory = '';
    let videoGuideVoice = '';

    if (config.packagesJson) {
      try {
        const parsed = JSON.parse(config.packagesJson);
        if (Array.isArray(parsed)) {
          parsedPackages = parsed;
        } else if (parsed && typeof parsed === 'object') {
          parsedPackages = parsed.packages || [];
          parsedAffiliate = parsed.affiliateRewards || null;
          if (parsed.ratingUrl) ratingUrl = parsed.ratingUrl;
          if (parsed.liveWebPin) liveWebPin = parsed.liveWebPin;
          if (parsed.videoGuideNewbie) videoGuideNewbie = parsed.videoGuideNewbie;
          if (parsed.videoGuideSmooth) videoGuideSmooth = parsed.videoGuideSmooth;
          if (parsed.videoGuideAffiliate) videoGuideAffiliate = parsed.videoGuideAffiliate;
          if (parsed.videoGuideHistory) videoGuideHistory = parsed.videoGuideHistory;
          if (parsed.videoGuideVoice) videoGuideVoice = parsed.videoGuideVoice;
        }
      } catch (_) {}
    }

    return {
      ...config,
      packages: parsedPackages,
      affiliateRewards: parsedAffiliate || [
        { name: 'Gói 1 Tháng', duration: '30 ngày', reward: 10000, desc: 'Nhận 10.000₫/lượt' },
        { name: 'Gói 3 Tháng', duration: '90 ngày', reward: 25000, desc: 'Nhận 25.000₫/lượt' },
        { name: 'Gói 6 Tháng', duration: '180 ngày', reward: 45000, desc: 'Nhận 45.000₫/lượt' },
        { name: 'Gói 1 Năm (VIP)', duration: '365 ngày', reward: 75000, desc: 'Nhận 75.000₫/lượt' },
        { name: 'Gói Vĩnh Viễn Trọn Đời', duration: 'Trọn đời', reward: 120000, desc: 'Nhận 120.000₫/lượt' },
      ],
      ratingUrl,
      liveWebPin,
      videoGuideNewbie: videoGuideNewbie || config.youtubeLink || 'https://www.youtube.com/watch?v=kYJqD9bZ_fQ',
      videoGuideSmooth: videoGuideSmooth || 'https://www.youtube.com/watch?v=kYJqD9bZ_fQ',
      videoGuideAffiliate: videoGuideAffiliate || 'https://www.youtube.com/watch?v=kYJqD9bZ_fQ',
      videoGuideHistory: videoGuideHistory || 'https://www.youtube.com/watch?v=kYJqD9bZ_fQ',
      videoGuideVoice: videoGuideVoice || 'https://www.youtube.com/watch?v=kYJqD9bZ_fQ',
    };
  }

  async updateConfig(dto: any) {
    const allowed = [
      'brandName', 'brandSlogan', 'chplayLink', 'youtubeLink', 'hotline',
      'email', 'facebook', 'tiktok', 'bankCode', 'bankAcc', 'bankName',
      'priceTrial', 'price1m', 'price3m', 'price6m', 'price9m', 'price1y',
      'priceLifetime', 'bonusMonths1y', 'marketingBanner',
      'maintenance', 'maintenanceMsg', 'googlePayMaintenance', 'googlePayMaintenanceMsg', 'latestVersion', 'minVersion',
      'serverDomain', 'webDomain', 'apiPort', 'packagesJson',
    ];
    const data: any = {};
    for (const key of allowed) {
      if (dto[key] !== undefined) {
        if (key.startsWith('price') && key !== 'priceTrial') {
          data[key] = parseInt(String(dto[key]).replace(/\D/g, ''), 10) || 0;
        } else if (key === 'bonusMonths1y' || key === 'apiPort') {
          data[key] = parseInt(String(dto[key]).replace(/\D/g, ''), 10) || 0;
        } else if (key === 'maintenance' || key === 'googlePayMaintenance') {
          data[key] = Boolean(dto[key]);
        } else {
          data[key] = dto[key];
        }
      }
    }

    if (
      dto.packages !== undefined ||
      dto.affiliateRewards !== undefined ||
      dto.ratingUrl !== undefined ||
      dto.liveWebPin !== undefined ||
      dto.videoGuideNewbie !== undefined ||
      dto.videoGuideSmooth !== undefined ||
      dto.videoGuideAffiliate !== undefined ||
      dto.videoGuideHistory !== undefined ||
      dto.videoGuideVoice !== undefined
    ) {
      const existingConfig = await this.prisma.systemConfig.findUnique({ where: { id: 'default' } });
      let currentPackages = [];
      let currentAffiliate = null;
      let currentRating = dto.ratingUrl || dto.chplayLink;
      let currentLivePin = dto.liveWebPin;
      let currentVideoNewbie = dto.videoGuideNewbie;
      let currentVideoSmooth = dto.videoGuideSmooth;
      let currentVideoAffiliate = dto.videoGuideAffiliate;
      let currentVideoHistory = dto.videoGuideHistory;
      let currentVideoVoice = dto.videoGuideVoice;

      if (existingConfig?.packagesJson) {
        try {
          const parsed = JSON.parse(existingConfig.packagesJson);
          if (Array.isArray(parsed)) {
            currentPackages = parsed;
          } else if (parsed && typeof parsed === 'object') {
            currentPackages = parsed.packages || [];
            currentAffiliate = parsed.affiliateRewards || null;
            if (!currentRating) currentRating = parsed.ratingUrl;
            if (!currentLivePin) currentLivePin = parsed.liveWebPin;
            if (currentVideoNewbie === undefined) currentVideoNewbie = parsed.videoGuideNewbie;
            if (currentVideoSmooth === undefined) currentVideoSmooth = parsed.videoGuideSmooth;
            if (currentVideoAffiliate === undefined) currentVideoAffiliate = parsed.videoGuideAffiliate;
            if (currentVideoHistory === undefined) currentVideoHistory = parsed.videoGuideHistory;
            if (currentVideoVoice === undefined) currentVideoVoice = parsed.videoGuideVoice;
          }
        } catch (_) {}
      }

      if (dto.packages !== undefined) {
        currentPackages = typeof dto.packages === 'string' ? JSON.parse(dto.packages) : dto.packages;
      }
      if (dto.affiliateRewards !== undefined) {
        currentAffiliate = typeof dto.affiliateRewards === 'string' ? JSON.parse(dto.affiliateRewards) : dto.affiliateRewards;
      }

      data.packagesJson = JSON.stringify({
        packages: currentPackages,
        affiliateRewards: currentAffiliate,
        ratingUrl: currentRating || existingConfig?.chplayLink || 'https://play.google.com/store/apps/details?id=com.docthongbaobank.app',
        liveWebPin: currentLivePin || '889922',
        videoGuideNewbie: currentVideoNewbie || '',
        videoGuideSmooth: currentVideoSmooth || '',
        videoGuideAffiliate: currentVideoAffiliate || '',
        videoGuideHistory: currentVideoHistory || '',
        videoGuideVoice: currentVideoVoice || '',
      });
    }
    const defaultCreate = {
      id: 'default',
      brandName: 'Đọc thông báo nhận tiền',
      brandSlogan: 'Tiền vừa sang ~ máy báo vang',
      chplayLink: 'https://play.google.com/store/apps/details?id=com.docthongbaobank.app',
      youtubeLink: '',
      hotline: '0869226687',
      email: 'tranquocvu3011@gmail.com',
      facebook: 'https://www.facebook.com/Baochuyentienbanggiongnoi',
      tiktok: 'https://www.tiktok.com/@locketgoldqvu',
      bankCode: 'MB',
      bankAcc: '0869226687',
      bankName: 'TRẦN QUỐC VŨ',
      priceTrial: '0đ (3 ngày)',
      price1m: 38000,
      price3m: 99000,
      price6m: 179000,
      price9m: 249000,
      price1y: 299000,
      priceLifetime: 499000,
      serverDomain: 'https://api.docthongbaobank.com',
      webDomain: 'https://docthongbaobank.com',
      apiPort: 3000,
      maintenance: false,
      maintenanceMsg: 'Hệ thống đang bảo trì nâng cấp máy chủ định kỳ. Vui lòng quay lại sau 15 phút.',
      latestVersion: '1.2.0',
      minVersion: '1.0.0',
      ...data,
    };

    return this.prisma.systemConfig.upsert({
      where: { id: 'default' },
      update: data,
      create: defaultCreate,
    });
  }

  async getBanks() {
    return this.prisma.bankApp.findMany({
      orderBy: { name: 'asc' },
    });
  }

  async saveBank(dto: any) {
    const id = String(dto.id || dto.code || dto.pkg || `bank_${Date.now()}`);
    const data = {
      name: dto.name || '',
      app: dto.app || dto.name || '',
      code: String(dto.code || id).toUpperCase(),
      pkg: dto.pkg || '',
      category: dto.category || 'commercial',
      logo: dto.logo || '',
      guide: dto.guide || '',
      isActive: dto.active !== undefined ? Boolean(dto.active) : (dto.isActive !== undefined ? Boolean(dto.isActive) : true),
    };
    return this.prisma.bankApp.upsert({
      where: { id },
      update: data,
      create: { id, ...data },
    });
  }

  async toggleBank(idOrCode: string) {
    const b = await this.prisma.bankApp.findFirst({
      where: {
        OR: [{ id: idOrCode }, { code: idOrCode }, { pkg: idOrCode }],
      },
    });
    if (!b) return null;
    return this.prisma.bankApp.update({
      where: { id: b.id },
      data: { isActive: !b.isActive },
    });
  }

  async deleteBank(idOrCode: string) {
    const b = await this.prisma.bankApp.findFirst({
      where: {
        OR: [{ id: idOrCode }, { code: idOrCode }, { pkg: idOrCode }],
      },
    });
    if (!b) return null;
    return this.prisma.bankApp.delete({
      where: { id: b.id },
    });
  }

  private async syncToUsersTable(user: any) {
    if (!user || !user.email) return;
    try {
      await this.prisma.$executeRawUnsafe(`
        INSERT INTO \`users\` (\`id\`, \`name\`, \`email\`, \`phone\`, \`shopName\`, \`packagePlan\`, \`status\`, \`device\`, \`version\`, \`deviceId\`, \`expiresAt\`, \`createdAt\`, \`updatedAt\`)
        VALUES (UUID(), ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW(), NOW())
        ON DUPLICATE KEY UPDATE
          \`name\` = VALUES(\`name\`),
          \`phone\` = VALUES(\`phone\`),
          \`shopName\` = VALUES(\`shopName\`),
          \`packagePlan\` = VALUES(\`packagePlan\`),
          \`status\` = VALUES(\`status\`),
          \`device\` = VALUES(\`device\`),
          \`version\` = VALUES(\`version\`),
          \`deviceId\` = VALUES(\`deviceId\`),
          \`expiresAt\` = VALUES(\`expiresAt\`),
          \`updatedAt\` = NOW()
      `, user.name, user.email, user.phone || null, user.shopName || null, user.packagePlan || 'Dùng thử 3 ngày', user.status || 'ACTIVE', user.device || 'Thiết bị di động', user.version || '1.2.0', user.deviceId || null, user.expiresAt ? new Date(user.expiresAt) : null);
    } catch (_) {}
  }

  async upsertUser(dto: any) {
    const isTrial = (dto.packagePlan || '').toLowerCase().includes('dùng thử') || (dto.packagePlan || '').toLowerCase().includes('trial');
    const existing = await this.prisma.appDeviceUser.findUnique({ where: { email: dto.email } });

    let result;
    if (existing) {
      // Nếu tài khoản đã tồn tại và đang có gói trả phí thật sự (còn hạn), giữ nguyên trừ khi forceUpdate
      const hasPaidPlan = existing.packagePlan && 
        !existing.packagePlan.toLowerCase().includes('dùng thử') && 
        existing.packagePlan !== 'Chưa kích hoạt gói' &&
        existing.packagePlan !== 'Chưa đăng ký gói' &&
        new Date(existing.expiresAt) > new Date();
      const isNewTrialRequest = isTrial && !dto.forceUpdate;

      let targetPackagePlan = (hasPaidPlan && isNewTrialRequest) 
        ? existing.packagePlan 
        : (dto.packagePlan || existing.packagePlan || 'Dùng thử 3 ngày');

      let targetExpiresAt = (hasPaidPlan && isNewTrialRequest)
        ? existing.expiresAt
        : (dto.expiresAt ? new Date(dto.expiresAt) : existing.expiresAt);

      if ((dto.status === 'EXPIRED' || dto.status === 'BLOCKED') && targetExpiresAt >= new Date()) {
        targetExpiresAt = new Date(Date.now() - 86400000);
      } else if (targetExpiresAt > new Date()) {
        // Hạn sử dụng còn trong tương lai -> Tự động chuẩn hóa tên gói nếu bị dính chuỗi 'hết hạn'
        if (targetPackagePlan.includes('hết hạn') || targetPackagePlan === 'Chưa kích hoạt gói' || targetPackagePlan === 'Chưa đăng ký gói') {
          targetPackagePlan = '1 Tháng';
        }
      }

      result = await this.prisma.appDeviceUser.update({
        where: { email: dto.email },
        data: {
          name: dto.name || existing.name,
          device: dto.device || existing.device,
          version: dto.version || existing.version,
          packagePlan: targetPackagePlan,
          hasUsedTrial: existing.hasUsedTrial || isTrial || Boolean(dto.hasUsedTrial),
          expiresAt: targetExpiresAt,
          status: dto.status || existing.status,
          phone: (dto.phone !== undefined && dto.phone !== null && String(dto.phone).trim().length > 0) ? String(dto.phone).trim() : existing.phone,
          shopName: (dto.shopName !== undefined && dto.shopName !== null && String(dto.shopName).trim().length > 0) ? String(dto.shopName).trim() : existing.shopName,
          deviceId: dto.deviceId || existing.deviceId,
        },
      });
    } else {
      let expiresAt = dto.expiresAt ? new Date(dto.expiresAt) : new Date(Date.now() + 3 * 86400000);
      if ((dto.status === 'EXPIRED' || dto.status === 'BLOCKED') && expiresAt >= new Date()) {
        expiresAt = new Date(Date.now() - 86400000);
      }
      const hasUsedTrial = Boolean(isTrial || dto.hasUsedTrial);

      result = await this.prisma.appDeviceUser.create({
        data: {
          name: dto.name || dto.email.split('@')[0],
          email: dto.email,
          device: dto.device || 'Android',
          version: dto.version || '1.2.0',
          packagePlan: dto.packagePlan || 'Dùng thử 3 ngày',
          hasUsedTrial: hasUsedTrial,
          expiresAt: expiresAt,
          status: dto.status || 'ACTIVE',
          phone: dto.phone || null,
          shopName: dto.shopName || null,
          deviceId: dto.deviceId || null,
        },
      });
    }

    await this.syncToUsersTable(result);
    return result;
  }

  async getUsers() {
    return this.prisma.appDeviceUser.findMany({
      orderBy: { createdAt: 'desc' },
    });
  }

  async getUserByEmail(email: string) {
    return this.prisma.appDeviceUser.findUnique({
      where: { email },
    });
  }

  async extendUser(idOrEmail: string, days: number) {
    const user = await this.prisma.appDeviceUser.findFirst({
      where: {
        OR: [{ email: idOrEmail }, { id: idOrEmail }],
      },
    });
    if (!user) return null;
    const current = new Date(user.expiresAt) > new Date() ? new Date(user.expiresAt) : new Date();
    current.setDate(current.getDate() + days);

    let resolvedPkg = user.packagePlan;
    if (!resolvedPkg || resolvedPkg.includes('hết hạn') || resolvedPkg.includes('Chưa')) {
      resolvedPkg = days >= 365 ? '1 Năm' : (days >= 90 ? '3 Tháng' : '1 Tháng');
    }

    const updated = await this.prisma.appDeviceUser.update({
      where: { id: user.id },
      data: { expiresAt: current, status: 'ACTIVE', packagePlan: resolvedPkg },
    });
    await this.syncToUsersTable(updated);
    return updated;
  }

  async toggleBlockUser(idOrEmail: string) {
    const user = await this.prisma.appDeviceUser.findFirst({
      where: {
        OR: [{ email: idOrEmail }, { id: idOrEmail }],
      },
    });
    if (!user) return null;
    const nextStatus = user.status === 'BLOCKED' ? 'ACTIVE' : 'BLOCKED';
    const updated = await this.prisma.appDeviceUser.update({
      where: { id: user.id },
      data: { status: nextStatus },
    });
    await this.syncToUsersTable(updated);
    return updated;
  }

  async deleteUser(idOrEmail: string) {
    const user = await this.prisma.appDeviceUser.findFirst({
      where: {
        OR: [{ email: idOrEmail }, { id: idOrEmail }],
      },
    });
    if (!user) return null;
    try {
      await this.prisma.$executeRawUnsafe('DELETE FROM `users` WHERE `email` = ?', user.email);
    } catch (_) {}
    return this.prisma.appDeviceUser.delete({
      where: { id: user.id },
    });
  }

  async getStats() {
    const totalUsers = await this.prisma.appDeviceUser.count();
    const activeUsers = await this.prisma.appDeviceUser.count({ where: { status: 'ACTIVE' } });
    const trialUsers = await this.prisma.appDeviceUser.count({ where: { status: 'TRIAL' } });
    const expiredUsers = await this.prisma.appDeviceUser.count({ where: { status: 'EXPIRED' } });
    const blockedUsers = await this.prisma.appDeviceUser.count({ where: { status: 'BLOCKED' } });

    const now = new Date();
    const startOfDay = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 0, 0, 0);

    const todayTransactions = await this.prisma.transaction.findMany({
      where: { transactionTime: { gte: startOfDay } },
      select: { amount: true },
    });
    const todayTxCount = todayTransactions.length;
    const todayTxTotal = todayTransactions.reduce((acc, t) => acc + Number(t.amount || 0), 0);
    const allTxCount = await this.prisma.transaction.count();

    const orders = await this.prisma.order.findMany();
    const paidOrders = orders.filter(o => o.status === 'PAID');
    const totalRevenue = paidOrders.reduce((acc, o) => acc + Number(o.totalAmount || 0), 0);

    return {
      users: {
        total: totalUsers,
        active: activeUsers,
        trial: trialUsers,
        expired: expiredUsers,
        blocked: blockedUsers,
      },
      transactions: {
        todayCount: todayTxCount,
        todayAmount: todayTxTotal,
        totalCount: allTxCount,
      },
      orders: {
        totalCount: paidOrders.length,
        paidCount: paidOrders.length,
        revenue: totalRevenue,
      },
    };
  }

  async getLogs() {
    const [transactions, users, orders] = await Promise.all([
      this.prisma.transaction.findMany({
        take: 20,
        orderBy: { transactionTime: 'desc' },
      }),
      this.prisma.appDeviceUser.findMany({
        take: 10,
        orderBy: { updatedAt: 'desc' },
      }),
      this.prisma.order.findMany({
        take: 10,
        orderBy: { createdAt: 'desc' },
      }),
    ]);

    const logs: any[] = [];

    for (const t of transactions) {
      const time = new Date(t.transactionTime).toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit', second: '2-digit' });
      const date = new Date(t.transactionTime).toLocaleDateString('vi-VN');
      logs.push({
        id: `tx_${t.id}`,
        time: `${time} ${date}`,
        timestamp: new Date(t.transactionTime).getTime(),
        type: 'Phát Loa Báo Tiền',
        entity: t.bankCode || 'Ngân hàng',
        detail: `+${Number(t.amount).toLocaleString('vi-VN')}đ (${t.content || t.orderCode || 'Nhận tiền'})`,
        status: 'SUCCESS',
        badge: 'Thành công',
      });
    }

    for (const u of users) {
      const time = new Date(u.updatedAt).toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit', second: '2-digit' });
      const date = new Date(u.updatedAt).toLocaleDateString('vi-VN');
      logs.push({
        id: `usr_${u.id}`,
        time: `${time} ${date}`,
        timestamp: new Date(u.updatedAt).getTime(),
        type: 'Đồng Bộ Người Dùng',
        entity: `${u.name} (${u.device || 'Android'})`,
        detail: `${u.packagePlan || 'Gói cước'} · Hạn: ${new Date(u.expiresAt).toLocaleDateString('vi-VN')}`,
        status: u.status === 'BLOCKED' ? 'BLOCKED' : 'SUCCESS',
        badge: u.status === 'BLOCKED' ? 'Đã khóa' : 'Hoạt động',
      });
    }

    for (const o of orders) {
      const time = new Date(o.createdAt).toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit', second: '2-digit' });
      const date = new Date(o.createdAt).toLocaleDateString('vi-VN');
      logs.push({
        id: `ord_${o.id}`,
        time: `${time} ${date}`,
        timestamp: new Date(o.createdAt).getTime(),
        type: 'Đơn Hàng Gói',
        entity: o.orderCode,
        detail: `${o.description || 'Gói dịch vụ'} (${Number(o.totalAmount).toLocaleString('vi-VN')}đ) - ${o.customerName || o.customerPhone || 'Khách hàng'}`,
        status: o.status === 'PAID' ? 'SUCCESS' : 'PENDING',
        badge: o.status === 'PAID' ? 'Đã kích hoạt' : 'Chờ duyệt',
      });
    }

    logs.sort((a, b) => b.timestamp - a.timestamp);
    return logs.slice(0, 25);
  }

  async getOrders() {
    return this.prisma.order.findMany({
      where: { status: 'PAID' },
      orderBy: { createdAt: 'desc' },
      include: { transactions: true },
    });
  }

  async createOrder(dto: any) {
    let merchant = await this.prisma.merchant.findFirst();
    if (!merchant) {
      merchant = await this.prisma.merchant.create({
        data: {
          name: 'AutoBank Merchant Store',
          slug: 'autobank-merchant-' + Date.now(),
        },
      });
    }

    const orderCode = dto.orderCode || dto.code || 'ORD-' + Math.floor(100000 + Math.random() * 900000);
    const amount = Number(dto.amount || dto.totalAmount || 0);

    return this.prisma.order.upsert({
      where: { orderCode },
      update: {
        totalAmount: amount,
        paidAmount: dto.status === 'PAID' ? amount : 0,
        status: dto.status || 'PENDING',
        description: dto.pkg || dto.description || 'Gói dịch vụ',
        customerName: dto.customerName || dto.customer || '',
        customerPhone: dto.customerPhone || dto.phone || '',
      },
      create: {
        merchantId: merchant.id,
        orderCode,
        totalAmount: amount,
        paidAmount: dto.status === 'PAID' ? amount : 0,
        status: dto.status || 'PENDING',
        description: dto.pkg || dto.description || 'Gói dịch vụ',
        customerName: dto.customerName || dto.customer || '',
        customerPhone: dto.customerPhone || dto.phone || '',
      },
    });
  }

  async approveOrder(orderCodeOrId: string) {
    const order = await this.prisma.order.findFirst({
      where: {
        OR: [{ orderCode: orderCodeOrId }, { id: orderCodeOrId }],
      },
    });
    if (!order) return null;
    const updated = await this.prisma.order.update({
      where: { id: order.id },
      data: {
        status: 'PAID',
        paidAmount: order.totalAmount,
      },
    });

    if (order.customerName && order.customerName.includes('@')) {
      await this.extendUser(order.customerName, 365);
    }
    return updated;
  }

  async deleteOrder(orderCodeOrId: string) {
    const order = await this.prisma.order.findFirst({
      where: {
        OR: [{ orderCode: orderCodeOrId }, { id: orderCodeOrId }],
      },
    });
    if (!order) return null;
    return this.prisma.order.delete({
      where: { id: order.id },
    });
  }

  private currentLivePin: string = process.env.ADMIN_LIVE_PIN || '606060';
  private lastPhoneHeartbeat: {
    timestamp: number;
    deviceName: string;
    batteryLevel?: number;
    isListening: boolean;
    keepScreenOn: boolean;
    activePackage: string;
    voiceName: string;
    repeatCount: number;
    autoSpeechCredit: boolean;
    autoSpeechDebit: boolean;
    email?: string;
    userEmail?: string;
    shopName?: string;
  } | null = null; // Production: Starts with null until real device pings

  recordPhoneHeartbeat(dto: any) {
    if (!dto || !dto.deviceName) {
      throw new BadRequestException('Thông tin thiết bị không hợp lệ');
    }
    this.lastPhoneHeartbeat = {
      timestamp: Date.now(),
      deviceName: dto.deviceName,
      batteryLevel: typeof dto.batteryLevel === 'number' ? dto.batteryLevel : undefined,
      isListening: dto.isListening !== false,
      keepScreenOn: dto.keepScreenOn !== false,
      activePackage: dto.activePackage || 'Gói cước cơ bản',
      voiceName: dto.voiceName || 'Giọng đọc mặc định',
      repeatCount: dto.repeatCount || 1,
      autoSpeechCredit: dto.autoSpeechCredit !== false,
      autoSpeechDebit: dto.autoSpeechDebit === true,
      email: dto.email || dto.userEmail || undefined,
      userEmail: dto.userEmail || dto.email || undefined,
      shopName: dto.shopName || undefined,
    };
    return { success: true, serverTime: Date.now() };
  }

  getPhoneStatus() {
    const now = Date.now();
    // Phone considered online if heartbeat ping received within the last 35 seconds (app pings every 10s)
    const isOnline = this.lastPhoneHeartbeat != null && (now - this.lastPhoneHeartbeat.timestamp) < 35000;
    const diffSec = this.lastPhoneHeartbeat ? Math.round((now - this.lastPhoneHeartbeat.timestamp) / 1000) : null;

    return {
      isOnline,
      lastHeartbeat: this.lastPhoneHeartbeat,
      offlineSeconds: diffSec,
      instruction: isOnline
        ? 'Thiết bị điện thoại đang hoạt động nền 24/24 và kết nối tín hiệu ổn định.'
        : 'Đang không nhận được tín hiệu từ điện thoại. Vui lòng mở lại ứng dụng trên điện thoại để tránh bị gián đoạn nhận thông báo!',
    };
  }

  async getLivePin() {
    try {
      const config = await this.prisma.systemConfig.findUnique({
        where: { id: 'default' },
      });
      if (config && config.packagesJson) {
        try {
          const parsed = JSON.parse(config.packagesJson);
          if (parsed && parsed.livePin) {
            this.currentLivePin = parsed.livePin;
          }
        } catch (_) {}
      }
    } catch (_) {}
    return { pin: this.currentLivePin };
  }

  async setLivePin(pin: string, email?: string) {
    if (!pin || pin.trim().length < 4) {
      throw new BadRequestException('Mã PIN bảo vệ phải có ít nhất 4 ký tự!');
    }
    this.currentLivePin = pin.trim();
    const cleanEmail = (email || '').trim().toLowerCase();

    // 1. Cập nhật system_configs (livePin và liveWebPin)
    try {
      const config = await this.prisma.systemConfig.findUnique({
        where: { id: 'default' },
      });
      let parsed: any = {};
      if (config && config.packagesJson) {
        try {
          parsed = JSON.parse(config.packagesJson);
        } catch (_) {}
      }
      parsed.livePin = this.currentLivePin;
      parsed.liveWebPin = this.currentLivePin;
      if (config) {
        await this.prisma.systemConfig.update({
          where: { id: 'default' },
          data: { packagesJson: JSON.stringify(parsed) },
        });
      } else {
        await this.prisma.systemConfig.create({
          data: {
            id: 'default',
            brandName: 'Đọc thông báo nhận tiền',
            brandSlogan: 'Tiền vừa sang ~ máy báo vang',
            chplayLink: 'https://play.google.com/store/apps/details?id=com.docthongbaobank.app',
            packagesJson: JSON.stringify(parsed),
          } as any,
        });
      }
    } catch (e) {
      console.error('Failed to persist livePin to MySQL systemConfig:', e);
    }

    // 2. Nếu có email, cập nhật sharePin trực tiếp vào voiceSettingsJson của tài khoản
    if (cleanEmail && cleanEmail !== 'anonymous') {
      try {
        const rows: any[] = await this.prisma.$queryRawUnsafe(
          `SELECT voiceSettingsJson FROM app_device_users WHERE LOWER(email) = ? LIMIT 1`,
          cleanEmail,
        );
        let userCfg: any = {};
        if (rows && rows[0]?.voiceSettingsJson) {
          try {
            userCfg = JSON.parse(rows[0].voiceSettingsJson);
          } catch (_) {}
        }
        userCfg.sharePin = this.currentLivePin;
        userCfg.email = cleanEmail;
        userCfg.updatedAt = new Date().toISOString();
        const jsonStr = JSON.stringify(userCfg);

        await this.prisma.$executeRawUnsafe(
          `UPDATE app_device_users SET voiceSettingsJson = ?, updatedAt = NOW() WHERE LOWER(email) = ?`,
          jsonStr,
          cleanEmail,
        );
        await this.prisma.$executeRawUnsafe(
          `UPDATE users SET voiceSettingsJson = ?, updatedAt = NOW() WHERE LOWER(email) = ?`,
          jsonStr,
          cleanEmail,
        );
      } catch (err: any) {
        console.error('Error updating user sharePin in setLivePin:', err);
      }
    }

    return { success: true, pin: this.currentLivePin, email: cleanEmail || undefined };
  }

  async verifyLivePin(pin: string, email?: string) {
    await this.getLivePin();
    const cleanPin = (pin || '').trim();
    if (!cleanPin) return { isValid: false, message: 'Mã PIN không được để trống' };

    // 1. Nếu có email tài khoản được truyền lên, kiểm tra trực tiếp cấu hình của email đó
    if (email) {
      const cleanEmail = email.trim().toLowerCase();
      try {
        const rows: any[] = await this.prisma.$queryRawUnsafe(
          `SELECT voiceSettingsJson FROM app_device_users WHERE LOWER(email) = ? LIMIT 1`,
          cleanEmail,
        );
        if (rows && rows[0]?.voiceSettingsJson) {
          const cfg = JSON.parse(rows[0].voiceSettingsJson);
          if (cfg && cfg.sharePin && cleanPin === String(cfg.sharePin).trim()) {
            return { isValid: true, email: cleanEmail, message: 'Mã PIN chính xác' };
          }
        }
      } catch (_) {}

      try {
        const userRows: any[] = await this.prisma.$queryRawUnsafe(
          `SELECT voiceSettingsJson FROM users WHERE LOWER(email) = ? LIMIT 1`,
          cleanEmail,
        );
        if (userRows && userRows[0]?.voiceSettingsJson) {
          const cfg = JSON.parse(userRows[0].voiceSettingsJson);
          if (cfg && cfg.sharePin && cleanPin === String(cfg.sharePin).trim()) {
            return { isValid: true, email: cleanEmail, message: 'Mã PIN chính xác' };
          }
        }
      } catch (_) {}
    }

    // 2. Tìm kiếm trong CSDL xem mã PIN 6 số này có thuộc về tài khoản thiết bị nào không
    try {
      const matchApp: any[] = await this.prisma.$queryRawUnsafe(
        `SELECT email FROM app_device_users WHERE JSON_UNQUOTE(JSON_EXTRACT(voiceSettingsJson, '$.sharePin')) = ? OR voiceSettingsJson LIKE ? LIMIT 1`,
        cleanPin,
        `%"sharePin":%${cleanPin}%`,
      );
      if (matchApp && matchApp.length > 0 && matchApp[0].email) {
        return { isValid: true, email: matchApp[0].email, message: 'Mã PIN chính xác' };
      }
    } catch (_) {}

    try {
      const matchUser: any[] = await this.prisma.$queryRawUnsafe(
        `SELECT email FROM users WHERE JSON_UNQUOTE(JSON_EXTRACT(voiceSettingsJson, '$.sharePin')) = ? OR voiceSettingsJson LIKE ? LIMIT 1`,
        cleanPin,
        `%"sharePin":%${cleanPin}%`,
      );
      if (matchUser && matchUser.length > 0 && matchUser[0].email) {
        return { isValid: true, email: matchUser[0].email, message: 'Mã PIN chính xác' };
      }
    } catch (_) {}

    // 3. Khớp mã PIN hiện tại trong RAM hệ thống
    if (this.currentLivePin && cleanPin === this.currentLivePin) {
      let fallbackEmail = '';
      try {
        const latestUser: any[] = await this.prisma.$queryRawUnsafe(
          `SELECT email FROM users ORDER BY updatedAt DESC LIMIT 1`,
        );
        if (latestUser && latestUser[0]?.email) fallbackEmail = latestUser[0].email;
      } catch (_) {}
      return { isValid: true, email: fallbackEmail, message: 'Mã PIN chính xác' };
    }

    // 4. Khớp với mã cấu hình packagesJson (livePin hoặc liveWebPin)
    try {
      const config = await this.prisma.systemConfig.findUnique({
        where: { id: 'default' },
      });
      if (config && config.packagesJson) {
        const parsed = JSON.parse(config.packagesJson);
        if (
          (parsed.livePin && cleanPin === String(parsed.livePin).trim()) ||
          (parsed.liveWebPin && cleanPin === String(parsed.liveWebPin).trim())
        ) {
          let fallbackEmail = '';
          try {
            const latestUser: any[] = await this.prisma.$queryRawUnsafe(
              `SELECT email FROM users ORDER BY updatedAt DESC LIMIT 1`,
            );
            if (latestUser && latestUser[0]?.email) fallbackEmail = latestUser[0].email;
          } catch (_) {}
          return { isValid: true, email: fallbackEmail, message: 'Mã PIN chính xác' };
        }
      }
    } catch (_) {}

    return { isValid: false, message: 'Mã bảo mật 6 số không đúng' };
  }

  async getPushes() {
    return this.prisma.pushBroadcast.findMany({
      orderBy: { createdAt: 'desc' },
    });
  }

  async sendPush(dto: any) {
    return this.prisma.pushBroadcast.create({
      data: {
        type: dto.type || 'system_update',
        title: dto.title,
        body: dto.body,
        action: dto.action || 'open_app',
      },
    });
  }

  async updatePush(id: string, dto: any) {
    return this.prisma.pushBroadcast.update({
      where: { id },
      data: {
        type: dto.type,
        title: dto.title,
        body: dto.body,
        action: dto.action,
      },
    });
  }

  async deletePush(id: string) {
    return this.prisma.pushBroadcast.delete({
      where: { id },
    });
  }

  // --- COUPONS MARKETING ---
  async getCoupons() {
    return this.prisma.discountCoupon.findMany({
      orderBy: { createdAt: 'desc' },
    });
  }

  async saveCoupon(dto: any) {
    const code = (dto.code || '').trim().toUpperCase();
    if (!code) throw new BadRequestException('Mã giảm giá không được để trống.');
    const targetAudience = dto.targetAudience || 'ALL';
    const autoApply = dto.autoApply !== undefined ? Boolean(dto.autoApply) : true;
    return this.prisma.discountCoupon.upsert({
      where: { code },
      update: {
        description: dto.description || 'Ưu đãi giảm giá đặc biệt',
        discountPercent: Number(dto.discountPercent || 0),
        discountAmount: Number(dto.discountAmount || 0),
        minPrice: Number(dto.minPrice || 0),
        targetAudience,
        autoApply,
        isActive: dto.isActive !== undefined ? Boolean(dto.isActive) : true,
      },
      create: {
        code,
        description: dto.description || 'Ưu đãi giảm giá đặc biệt',
        discountPercent: Number(dto.discountPercent || 0),
        discountAmount: Number(dto.discountAmount || 0),
        minPrice: Number(dto.minPrice || 0),
        targetAudience,
        autoApply,
        isActive: dto.isActive !== undefined ? Boolean(dto.isActive) : true,
      },
    });
  }

  async toggleCoupon(idOrCode: string) {
    const coupon = await this.prisma.discountCoupon.findFirst({
      where: {
        OR: [{ id: idOrCode }, { code: idOrCode }],
      },
    });
    if (!coupon) throw new BadRequestException('Không tìm thấy mã giảm giá.');
    return this.prisma.discountCoupon.update({
      where: { id: coupon.id },
      data: { isActive: !coupon.isActive },
    });
  }

  async deleteCoupon(idOrCode: string) {
    const coupon = await this.prisma.discountCoupon.findFirst({
      where: {
        OR: [{ id: idOrCode }, { code: idOrCode }],
      },
    });
    if (!coupon) throw new BadRequestException('Không tìm thấy mã giảm giá.');
    return this.prisma.discountCoupon.delete({
      where: { id: coupon.id },
    });
  }

  async validateCoupon(code: string, amount: number, userEmail?: string) {
    const cleanCode = (code || '').trim().toUpperCase();
    if (!cleanCode) {
      throw new BadRequestException('Vui lòng nhập mã giảm giá.');
    }
    const coupon = await this.prisma.discountCoupon.findUnique({
      where: { code: cleanCode },
    });
    if (!coupon || !coupon.isActive) {
      throw new BadRequestException('Mã giảm giá không hợp lệ hoặc đã hết hạn.');
    }

    // Kiểm tra điều kiện dành cho người mới theo số ngày (1 ngày, 2 ngày, 3 ngày)
    if (userEmail && (coupon.targetAudience === 'NEW_1DAY' || coupon.targetAudience === 'NEW_2DAYS' || coupon.targetAudience === 'NEW_3DAYS')) {
      const user = await this.prisma.appDeviceUser.findUnique({ where: { email: userEmail } });
      if (user) {
        const daysSinceJoin = (Date.now() - new Date(user.createdAt).getTime()) / (1000 * 3600 * 24);
        let maxDays = 3.0;
        if (coupon.targetAudience === 'NEW_1DAY') maxDays = 1.0;
        if (coupon.targetAudience === 'NEW_2DAYS') maxDays = 2.0;
        if (coupon.targetAudience === 'NEW_3DAYS') maxDays = 3.0;
        if (daysSinceJoin > maxDays) {
          throw new BadRequestException(`Mã giảm giá này chỉ áp dụng cho tài khoản mới tạo trong vòng ${maxDays * 24} giờ (${maxDays} ngày) đầu!`);
        }
      }
    }

    if (coupon.minPrice > 0 && amount < coupon.minPrice) {
      throw new BadRequestException(`Đơn hàng phải từ ${Number(coupon.minPrice).toLocaleString('vi-VN')}đ mới được áp dụng mã này.`);
    }

    let discount = 0;
    if (coupon.discountPercent > 0) {
      discount = Math.round((amount * coupon.discountPercent) / 100);
    } else if (coupon.discountAmount > 0) {
      discount = coupon.discountAmount;
    }
    if (discount > amount) discount = amount;
    return {
      valid: true,
      code: coupon.code,
      description: coupon.description,
      discount,
      targetAudience: coupon.targetAudience,
      autoApply: coupon.autoApply,
      finalAmount: Math.max(0, amount - discount),
    };
  }

  async getActiveDiscounts(userEmail?: string) {
    const activeCoupons = await this.prisma.discountCoupon.findMany({
      where: { isActive: true },
      orderBy: { discountPercent: 'desc' },
    });

    let daysSinceJoin: number | null = null;
    if (userEmail) {
      const user = await this.prisma.appDeviceUser.findUnique({ where: { email: userEmail } });
      if (user) {
        daysSinceJoin = (Date.now() - new Date(user.createdAt).getTime()) / (1000 * 3600 * 24);
      }
    }

    return activeCoupons.filter(c => {
      if (daysSinceJoin !== null) {
        if (c.targetAudience === 'NEW_1DAY' && daysSinceJoin > 1.0) return false;
        if (c.targetAudience === 'NEW_2DAYS' && daysSinceJoin > 2.0) return false;
        if (c.targetAudience === 'NEW_3DAYS' && daysSinceJoin > 3.0) return false;
      }
      return true;
    });
  }

  // --- 1 TÀI KHOẢN LIÊN KẾT 1 ĐIỆN THOẠI DUY NHẤT ---
  async bindDevice(dto: { email: string; deviceId: string; deviceName?: string; phone?: string; shopName?: string; forceSwitch?: boolean }) {
    const { email, deviceId, deviceName, phone, shopName, forceSwitch } = dto;
    const user = await this.prisma.appDeviceUser.findUnique({ where: { email } });

    if (!user) {
      return this.prisma.appDeviceUser.create({
        data: {
          name: email.split('@')[0],
          email,
          device: deviceName || 'Thiết bị di động',
          deviceId,
          phone,
          shopName,
          packagePlan: 'Dùng thử 3 ngày',
          expiresAt: new Date(Date.now() + 3 * 86400000),
          status: 'ACTIVE',
        },
      });
    }

    return this.prisma.appDeviceUser.update({
      where: { email },
      data: {
        deviceId,
        device: deviceName || user.device,
        phone: phone || user.phone,
        shopName: shopName || user.shopName,
      },
    });
  }

  async unbindDevice(email: string) {
    return this.prisma.appDeviceUser.update({
      where: { email },
      data: { deviceId: null },
    });
  }

  // --- API KEYS & SERVER KEYS (MYSQL PERSISTENCE) ---
  async getApiKeys() {
    return (this.prisma as any).apiKey.findMany({
      orderBy: { createdAt: 'desc' },
    });
  }

  async saveApiKey(dto: any) {
    const { name, key, role, status } = dto;
    const existing = await (this.prisma as any).apiKey.findUnique({
      where: { key },
    });
    if (existing) {
      return (this.prisma as any).apiKey.update({
        where: { key },
        data: {
          name: name || existing.name,
          role: role || existing.role,
          status: status || existing.status,
        },
      });
    }
    return (this.prisma as any).apiKey.create({
      data: {
        name,
        key,
        role: role || 'FULL',
        status: status || 'ACTIVE',
      },
    });
  }

  async deleteApiKey(idOrKey: string) {
    try {
      return await (this.prisma as any).apiKey.delete({
        where: { key: idOrKey },
      });
    } catch (_) {
      return await (this.prisma as any).apiKey.delete({
        where: { id: idOrKey },
      });
    }
  }

  async getServerKeys() {
    const cfg = await this.prisma.systemConfig.findUnique({
      where: { id: 'default' },
    });
    return {
      masterKey: cfg?.masterApiKey || 'ak_live_master_autobank_secret_key_2026',
      fcmKey: cfg?.fcmServerKey || '',
      webhookUrl: cfg?.webhookEndpoint || 'http://localhost:3000/transactions/webhook',
    };
  }

  async updateServerKeys(dto: { masterKey?: string; fcmKey?: string; webhookUrl?: string }) {
    return this.prisma.systemConfig.upsert({
      where: { id: 'default' },
      update: {
        masterApiKey: dto.masterKey,
        fcmServerKey: dto.fcmKey,
        webhookEndpoint: dto.webhookUrl,
      },
      create: {
        id: 'default',
        brandName: 'Đọc thông báo nhận tiền',
        brandSlogan: 'Tiền vừa sang ~ máy báo vang',
        chplayLink: '',
        youtubeLink: '',
        masterApiKey: dto.masterKey,
        fcmServerKey: dto.fcmKey,
        webhookEndpoint: dto.webhookUrl,
      },
    });
  }

  /**
   * Quét và gửi email thông báo sắp hết hạn dùng thử (còn dưới 24h hoặc vừa hết hạn)
   * và tặng mã NGUOIMOI giảm 10%
   */
  async sendTrialExpiryReminders() {
    const now = new Date();
    // Các tài khoản có expiresAt trong khoảng từ -12h đến +24h
    const in24h = new Date(now.getTime() + 24 * 60 * 60 * 1000);
    const past12h = new Date(now.getTime() - 12 * 60 * 60 * 1000);

    const candidates = await this.prisma.appDeviceUser.findMany({
      where: {
        expiresAt: {
          gte: past12h,
          lte: in24h,
        },
        OR: [
          { packagePlan: { contains: 'dùng thử' } },
          { packagePlan: { contains: 'Dùng thử' } },
          { packagePlan: { contains: 'trial' } },
          { hasUsedTrial: true },
        ],
      },
    });

    const results = [];
    for (const user of candidates) {
      if (!user.email || !user.email.includes('@')) continue;
      const hoursLeft = (new Date(user.expiresAt).getTime() - now.getTime()) / (1000 * 3600);
      try {
        const sent = await this.mailService.sendTrialExpiringEmail(user.email, {
          hoursLeft: Math.max(1, Math.round(hoursLeft)),
          expiresAt: new Date(user.expiresAt),
          couponCode: 'NGUOIMOI',
          discountPercent: 10,
        });
        results.push({ email: user.email, sent, hoursLeft: Math.round(hoursLeft) });
      } catch (err: any) {
        results.push({ email: user.email, sent: false, error: err.message });
      }
    }
    return { count: results.length, details: results };
  }

  // ==========================================
  // QUẢN LÝ GIỚI THIỆU BẠN BÈ & LỊCH SỬ RÚT TIỀN
  // ==========================================

  private getAffiliateFilePath(): string {
    const dataDir = path.resolve(process.cwd(), 'data');
    if (!fs.existsSync(dataDir)) {
      try {
        fs.mkdirSync(dataDir, { recursive: true });
      } catch (_) {}
    }
    return path.join(dataDir, 'affiliate.json');
  }

  private readAffiliateData(): {
    withdrawals: any[];
    referrals: any[];
    userBalances: Record<string, { available: number; totalEarned: number; invitedCount: number }>;
  } {
    const filePath = this.getAffiliateFilePath();
    if (fs.existsSync(filePath)) {
      try {
        const content = fs.readFileSync(filePath, 'utf-8');
        const parsed = JSON.parse(content);
        return {
          withdrawals: Array.isArray(parsed.withdrawals) ? parsed.withdrawals : [],
          referrals: Array.isArray(parsed.referrals) ? parsed.referrals : [],
          userBalances: parsed.userBalances && typeof parsed.userBalances === 'object' ? parsed.userBalances : {},
        };
      } catch (_) {}
    }

    // Dữ liệu mẫu chuẩn bị sẵn chuyên nghiệp
    const defaultData = {
      withdrawals: [
        {
          id: 'WD_1730001',
          referralCode: '688219',
          userEmail: 'quocvu.merchant@gmail.com',
          bankName: 'MBBank',
          accountNumber: '3011200588888',
          accountHolder: 'TRẦN QUỐC VŨ',
          amount: 500000,
          status: 'PENDING',
          rejectReason: '',
          date: '23/10/2026 14:30',
          createdAt: new Date(Date.now() - 3600000 * 5).toISOString(),
        },
        {
          id: 'WD_1730002',
          referralCode: '912384',
          userEmail: 'minhnguyen.coffee@gmail.com',
          bankName: 'Techcombank',
          accountNumber: '190382910398',
          accountHolder: 'NGUYỄN VĂN MINH',
          amount: 250000,
          status: 'APPROVED',
          rejectReason: '',
          date: '22/10/2026 09:15',
          createdAt: new Date(Date.now() - 86400000).toISOString(),
          processedAt: new Date(Date.now() - 82800000).toISOString(),
        },
        {
          id: 'WD_1730003',
          referralCode: '349182',
          userEmail: 'spamanh@gmail.com',
          bankName: 'Vietcombank',
          accountNumber: '0071000889912',
          accountHolder: 'LÊ THỊ ANH',
          amount: 200000,
          status: 'REJECTED',
          rejectReason: 'Sai số tài khoản nhận tiền tại Vietcombank, đã hoàn lại 200.000₫ về số dư',
          date: '21/10/2026 16:40',
          createdAt: new Date(Date.now() - 86400000 * 2).toISOString(),
          processedAt: new Date(Date.now() - 86400000 * 2 + 1800000).toISOString(),
        },
      ],
      referrals: [
        {
          id: 'REF_173001',
          referrerCode: '688219',
          referrerEmail: 'quocvu.merchant@gmail.com',
          invitedEmail: 'tiembanh.mai@gmail.com',
          invitedName: 'Tiệm Bánh Mơ Màng',
          packageName: '1 Năm (tặng 2T)',
          commissionAmount: 75000,
          date: '23/10/2026 11:20',
          createdAt: new Date(Date.now() - 3600000 * 8).toISOString(),
        },
        {
          id: 'REF_173002',
          referrerCode: '912384',
          referrerEmail: 'minhnguyen.coffee@gmail.com',
          invitedEmail: 'taphoahuong@gmail.com',
          invitedName: 'Tạp Hóa Cô Hương',
          packageName: '6 Tháng',
          commissionAmount: 45000,
          date: '22/10/2026 18:05',
          createdAt: new Date(Date.now() - 86400000).toISOString(),
        },
        {
          id: 'REF_173003',
          referrerCode: '688219',
          referrerEmail: 'quocvu.merchant@gmail.com',
          invitedEmail: 'nhahangbien@gmail.com',
          invitedName: 'Nhà Hàng Biển Xanh',
          packageName: 'Gói Vĩnh Viễn Trọn Đời',
          commissionAmount: 120000,
          date: '21/10/2026 15:30',
          createdAt: new Date(Date.now() - 86400000 * 2).toISOString(),
        },
        {
          id: 'REF_173004',
          referrerCode: '773210',
          referrerEmail: 'hoa.salon@gmail.com',
          invitedEmail: 'phothin@gmail.com',
          invitedName: 'Phở Thìn Hà Nội',
          packageName: '3 Tháng',
          commissionAmount: 25000,
          date: '20/10/2026 10:10',
          createdAt: new Date(Date.now() - 86400000 * 3).toISOString(),
        },
      ],
      userBalances: {
        '688219': { available: 195000, totalEarned: 695000, invitedCount: 8 },
        '912384': { available: 120000, totalEarned: 370000, invitedCount: 5 },
        '773210': { available: 195000, totalEarned: 195000, invitedCount: 3 },
      },
    };

    try {
      fs.writeFileSync(filePath, JSON.stringify(defaultData, null, 2), 'utf-8');
    } catch (_) {}
    return defaultData;
  }

  private writeAffiliateData(data: any) {
    try {
      const filePath = this.getAffiliateFilePath();
      fs.writeFileSync(filePath, JSON.stringify(data, null, 2), 'utf-8');
    } catch (e: any) {
      this.logger.error(`Không thể ghi affiliate.json: ${e.message}`);
    }
  }

  async getAffiliateOverview() {
    const data = this.readAffiliateData();
    const config = await this.getConfig();

    let totalCommissionPaid = 0;
    let pendingWithdrawalAmount = 0;
    let pendingCount = 0;

    for (const w of data.withdrawals) {
      if (w.status === 'APPROVED') {
        totalCommissionPaid += Number(w.amount || 0);
      } else if (w.status === 'PENDING' || w.status === 'Chờ duyệt') {
        pendingWithdrawalAmount += Number(w.amount || 0);
        pendingCount += 1;
      }
    }

    // Tính Top 3 người giới thiệu xuất sắc nhất
    const referrersMap: Record<string, { code: string; email: string; name: string; count: number; totalEarned: number }> = {};
    for (const ref of data.referrals) {
      const key = ref.referrerCode || ref.referrerEmail || 'unknown';
      if (!referrersMap[key]) {
        referrersMap[key] = {
          code: ref.referrerCode || '000000',
          email: ref.referrerEmail || 'Người dùng',
          name: ref.referrerEmail ? ref.referrerEmail.split('@')[0] : 'Đại lý',
          count: 0,
          totalEarned: 0,
        };
      }
      referrersMap[key].count += 1;
      referrersMap[key].totalEarned += Number(ref.commissionAmount || 0);
    }

    // Bổ sung dữ liệu từ userBalances
    for (const [code, stat] of Object.entries(data.userBalances)) {
      if (!referrersMap[code]) {
        referrersMap[code] = {
          code,
          email: `user_${code}@autobank.vn`,
          name: `Đại lý #${code}`,
          count: stat.invitedCount || 0,
          totalEarned: stat.totalEarned || 0,
        };
      } else {
        if (stat.totalEarned > referrersMap[code].totalEarned) {
          referrersMap[code].totalEarned = stat.totalEarned;
        }
        if (stat.invitedCount > referrersMap[code].count) {
          referrersMap[code].count = stat.invitedCount;
        }
      }
    }

    const sortedReferrers = Object.values(referrersMap).sort((a, b) => {
      if (b.count !== a.count) return b.count - a.count;
      return b.totalEarned - a.totalEarned;
    });

    const top3 = sortedReferrers.slice(0, 3).map((u, idx) => ({
      rank: idx + 1,
      medal: idx === 0 ? '🥇 Vàng' : idx === 1 ? '🥈 Bạc' : '🥉 Đồng',
      ...u,
    }));

    return {
      stats: {
        totalCommissionPaid,
        pendingWithdrawalAmount,
        totalReferralsCount: data.referrals.length,
        pendingWithdrawalsCount: pendingCount,
      },
      top3,
      withdrawals: data.withdrawals,
      referrals: data.referrals,
      affiliateRewards: config?.affiliateRewards || [],
    };
  }

  async approveWithdrawal(id: string) {
    const data = this.readAffiliateData();
    const item = data.withdrawals.find((w: any) => w.id === id);
    if (!item) {
      throw new BadRequestException('Không tìm thấy lệnh rút tiền với ID này.');
    }
    item.status = 'APPROVED';
    item.processedAt = new Date().toISOString();
    this.writeAffiliateData(data);
    return { success: true, message: `Đã duyệt thành công lệnh rút tiền #${id}`, item };
  }

  async rejectWithdrawal(id: string, reason?: string) {
    const data = this.readAffiliateData();
    const item = data.withdrawals.find((w: any) => w.id === id);
    if (!item) {
      throw new BadRequestException('Không tìm thấy lệnh rút tiền với ID này.');
    }
    item.status = 'REJECTED';
    item.rejectReason = reason || 'Thông tin tài khoản ngân hàng không chính xác';
    item.processedAt = new Date().toISOString();

    // Hoàn tiền lại số dư cho người dùng
    const code = item.referralCode;
    if (code && data.userBalances[code]) {
      data.userBalances[code].available = (data.userBalances[code].available || 0) + Number(item.amount || 0);
    }

    this.writeAffiliateData(data);
    return { success: true, message: `Đã từ chối lệnh rút tiền #${id}. Số dư đã được hoàn trả.`, item };
  }

  async recordWithdrawalRequest(dto: any) {
    const data = this.readAffiliateData();
    const now = new Date();
    const d = String(now.getDate()).padStart(2, '0');
    const m = String(now.getMonth() + 1).padStart(2, '0');
    const y = now.getFullYear();
    const h = String(now.getHours()).padStart(2, '0');
    const min = String(now.getMinutes()).padStart(2, '0');
    const dateStr = `${d}/${m}/${y} ${h}:${min}`;

    const newWithdrawal = {
      id: dto.withdrawalId || `WD_${Date.now()}`,
      referralCode: dto.referralCode || '000000',
      userEmail: dto.userEmail || dto.email || `user_${dto.referralCode}@autobank.vn`,
      bankName: dto.bankName || 'Ngân hàng',
      accountNumber: dto.accountNumber || '',
      accountHolder: (dto.accountHolder || '').toUpperCase(),
      amount: Number(dto.amount || 0),
      status: 'PENDING',
      rejectReason: '',
      date: dto.date || dateStr,
      createdAt: now.toISOString(),
    };

    data.withdrawals.unshift(newWithdrawal);
    this.writeAffiliateData(data);
    return { success: true, message: 'Đã tiếp nhận yêu cầu rút tiền thành công', withdrawal: newWithdrawal };
  }

  async recordReferralBind(dto: any) {
    const data = this.readAffiliateData();
    const refCode = dto.referredByCode;
    if (refCode && refCode.length === 6) {
      if (!data.userBalances[refCode]) {
        data.userBalances[refCode] = { available: 0, totalEarned: 0, invitedCount: 1 };
      } else {
        data.userBalances[refCode].invitedCount = (data.userBalances[refCode].invitedCount || 0) + 1;
      }
      this.writeAffiliateData(data);
    }
    return { success: true };
  }

  async getAffiliateStats(code?: string, email?: string) {
    const data = this.readAffiliateData();
    const key = code || '';
    const userStat = (key && data.userBalances[key]) ? data.userBalances[key] : { available: 0, totalEarned: 0, invitedCount: 0 };
    return {
      availableBalance: userStat.available,
      totalEarned: userStat.totalEarned,
      invitedCount: userStat.invitedCount,
      withdrawals: data.withdrawals.filter((w: any) => w.referralCode === code || (email && w.userEmail === email)),
      referrals: data.referrals.filter((r: any) => r.referrerCode === code || (email && r.referrerEmail === email)),
    };
  }
}


