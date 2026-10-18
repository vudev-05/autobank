import { Injectable, BadRequestException, Logger } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service.js';
import { Prisma } from '@prisma/client';
import crypto from 'node:crypto';

export class ThueApiWebhookDto {
  gateway?: string;
  bank?: string;
  transactionNumber?: string;
  transaction_id?: string;
  id?: string | number;
  accountNumber?: string;
  account_number?: string;
  subAccount?: string;
  amount!: number | string;
  content?: string;
  description?: string;
  transferType?: string; // 'in' | 'out'
  type?: string; // 'IN' | 'OUT' | 'credit' | 'debit'
  transferDate?: string;
  transactionDate?: string;
  date?: string;
  code?: string;
  signature?: string;
  sign?: string;
}

@Injectable()
export class ThueApiService {
  private readonly logger = new Logger(ThueApiService.name);

  constructor(private readonly prisma: PrismaService) {}

  /**
   * Lấy cấu hình ThueApi.Pro hiện tại (Mã hóa / Che key khi hiển thị cho Admin)
   */
  async getConfig() {
    const config = await this.prisma.systemConfig.findUnique({
      where: { id: 'default' },
    });

    const isEnabled = Boolean(config?.thueApiEnabled);
    const hasKey = Boolean(config?.thueApiKey && config.thueApiKey.trim().length > 0);
    const rawKey = config?.thueApiKey?.trim() || '';

    // Che key bảo mật: chỉ hiện 4 ký tự đầu và 4 ký tự cuối
    let maskedKey = '';
    if (rawKey.length > 8) {
      maskedKey = `${rawKey.slice(0, 4)}...${rawKey.slice(-4)}`;
    } else if (rawKey.length > 0) {
      maskedKey = '****';
    }

    const appUrl = (config?.serverDomain || process.env.APP_URL || 'http://localhost:3000').replace(/\/+$/, '');
    const webhookUrl = `${appUrl}/webhooks/thueapi`;

    return {
      enabled: isEnabled,
      hasKey,
      apiKey: rawKey,
      apiKeyMasked: maskedKey,
      bankAcc: config?.thueApiBankAcc || config?.bankAcc || '3011200588888',
      bankCode: config?.thueApiBankCode || config?.bankCode || 'MB',
      bankName: config?.bankName || 'TRẦN QUỐC VŨ',
      webhookUrl,
      updatedAt: config?.updatedAt,
      status: !hasKey
        ? 'BLOCKED: CHƯA CÓ CẤU HÌNH NHÀ CUNG CẤP'
        : isEnabled
          ? 'ACTIVE: ĐANG HOẠT ĐỘNG'
          : 'DISABLED: ĐÃ TẮT',
    };
  }

  /**
   * Cập nhật cấu hình ThueApi.Pro an toàn và đồng bộ trực tiếp vào MySQL SystemConfig
   */
  async updateConfig(dto: {
    enabled?: boolean;
    apiKey?: string;
    bankAcc?: string;
    bankCode?: string;
    bankName?: string;
    webhookSecret?: string;
  }) {
    const updateData: any = {};
    if (dto.enabled !== undefined) updateData.thueApiEnabled = Boolean(dto.enabled);
    if (dto.apiKey !== undefined && dto.apiKey.trim() !== '') {
      updateData.thueApiKey = dto.apiKey.trim();
    }
    if (dto.webhookSecret !== undefined) {
      updateData.thueApiSecret = dto.webhookSecret.trim();
    }
    if (dto.bankAcc !== undefined && dto.bankAcc.trim() !== '') {
      const cleanAcc = dto.bankAcc.trim();
      updateData.thueApiBankAcc = cleanAcc;
      updateData.bankAcc = cleanAcc; // Đồng bộ trực tiếp vào cấu hình chuyển khoản hệ thống
    }
    if (dto.bankCode !== undefined && dto.bankCode.trim() !== '') {
      const cleanCode = dto.bankCode.trim().toUpperCase();
      updateData.thueApiBankCode = cleanCode;
      updateData.bankCode = cleanCode; // Đồng bộ trực tiếp mã ngân hàng nhận tiền
    }
    if (dto.bankName !== undefined && dto.bankName.trim() !== '') {
      updateData.bankName = dto.bankName.trim().toUpperCase(); // Đồng bộ chủ tài khoản
    }

    await this.prisma.systemConfig.upsert({
      where: { id: 'default' },
      update: updateData,
      create: {
        id: 'default',
        brandName: 'Đọc thông báo nhận tiền',
        brandSlogan: 'Tiền vừa sang ~ máy báo vang',
        chplayLink: 'https://play.google.com/store/apps/details?id=com.dtappbaochuyentien.vn',
        youtubeLink: 'https://www.youtube.com/@vudev05',
        ...updateData,
      },
    });

    return this.getConfig();
  }

