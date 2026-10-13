import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service.js';
import { CreateTransactionDto } from './dto/create-transaction.dto.js';
import { Prisma } from '@prisma/client';

@Injectable()
export class TransactionsService {
  private readonly logger = new Logger(TransactionsService.name);

  constructor(private readonly prisma: PrismaService) {}

  /**
   * Tiếp nhận giao dịch từ Mobile App hoặc Ngân hàng.
   * Xử lý Idempotency bằng Fingerprint và tự động đối soát đơn hàng (Reconciliation Engine).
   */
  async ingestTransaction(dto: CreateTransactionDto) {
    // 1. Kiểm tra Idempotency (Chống xử lý trùng lặp trên server)
    const existingTx = await this.prisma.transaction.findUnique({
      where: { fingerprint: dto.fingerprint },
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

    const txTime = new Date(dto.transactionTime);

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
        status: 'UNMATCHED',
      },
    });

    this.logger.log(`Đã ghi nhận giao dịch mới: ${newTx.bankCode} +${newTx.amount}đ [${newTx.orderCode ?? 'No Code'}]`);

    // 4. Động cơ đối soát đơn hàng (Reconciliation Engine)
    let reconciliationResult = null;
    if (dto.orderCode && dto.type === 'credit') {
      reconciliationResult = await this.reconcileOrder(newTx.id, dto.orderCode, dto.amount);
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

    return {
      matched: true,
      orderCode: order.orderCode,
      orderStatus: newStatus,
      totalAmount: orderTotal,
      paidAmount: newTotalPaid,
      order: updatedOrder,
    };
  }

  async findAll(limit = 50) {
    return this.prisma.transaction.findMany({
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
}
