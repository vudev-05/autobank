import { Injectable, NotFoundException, BadRequestException, Logger } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service.js';
import { CreateOrderDto } from './dto/create-order.dto.js';
import { Prisma } from '@prisma/client';

@Injectable()
export class OrdersService {
  private readonly logger = new Logger(OrdersService.name);

  constructor(private readonly prisma: PrismaService) {}

  /**
   * Tạo đơn hàng mới kèm link VietQR động
   */
  async create(dto: CreateOrderDto) {
    const existing = await this.prisma.order.findUnique({
      where: { orderCode: dto.orderCode },
    });

    if (existing) {
      throw new BadRequestException(`Mã đơn hàng ${dto.orderCode} đã tồn tại!`);
    }

    // Đảm bảo có ít nhất 1 merchant mặc định
    let merchant = await this.prisma.merchant.findFirst();
    if (!merchant) {
      merchant = await this.prisma.merchant.create({
        data: {
          name: 'Cửa hàng Mặc định',
          slug: 'default-merchant',
        },
      });
    }

    const bankCode = dto.bankCode ?? 'MBBANK';
    const accountNumber = dto.accountNumber ?? '0338889999';

    // Mã BIN ngân hàng VietQR
    const bankBinMap: Record<string, string> = {
      MBBANK: '970422',
      VIETCOMBANK: '970436',
      TECHCOMBANK: '970407',
      ACB: '970416',
      BIDV: '970418',
    };
    const bin = bankBinMap[bankCode.toUpperCase()] ?? '970422';
    const qrCodeUrl = `https://img.vietqr.io/image/${bin}-${accountNumber}-compact2.png?amount=${dto.totalAmount}&addInfo=${dto.orderCode}`;

    const order = await this.prisma.order.create({
      data: {
        merchantId: merchant.id,
        orderCode: dto.orderCode,
        totalAmount: new Prisma.Decimal(dto.totalAmount),
        paidAmount: new Prisma.Decimal(0),
        status: 'PENDING',
        description: dto.description,
        customerName: dto.customerName,
        customerPhone: dto.customerPhone,
        qrCodeUrl,
      },
    });

    this.logger.log(`Tạo đơn hàng thành công: ${order.orderCode} - ${order.totalAmount}đ`);

    return order;
  }

  async findAll(limit = 50) {
    return this.prisma.order.findMany({
      take: limit,
      orderBy: { createdAt: 'desc' },
      include: {
        transactions: true,
      },
    });
  }

  async findByCode(orderCode: string) {
    const order = await this.prisma.order.findUnique({
      where: { orderCode },
      include: {
        transactions: true,
      },
    });

    if (!order) {
      throw new NotFoundException(`Không tìm thấy đơn hàng mã ${orderCode}`);
    }

    return order;
  }

  async getStatus(orderCode: string) {
    const order = await this.findByCode(orderCode);
    return {
      orderCode: order.orderCode,
      status: order.status,
      totalAmount: Number(order.totalAmount),
      paidAmount: Number(order.paidAmount),
      isPaid: order.status === 'PAID' || order.status === 'OVERPAID',
    };
  }
}