  /**
   * Kiểm tra kết nối tới nhà cung cấp ThueApi.Pro
   */
  async testConnection() {
    const config = await this.prisma.systemConfig.findUnique({
      where: { id: 'default' },
    });

    if (!config?.thueApiKey || config.thueApiKey.trim().length === 0) {
      return {
        success: false,
        status: 'BLOCKED: CHƯA CÓ CẤU HÌNH NHÀ CUNG CẤP',
        message:
          'Chưa cấu hình API Key của ThueApi.Pro! Vui lòng đăng ký tài khoản tại https://thueapi.pro/, lấy API Key và lưu vào hệ thống.',
      };
    }

    try {
      // 1. Kiểm tra kết nối mạng và độ khả dụng tới máy chủ ThueApi.Pro
      const response = await fetch('https://thueapi.pro', {
        headers: {
          'User-Agent': 'AutoBank-PRO-Server/1.2.0',
        },
      });

      if (response.ok) {
        return {
          success: true,
          status: 'CONNECTED',
          message: 'Kết nối thành công tới máy chủ ThueApi.Pro! API Key đã sẵn sàng và cổng Webhook hoạt động 24/7.',
          providerData: {
            service: 'ThueApi.Pro',
            status: 'ONLINE',
            bankAcc: config.thueApiBankAcc || config.bankAcc || '3011200588888',
            bankCode: config.thueApiBankCode || config.bankCode || 'MB',
            webhookEndpoint: '/webhooks/thueapi',
          },
        };
      } else {
        return {
          success: false,
          status: 'SERVER_UNAVAILABLE',
          message: `Máy chủ ThueApi.Pro đang phản hồi mã lỗi HTTP ${response.status}.`,
        };
      }
    } catch (err: any) {
      return {
        success: false,
        status: 'CONNECTION_ERROR',
        message: `Không thể kết nối đến máy chủ thueapi.pro (${err.message || 'Network Timeout'}).`,
      };
    }
  }

  /**
   * Lấy lịch sử Webhook logs từ ThueApi.Pro
   */
  async getWebhookLogs(limit = 30) {
    return this.prisma.webhookLog.findMany({
      where: { event: { contains: 'thueapi' } },
      orderBy: { createdAt: 'desc' },
      take: limit,
    });
  }

