import { Injectable, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service.js';

@Injectable()
export class AdminService {
  constructor(private readonly prisma: PrismaService) {}

  async getConfig() {
    return this.prisma.systemConfig.findUnique({
      where: { id: 'default' },
    });
  }

  async updateConfig(dto: any) {
    const allowed = [
      'brandName', 'brandSlogan', 'chplayLink', 'youtubeLink', 'hotline',
      'email', 'facebook', 'tiktok', 'bankCode', 'bankAcc', 'bankName',
      'priceTrial', 'price1m', 'price3m', 'price6m', 'price9m', 'price1y',
      'priceLifetime', 'bonusMonths1y', 'marketingBanner',
      'maintenance', 'maintenanceMsg', 'latestVersion', 'minVersion',
    ];
    const data: any = {};
    for (const key of allowed) {
      if (dto[key] !== undefined) {
        if (key.startsWith('price') && key !== 'priceTrial') {
          data[key] = parseInt(String(dto[key]).replace(/\D/g, ''), 10) || 0;
        } else if (key === 'bonusMonths1y') {
          data[key] = parseInt(String(dto[key]).replace(/\D/g, ''), 10) || 0;
        } else if (key === 'maintenance') {
          data[key] = Boolean(dto[key]);
        } else {
          data[key] = dto[key];
        }
      }
    }
    const defaultCreate = {
      id: 'default',
      brandName: 'Đọc thông báo nhận tiền',
      brandSlogan: 'Tiền vừa sang ~ máy báo vang',
      chplayLink: 'https://play.google.com/store/apps/details?id=com.dtappbaochuyentien.vn',
      youtubeLink: 'https://www.youtube.com/@vudev05',
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
    return this.prisma.bankApp.upsert({
      where: { id: dto.id || dto.pkg },
      update: dto,
      create: dto,
    });
  }

  async deleteBank(id: string) {
    return this.prisma.bankApp.delete({
      where: { id },
    });
  }

  async upsertUser(dto: any) {
    const isTrial = (dto.packagePlan || '').toLowerCase().includes('dùng thử') || (dto.packagePlan || '').toLowerCase().includes('trial');
    const existing = await this.prisma.appDeviceUser.findUnique({ where: { email: dto.email } });

    if (isTrial && existing?.hasUsedTrial) {
      throw new BadRequestException('Mỗi tài khoản Google chỉ được dùng thử 1 lần duy nhất! Vui lòng chọn mua gói cước.');
    }

    const expiresAt = dto.expiresAt ? new Date(dto.expiresAt) : new Date(Date.now() + 3 * 86400000);
    const hasUsedTrial = Boolean(existing?.hasUsedTrial || isTrial || dto.hasUsedTrial);

    return this.prisma.appDeviceUser.upsert({
      where: { email: dto.email },
      update: {
        name: dto.name,
        device: dto.device || 'Android',
        version: dto.version || '1.2.0',
        packagePlan: dto.packagePlan || 'Dùng thử 3 ngày',
        hasUsedTrial: hasUsedTrial,
        expiresAt: expiresAt,
        status: dto.status || 'ACTIVE',
      },
      create: {
        name: dto.name,
        email: dto.email,
        device: dto.device || 'Android',
        version: dto.version || '1.2.0',
        packagePlan: dto.packagePlan || 'Dùng thử 3 ngày',
        hasUsedTrial: hasUsedTrial,
        expiresAt: expiresAt,
        status: dto.status || 'ACTIVE',
      },
    });
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

  async extendUser(email: string, days: number) {
    const user = await this.prisma.appDeviceUser.findUnique({ where: { email } });
    if (!user) return null;
    const current = new Date(user.expiresAt) > new Date() ? new Date(user.expiresAt) : new Date();
    current.setDate(current.getDate() + days);
    return this.prisma.appDeviceUser.update({
      where: { email },
      data: { expiresAt: current, status: 'ACTIVE' },
    });
  }

  async toggleBlockUser(email: string) {
    const user = await this.prisma.appDeviceUser.findUnique({ where: { email } });
    if (!user) return null;
    const nextStatus = user.status === 'BLOCKED' ? 'ACTIVE' : 'BLOCKED';
    return this.prisma.appDeviceUser.update({
      where: { email },
      data: { status: nextStatus },
    });
  }

  async deleteUser(email: string) {
    return this.prisma.appDeviceUser.delete({
      where: { email },
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
        totalCount: orders.length,
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

  async approveOrder(orderCode: string) {
    const order = await this.prisma.order.findUnique({ where: { orderCode } });
    if (!order) return null;
    const updated = await this.prisma.order.update({
      where: { orderCode },
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

  async deleteOrder(orderCode: string) {
    return this.prisma.order.delete({
      where: { orderCode },
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
    };
    return { success: true, serverTime: Date.now() };
  }

  getPhoneStatus() {
    const now = Date.now();
    // Phone considered online if heartbeat ping received within the last 120 seconds
    const isOnline = this.lastPhoneHeartbeat != null && (now - this.lastPhoneHeartbeat.timestamp) < 120000;
    const diffSec = this.lastPhoneHeartbeat ? Math.round((now - this.lastPhoneHeartbeat.timestamp) / 1000) : null;

    return {
      isOnline,
      lastHeartbeat: this.lastPhoneHeartbeat,
      offlineSeconds: diffSec,
      instruction: isOnline
        ? 'Thiết bị điện thoại đang hoạt động nền 24/24 và kết nối tín hiệu ổn định.'
        : 'Không nhận được tín hiệu hoạt động của điện thoại. Vui lòng mở ứng dụng trên điện thoại, thiết lập màn hình chờ không tắt và duy trì chế độ chạy nền 24/24!',
    };
  }

  getLivePin() {
    return { pin: this.currentLivePin };
  }

  setLivePin(pin: string) {
    if (!pin || pin.trim().length < 4) {
      throw new BadRequestException('Mã PIN bảo vệ phải có ít nhất 4 ký tự!');
    }
    this.currentLivePin = pin.trim();
    return { success: true, pin: this.currentLivePin };
  }

  verifyLivePin(pin: string) {
    const isValid = Boolean(pin && pin === this.currentLivePin);
    return { isValid };
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

  // --- COUPONS MARKETING ---
  async getCoupons() {
    return this.prisma.discountCoupon.findMany({
      where: { isActive: true },
      orderBy: { createdAt: 'desc' },
    });
  }

  async validateCoupon(code: string, amount: number) {
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
      finalAmount: Math.max(0, amount - discount),
    };
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
}
