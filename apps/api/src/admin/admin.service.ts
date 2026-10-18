import { Injectable, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service.js';

@Injectable()
export class AdminService {
  constructor(private readonly prisma: PrismaService) {}

  async getConfig() {
    const config = await this.prisma.systemConfig.findUnique({
      where: { id: 'default' },
    });
    if (!config) return null;
    let parsedPackages = [];
    if (config.packagesJson) {
      try {
        parsedPackages = JSON.parse(config.packagesJson);
      } catch (_) {}
    }
    return {
      ...config,
      packages: parsedPackages,
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
    if (dto.packages !== undefined) {
      data.packagesJson = typeof dto.packages === 'string' ? dto.packages : JSON.stringify(dto.packages);
    }
    const defaultCreate = {
      id: 'default',
      brandName: 'Đọc thông báo nhận tiền',
      brandSlogan: 'Tiền vừa sang ~ máy báo vang',
      chplayLink: 'https://play.google.com/store/apps/details?id=com.dtappbaochuyentien.vn',
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
      serverDomain: 'http://192.168.1.217:3000',
      webDomain: 'http://192.168.1.217:5173',
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
      `, user.name, user.email, user.phone || null, user.shopName || null, user.packagePlan || '1 Năm', user.status || 'ACTIVE', user.device || 'Thiết bị di động', user.version || '1.2.0', user.deviceId || null, user.expiresAt ? new Date(user.expiresAt) : null);
    } catch (_) {}
  }

  async upsertUser(dto: any) {
    const isTrial = (dto.packagePlan || '').toLowerCase().includes('dùng thử') || (dto.packagePlan || '').toLowerCase().includes('trial');
    const existing = await this.prisma.appDeviceUser.findUnique({ where: { email: dto.email } });

    let result;
    if (existing) {
      // Nếu tài khoản đã tồn tại và đang có gói trả phí, giữ nguyên gói cước và hạn dùng từ MySQL
      const hasPaidPlan = existing.packagePlan && !existing.packagePlan.toLowerCase().includes('dùng thử');
      const isNewTrialRequest = isTrial && !dto.forceUpdate;

      const targetPackagePlan = (hasPaidPlan && isNewTrialRequest) 
        ? existing.packagePlan 
        : (dto.packagePlan || existing.packagePlan);

      let targetExpiresAt = (hasPaidPlan && isNewTrialRequest && new Date(existing.expiresAt) > new Date())
        ? existing.expiresAt
        : (dto.expiresAt ? new Date(dto.expiresAt) : existing.expiresAt);

      if ((dto.status === 'EXPIRED' || dto.status === 'BLOCKED') && targetExpiresAt >= new Date()) {
        targetExpiresAt = new Date(Date.now() - 86400000);
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
    const updated = await this.prisma.appDeviceUser.update({
      where: { id: user.id },
      data: { expiresAt: current, status: 'ACTIVE' },
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

  async setLivePin(pin: string) {
    if (!pin || pin.trim().length < 4) {
      throw new BadRequestException('Mã PIN bảo vệ phải có ít nhất 4 ký tự!');
    }
    this.currentLivePin = pin.trim();
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
            chplayLink: 'https://play.google.com/store/apps/details?id=com.dtappbaochuyentien.vn',
            packagesJson: JSON.stringify(parsed),
          } as any,
        });
      }
    } catch (e) {
      console.error('Failed to persist livePin to MySQL systemConfig:', e);
    }
    return { success: true, pin: this.currentLivePin };
  }

  async verifyLivePin(pin: string, email?: string) {
    await this.getLivePin();
    const cleanPin = (pin || '').trim();
    if (!cleanPin) return { isValid: false, message: 'Mã PIN không được để trống' };

    // 1. Khớp mã PIN hiện tại trong hệ thống (đã đồng bộ từ điện thoại hoặc cấu hình)
    if (this.currentLivePin && cleanPin === this.currentLivePin) {
      return { isValid: true, message: 'Mã PIN chính xác' };
    }

    // 2. Chấp nhận các mã mặc định phổ biến (889922 từ App Mobile, 606060 từ Web Admin)
    if (cleanPin === '889922' || cleanPin === '606060') {
      return { isValid: true, message: 'Mã PIN chính xác' };
    }

    // 3. Nếu có email tài khoản, kiểm tra mã PIN trong cấu hình của tài khoản đó trong SQL
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

    // 4. Nếu không có email (dùng link chia sẻ sạch /live không đính kèm gmail)
    // Kiểm tra xem mã PIN này có khớp với bất kỳ tài khoản thiết bị nào đã lưu trong cơ sở dữ liệu không
    try {
      const matchApp: any[] = await this.prisma.$queryRawUnsafe(
        `SELECT email FROM app_device_users WHERE voiceSettingsJson LIKE ? LIMIT 1`,
        `%"sharePin":"${cleanPin}"%`,
      );
      if (matchApp && matchApp.length > 0) {
        return { isValid: true, email: matchApp[0].email, message: 'Mã PIN chính xác' };
      }
    } catch (_) {}

    try {
      const matchUser: any[] = await this.prisma.$queryRawUnsafe(
        `SELECT email FROM users WHERE voiceSettingsJson LIKE ? LIMIT 1`,
        `%"sharePin":"${cleanPin}"%`,
      );
      if (matchUser && matchUser.length > 0) {
        return { isValid: true, email: matchUser[0].email, message: 'Mã PIN chính xác' };
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

    if (user.deviceId && user.deviceId !== deviceId && !forceSwitch) {
      return {
        conflict: true,
        message: `Tài khoản này đang liên kết với thiết bị (${user.device}). Bạn có muốn hủy liên kết trên máy cũ để chuyển sang máy này?`,
        boundDevice: user.device,
        user,
      };
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
}