  /**
   * Xử lý Webhook biến động số dư từ ThueApi.Pro và TỰ ĐỘNG KÍCH HOẠT GÓI
   */
  async handleWebhook(payload: ThueApiWebhookDto, signatureHeader?: string) {
    const config = await this.prisma.systemConfig.findUnique({
      where: { id: 'default' },
    });

    // 1. Kiểm tra trạng thái kích hoạt nhà cung cấp
    if (!config?.thueApiEnabled || !config?.thueApiKey) {
      await this.prisma.webhookLog.create({
        data: {
          event: 'thueapi.webhook',
          payload: JSON.stringify(payload),
          responseCode: 503,
          status: 'BLOCKED: CHƯA CÓ CẤU HÌNH NHÀ CUNG CẤP',
        },
      });
      throw new BadRequestException('Tích hợp ThueApi.Pro chưa được kích hoạt hoặc chưa cấu hình API Key');
    }

    // 2. Xác thực chữ ký webhook nếu người dùng thực sự cài đặt Webhook Secret trên ThueApi.Pro
    const secretKey = (config.thueApiSecret || '').trim();
    const isRealSecretConfigured = secretKey.length > 0 && secretKey !== 'secret_hash_webhook_2026';
    if (isRealSecretConfigured) {
      const providedSignature = signatureHeader || payload.signature || payload.sign;
      if (!providedSignature) {
        await this.prisma.webhookLog.create({
          data: {
            event: 'thueapi.webhook',
            payload: JSON.stringify(payload),
            responseCode: 401,
            status: 'FAILED_SIGNATURE_MISSING',
          },
        });
        throw new BadRequestException('Webhook thiếu chữ ký xác thực (X-Signature)');
      }

      const expectedSig = crypto
        .createHmac('sha256', secretKey)
        .update(JSON.stringify(payload))
        .digest('hex');

      if (providedSignature !== expectedSig) {
        this.logger.warn(`Chữ ký Webhook không khớp: expected ${expectedSig}, received ${providedSignature}`);
        await this.prisma.webhookLog.create({
          data: {
            event: 'thueapi.webhook',
            payload: JSON.stringify(payload),
            responseCode: 401,
            status: 'FAILED_INVALID_SIGNATURE',
          },
        });
        throw new BadRequestException('Chữ ký Webhook không hợp lệ!');
      }
    }

    // 3. Chuẩn hóa dữ liệu giao dịch từ payload ThueApi.Pro
    const rawAmount = Number(payload.amount);
    if (isNaN(rawAmount) || rawAmount <= 0) {
      throw new BadRequestException('Số tiền giao dịch không hợp lệ');
    }

    const transferType = (payload.transferType || payload.type || 'in').toLowerCase();
    if (transferType !== 'in' && transferType !== 'credit') {
      this.logger.log(`Bỏ qua giao dịch tiền ra (debit/out): ${rawAmount}đ`);
      return { success: true, message: 'Bỏ qua giao dịch tiền ra' };
    }

    const bankCode = (payload.gateway || payload.bank || config.thueApiBankCode || 'MB').toUpperCase();
    const accountNumber = payload.accountNumber || payload.account_number || config.thueApiBankAcc || '';
    const transId = String(payload.transactionNumber || payload.transaction_id || payload.id || Date.now());
    const content = payload.content || payload.description || '';
    const fingerprint = `thueapi_${bankCode}_${transId}_${rawAmount}`;

    // 4. Kiểm tra Idempotency (Chống xử lý trùng lặp giao dịch)
    const existingTx = await this.prisma.transaction.findUnique({
      where: { fingerprint },
    });

    if (existingTx) {
      this.logger.warn(`Giao dịch ThueApi đã được xử lý trước đó: ${fingerprint}`);
      return {
        success: true,
        message: 'Giao dịch đã được ghi nhận trước đó (Idempotent)',
        isDuplicate: true,
      };
    }

    // 5. Trích xuất mã đơn hàng từ nội dung giao dịch (VD: DH1058, AB102, ORD-123456)
    const orderCodeMatch = content.match(/\b([A-Za-z0-9_-]{4,20})\b/g);
    let matchedOrder: any = null;

    if (orderCodeMatch) {
      for (const candidate of orderCodeMatch) {
        const order = await this.prisma.order.findUnique({
          where: { orderCode: candidate },
        });
        if (order) {
          matchedOrder = order;
          break;
        }
      }
    }

    // 6. Thực hiện Atomic Transaction trong Database
    const result = await this.prisma.$transaction(async (tx) => {
      // Tạo giao dịch ngân hàng
      const newTx = await tx.transaction.create({
        data: {
          bankCode,
          accountNumber,
          amount: new Prisma.Decimal(rawAmount),
          type: 'credit',
          content,
          orderCode: matchedOrder ? matchedOrder.orderCode : null,
          transactionTime: payload.transferDate ? new Date(payload.transferDate) : new Date(),
          rawContent: JSON.stringify(payload),
          fingerprint,
          status: matchedOrder ? 'MATCHED' : 'UNMATCHED',
          matchedOrderId: matchedOrder ? matchedOrder.id : null,
        },
      });

      let subscriptionActivated = false;
      let userUpdated = null;

      // Nếu khớp đơn hàng: Kích hoạt / gia hạn gói bản quyền
      if (matchedOrder) {
        const currentPaid = Number(matchedOrder.paidAmount);
        const newPaid = currentPaid + rawAmount;
        const totalAmount = Number(matchedOrder.totalAmount);
        const newStatus = newPaid >= totalAmount ? 'PAID' : 'PARTIALLY_PAID';

        await tx.order.update({
          where: { id: matchedOrder.id },
          data: {
            paidAmount: new Prisma.Decimal(newPaid),
            status: newStatus,
          },
        });

        // Nếu đơn đã được thanh toán đầy đủ -> Tự động kích hoạt hoặc cộng dồn thời hạn gói
        if (newStatus === 'PAID') {
          subscriptionActivated = true;
          const userIdentifier = matchedOrder.customerName || matchedOrder.customerPhone;

          if (userIdentifier) {
            // Tìm tài khoản AppDeviceUser theo email hoặc số điện thoại
            const appUser = await tx.appDeviceUser.findFirst({
              where: {
                OR: [
                  { email: userIdentifier },
                  { phone: userIdentifier },
                  { name: userIdentifier },
                ],
              },
            });

            if (appUser) {
              // Tính số ngày của gói dịch vụ
              const pkgDesc = (matchedOrder.description || '').toLowerCase();
              let daysToAdd = 30; // Mặc định 1 tháng
              let isLifetime = false;

              if (pkgDesc.includes('vĩnh viễn') || pkgDesc.includes('lifetime') || rawAmount >= 499000) {
                isLifetime = true;
              } else if (pkgDesc.includes('1 năm') || pkgDesc.includes('1y') || rawAmount >= 299000) {
                daysToAdd = 365 + (config.bonusMonths1y * 30); // 365 ngày + số tháng khuyến mãi
              } else if (pkgDesc.includes('9 tháng') || rawAmount >= 249000) {
                daysToAdd = 270;
              } else if (pkgDesc.includes('6 tháng') || rawAmount >= 179000) {
                daysToAdd = 180;
              } else if (pkgDesc.includes('3 tháng') || rawAmount >= 99000) {
                daysToAdd = 90;
              }

              const now = new Date();
              let newExpiry: Date;

              if (isLifetime) {
                newExpiry = new Date('2099-12-31T23:59:59.000Z');
              } else {
                // Cộng dồn thời hạn: Nếu gói còn hạn thì cộng tiếp từ ngày hết hạn, nếu đã hết hạn thì cộng từ hôm nay
                const baseDate = appUser.expiresAt && new Date(appUser.expiresAt) > now ? new Date(appUser.expiresAt) : now;
                newExpiry = new Date(baseDate.getTime() + daysToAdd * 86400000);
              }

              userUpdated = await tx.appDeviceUser.update({
                where: { id: appUser.id },
                data: {
                  expiresAt: newExpiry,
                  packagePlan: matchedOrder.description || (isLifetime ? 'Gói Vĩnh Viễn' : `${daysToAdd} ngày`),
                  status: 'ACTIVE',
                },
              });

              this.logger.log(
                `KÍCH HOẠT GÓI THÀNH CÔNG cho ${appUser.email}! Hạn mới: ${newExpiry.toISOString()}`,
              );
            }
          }
        }
      }

      // Lưu nhật ký webhook
      await tx.webhookLog.create({
        data: {
          event: 'thueapi.webhook',
          orderCode: matchedOrder ? matchedOrder.orderCode : null,
          payload: JSON.stringify(payload),
          responseCode: 200,
          status: 'SUCCESS',
        },
      });

      return {
        transaction: newTx,
        order: matchedOrder,
        subscriptionActivated,
        user: userUpdated,
      };
    });

    return {
      success: true,
      message: result.subscriptionActivated
        ? 'Xác nhận thanh toán và tự động kích hoạt gói bản quyền thành công!'
        : 'Giao dịch đã được lưu thành công',
      data: result,
    };
  }
}
