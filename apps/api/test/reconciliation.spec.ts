import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { PrismaClient } from '@prisma/client';
import { TransactionsService } from '../src/transactions/transactions.service.js';
import { OrdersService } from '../src/orders/orders.service.js';
import { PrismaService } from '../src/prisma/prisma.service.js';

describe('Động cơ Đối soát Thanh toán AutoBank (Reconciliation Engine)', () => {
  let prisma: PrismaService;
  let transactionsService: TransactionsService;
  let ordersService: OrdersService;

  beforeAll(async () => {
    prisma = new PrismaService();
    await prisma.$connect();
    transactionsService = new TransactionsService(prisma);
    ordersService = new OrdersService(prisma);

    // Dọn dẹp đơn test cũ nếu có
    await prisma.transaction.deleteMany({
      where: { orderCode: { in: ['DH_TEST_99', 'DH_TEST_100'] } },
    });
    await prisma.order.deleteMany({
      where: { orderCode: { in: ['DH_TEST_99', 'DH_TEST_100'] } },
    });
  });

  afterAll(async () => {
    // Dọn dẹp dữ liệu test
    await prisma.transaction.deleteMany({
      where: { orderCode: { in: ['DH_TEST_99', 'DH_TEST_100'] } },
    });
    await prisma.order.deleteMany({
      where: { orderCode: { in: ['DH_TEST_99', 'DH_TEST_100'] } },
    });
    await prisma.$disconnect();
  });

  it('1. Tạo đơn hàng mới thành công với mã VietQR', async () => {
    const order = await ordersService.create({
      orderCode: 'DH_TEST_99',
      totalAmount: 100000,
      description: 'Đơn hàng test đối soát tự động',
      customerName: 'Nguyễn Văn Test',
    });

    expect(order.orderCode).toBe('DH_TEST_99');
    expect(Number(order.totalAmount)).toBe(100000);
    expect(Number(order.paidAmount)).toBe(0);
    expect(order.status).toBe('PENDING');
    expect(order.qrCodeUrl).toContain('vietqr.io');
  });

  it('2. Khách chuyển thiếu tiền -> Chuyển trạng thái sang PARTIALLY_PAID', async () => {
    const res = await transactionsService.ingestTransaction({
      bankCode: 'MBBANK',
      accountNumber: '0338889999',
      amount: 40000,
      type: 'credit',
      content: 'DH_TEST_99 Khach chuyen tien dot 1',
      orderCode: 'DH_TEST_99',
      transactionTime: new Date().toISOString(),
      rawContent: 'Biến động số dư: +40,000VND ND: DH_TEST_99',
      fingerprint: 'fp_test_partial_1',
    });

    expect(res.success).toBe(true);
    expect(res.isDuplicate).toBe(false);
    expect(res.reconciliation?.matched).toBe(true);
    expect(res.reconciliation?.orderStatus).toBe('PARTIALLY_PAID');
    expect(res.reconciliation?.paidAmount).toBe(40000);
  });

  it('3. Giao dịch bị gửi trùng lặp (Idempotency) -> Bị chặn và không cộng thêm tiền', async () => {
    const duplicateRes = await transactionsService.ingestTransaction({
      bankCode: 'MBBANK',
      accountNumber: '0338889999',
      amount: 40000,
      type: 'credit',
      content: 'DH_TEST_99 Khach chuyen tien dot 1',
      orderCode: 'DH_TEST_99',
      transactionTime: new Date().toISOString(),
      rawContent: 'Biến động số dư: +40,000VND ND: DH_TEST_99',
      fingerprint: 'fp_test_partial_1', // Trùng fingerprint
    });

    expect(duplicateRes.isDuplicate).toBe(true);

    // Kiểm tra đơn hàng vẫn chỉ nhận 40,000đ
    const orderStatus = await ordersService.getStatus('DH_TEST_99');
    expect(orderStatus.paidAmount).toBe(40000);
    expect(orderStatus.status).toBe('PARTIALLY_PAID');
  });

  it('4. Khách chuyển nốt tiền còn lại -> Chuyển trạng thái sang PAID hoàn tất', async () => {
    const finalRes = await transactionsService.ingestTransaction({
      bankCode: 'VIETCOMBANK',
      accountNumber: '1012345678',
      amount: 60000,
      type: 'credit',
      content: 'DH_TEST_99 Chuyen not 60k con thieu',
      orderCode: 'DH_TEST_99',
      transactionTime: new Date().toISOString(),
      rawContent: 'VCB Digibank: +60,000 VND ND: DH_TEST_99',
      fingerprint: 'fp_test_final_2',
    });

    expect(finalRes.reconciliation?.matched).toBe(true);
    expect(finalRes.reconciliation?.orderStatus).toBe('PAID');
    expect(finalRes.reconciliation?.paidAmount).toBe(100000);

    const checkOrder = await ordersService.getStatus('DH_TEST_99');
    expect(checkOrder.isPaid).toBe(true);
    expect(checkOrder.status).toBe('PAID');
  });
});
