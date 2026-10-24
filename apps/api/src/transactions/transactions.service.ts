import { Injectable, Logger, MessageEvent } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service.js';
import { CreateTransactionDto } from './dto/create-transaction.dto.js';
import { Prisma } from '@prisma/client';
import * as crypto from 'crypto';
import { Subject, Observable } from 'rxjs';
import { filter, map } from 'rxjs/operators';

@Injectable()
export class TransactionsService {
  private readonly logger = new Logger(TransactionsService.name);
  private readonly liveTxSubject = new Subject<{ tx: any; userEmail?: string }>();

  constructor(private readonly prisma: PrismaService) {}

  /**
   * Phát sự kiện giao dịch mới theo thời gian thực tới các máy nghe loa Web Live
   */
  broadcastLiveTx(tx: any, userEmail?: string) {
    this.liveTxSubject.next({ tx, userEmail });
  }

  /**
   * Đăng ký luồng Server-Sent Events (SSE) theo mã PIN hoặc tài khoản
   */
  getLiveTxStream(pinOrEmail?: string): Observable<MessageEvent> {
    return this.liveTxSubject.asObservable().pipe(
      filter((data) => {
        if (!pinOrEmail || pinOrEmail === 'all') return true;
        const target = pinOrEmail.trim().toLowerCase();
        if (data.userEmail && data.userEmail.toLowerCase().includes(target)) return true;
        return true; // Mặc định chuyển tiếp để loa Web phát ngay lập tức
      }),
      map((data) => ({
        data: JSON.stringify(data.tx),
      } as MessageEvent)),
    );
  }

  /**
   * Tiếp nhận giao dịch từ Mobile App hoặc Ngân hàng.
   * Xử lý Idempotency bằng Fingerprint và tự động đối soát đơn hàng (Reconciliation Engine).
   */
  async ingestTransaction(dto: CreateTransactionDto) {
    // Đảm bảo luôn có fingerprint hợp lệ
    const fingerprint = dto.fingerprint || crypto.createHash('sha256').update(
      `${dto.accountNumber || ''}_${dto.amount}_${dto.transactionTime || Date.now()}_${dto.content || ''}`
    ).digest('hex');
    dto.fingerprint = fingerprint;

    // 1. Kiểm tra Idempotency (Chống xử lý trùng lặp trên server)
    const existingTx = await this.prisma.transaction.findUnique({
      where: { fingerprint },
      include: { matchedOrder: true },
    });

    if (existingTx) {
      this.logger.warn(`Bỏ qua giao dịch trùng lặp: Fingerprint ${dto.fingerprint}`);
      return {
        success: true,
        message: 'Giao dịch đã tồn tại (Idempotent)',
        isDuplicate: true,
        transaction: existingTx,
      };
    }

    let txTime: Date;
    if (dto.transactionTime) {
      const timeStr = String(dto.transactionTime).trim();
      if (!timeStr.endsWith('Z') && !/[+-]\d{2}(:?\d{2})?$/.test(timeStr)) {
        txTime = new Date(`${timeStr}+07:00`);
      } else {
        txTime = new Date(timeStr);
      }
    } else {
      txTime = new Date();
    }

    // 2. Tìm merchant nếu có slug
    let merchantId: string | undefined;
    if (dto.merchantSlug) {
      const merchant = await this.prisma.merchant.findUnique({
        where: { slug: dto.merchantSlug },
      });
      if (merchant) merchantId = merchant.id;
    }

    // 3. Khởi tạo giao dịch trong database
    const newTx = await this.prisma.transaction.create({
      data: {
        bankCode: dto.bankCode,
        accountNumber: dto.accountNumber,
        amount: new Prisma.Decimal(dto.amount),
        type: dto.type,
        content: dto.content,
        orderCode: dto.orderCode,
        transactionTime: isNaN(txTime.getTime()) ? new Date() : txTime,
        rawContent: dto.rawContent,
        fingerprint: dto.fingerprint,
        merchantId,
        userEmail: dto.userEmail ? dto.userEmail.trim().toLowerCase() : undefined,
        category: dto.category,
        note: dto.note,
        status: 'UNMATCHED',
      },
    });

    this.logger.log(`Đã ghi nhận giao dịch mới: ${newTx.bankCode} +${newTx.amount}đ [${newTx.orderCode ?? 'No Code'}]`);

    // Phát tín hiệu Real-time qua SSE Stream tới các thiết bị Web Live
    this.broadcastLiveTx(newTx, dto.userEmail);

    // 4. Động cơ đối soát đơn hàng (Reconciliation Engine)
    let reconciliationResult = null;
    let orderCodeToMatch = dto.orderCode;
    if (!orderCodeToMatch && (dto.content || dto.rawContent)) {
      const match = `${dto.content || ''} ${dto.rawContent || ''}`.match(/\b(AB\d{5,15})\b/i);
      if (match) {
        orderCodeToMatch = match[1].toUpperCase();
      }
    }
    if (orderCodeToMatch && dto.type === 'credit') {
      reconciliationResult = await this.reconcileOrder(newTx.id, orderCodeToMatch, dto.amount);
    }

    return {
      success: true,
      message: 'Giao dịch đã được lưu và đối soát thành công',
      isDuplicate: false,
      transaction: newTx,
      reconciliation: reconciliationResult,
    };
  }

  /**
   * Động cơ đối soát đơn hàng (Reconciliation Algorithm 3 cấp độ)
   */
  private async reconcileOrder(transactionId: string, orderCode: string, paidAmount: number) {
    const order = await this.prisma.order.findUnique({
      where: { orderCode },
    });

    if (!order) {
      this.logger.log(`Không tìm thấy đơn hàng mã ${orderCode} trong hệ thống`);
      return { matched: false, reason: 'ORDER_NOT_FOUND' };
    }

    const currentPaid = Number(order.paidAmount);
    const orderTotal = Number(order.totalAmount);
    const newTotalPaid = currentPaid + paidAmount;

    let newStatus = order.status;
    if (newTotalPaid >= orderTotal) {
      newStatus = newTotalPaid > orderTotal ? 'OVERPAID' : 'PAID';
    } else {
      newStatus = 'PARTIALLY_PAID';
    }

    // Cập nhật cả đơn hàng và giao dịch trong 1 Transaction an toàn
    const [updatedOrder, updatedTx] = await this.prisma.$transaction([
      this.prisma.order.update({
        where: { id: order.id },
        data: {
          paidAmount: new Prisma.Decimal(newTotalPaid),
          status: newStatus,
        },
      }),
      this.prisma.transaction.update({
        where: { id: transactionId },
        data: {
          status: 'MATCHED',
          matchedOrderId: order.id,
        },
      }),
    ]);

    this.logger.log(`Khớp đơn thành công! Đơn: ${order.orderCode} -> Trạng thái: ${newStatus} (Đã trả: ${newTotalPaid}/${orderTotal})`);

    // Tự động kích hoạt / gia hạn gói bản quyền cho user khi đơn hàng đã thanh toán thành công
    if (newStatus === 'PAID' || newStatus === 'OVERPAID') {
      const email = order.customerName || order.customerPhone;
      if (email && email.includes('@')) {
        let days = 30;
        const desc = (order.description || '').toLowerCase();
        if (desc.includes('3 tháng')) days = 90;
        else if (desc.includes('6 tháng')) days = 180;
        else if (desc.includes('9 tháng')) days = 270;
        else if (desc.includes('1 năm') || desc.includes('12 tháng')) days = 365;
        else if (desc.includes('vĩnh viễn') || desc.includes('trọn đời')) days = 3650;
        else days = 365;

        try {
          const user = await this.prisma.appDeviceUser.findFirst({
            where: { email },
          });
          if (user) {
            const current = new Date(user.expiresAt) > new Date() ? new Date(user.expiresAt) : new Date();
            current.setDate(current.getDate() + days);
            await this.prisma.appDeviceUser.update({
              where: { id: user.id },
              data: { expiresAt: current, status: 'ACTIVE' },
            });
            this.logger.log(`[AutoBank] Đã tự động kích hoạt nâng gói cho ${email}: +${days} ngày!`);
          }
        } catch (err) {
          this.logger.error(`Lỗi tự động gia hạn gói cho ${email}: ${err}`);
        }
      }
    }

    return {
      matched: true,
      orderCode: order.orderCode,
      orderStatus: newStatus,
      totalAmount: orderTotal,
      paidAmount: newTotalPaid,
      order: updatedOrder,
    };
  }

  async findAll(limit = 100, userEmail?: string) {
    const where: any = {};
    if (userEmail && userEmail.trim().length > 0) {
      where.userEmail = userEmail.trim().toLowerCase();
    }
    return this.prisma.transaction.findMany({
      where: Object.keys(where).length > 0 ? where : undefined,
      take: limit,
      orderBy: { transactionTime: 'desc' },
      include: { matchedOrder: true },
    });
  }

  async findOne(id: string) {
    return this.prisma.transaction.findUnique({
      where: { id },
      include: { matchedOrder: true },
    });
  }

  /**
   * Xóa giao dịch theo ID hoặc Fingerprint trên MySQL server
   */
  async delete(idOrFingerprint: string, userEmail?: string) {
    const where: any = {
      OR: [
        { id: idOrFingerprint },
        { fingerprint: idOrFingerprint },
      ],
    };
    if (userEmail && userEmail.trim().length > 0) {
      where.userEmail = userEmail.trim().toLowerCase();
    }

    const tx = await this.prisma.transaction.findFirst({ where });
    if (!tx) {
      this.logger.warn(`Không tìm thấy giao dịch cần xóa: ${idOrFingerprint}`);
      return { success: false, message: 'Không tìm thấy giao dịch để xóa' };
    }

    await this.prisma.transaction.delete({ where: { id: tx.id } });
    this.logger.log(`Đã xóa vĩnh viễn giao dịch: ${tx.id} (${tx.fingerprint}) khỏi MySQL`);
    return { success: true, message: 'Đã xóa giao dịch thành công' };
  }

  /**
   * Xóa toàn bộ giao dịch của một tài khoản trên MySQL server
   */
  async clearUserTransactions(userEmail: string) {
    const cleanEmail = (userEmail || '').trim().toLowerCase();
    if (!cleanEmail) {
      return { success: false, message: 'Email không hợp lệ', count: 0 };
    }
    const res = await this.prisma.transaction.deleteMany({
      where: { userEmail: cleanEmail },
    });
    this.logger.log(`Đã xóa toàn bộ ${res.count} giao dịch của tài khoản ${cleanEmail} trên MySQL`);
    return { success: true, count: res.count };
  }
}
