import { PrismaClient } from '@prisma/client';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const prisma = new PrismaClient();

async function main() {
  console.log('--- BẮT ĐẦU NẠP DỮ LIỆU VÀO MYSQL (autobank) ---');

  // 1. Cấu hình hệ thống (System Config)
  console.log('1. Đang nạp cấu hình hệ thống...');
  await prisma.systemConfig.upsert({
    where: { id: 'default' },
    update: {
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
      priceLifetime: 499000,
      bonusMonths1y: 2,
      marketingBanner: '🎉 ƯU ĐÃI ĐẶC BIỆT: Nhập mã AUTOBANK20 giảm ngay 20% cho tất cả các gói!',
      maintenance: false,
      maintenanceMsg: 'Hệ thống đang bảo trì nâng cấp máy chủ định kỳ. Vui lòng quay lại sau 15 phút.',
      latestVersion: '1.2.0',
      minVersion: '1.0.0',
    },
    create: {
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
      priceLifetime: 499000,
      bonusMonths1y: 2,
      marketingBanner: '🎉 ƯU ĐÃI ĐẶC BIỆT: Nhập mã AUTOBANK20 giảm ngay 20% cho tất cả các gói!',
      maintenance: false,
      maintenanceMsg: 'Hệ thống đang bảo trì nâng cấp máy chủ định kỳ. Vui lòng quay lại sau 15 phút.',
      latestVersion: '1.2.0',
      minVersion: '1.0.0',
    },
  });
  console.log('✓ Đã nạp SystemConfig.');

  // 1.1 Khởi tạo các mã giảm giá Marketing
  console.log('1.1 Đang nạp mã giảm giá khuyến mãi Marketing...');
  const defaultCoupons = [
    { code: 'AUTOBANK20', description: 'Giảm 20% toàn bộ gói cước', discountPercent: 20, discountAmount: 0 },
    { code: 'TET2026', description: 'Tri ân khách hàng giảm 30%', discountPercent: 30, discountAmount: 0 },
    { code: 'VIP50K', description: 'Giảm ngay 50.000đ trực tiếp', discountPercent: 0, discountAmount: 50000 },
  ];
  for (const c of defaultCoupons) {
    await prisma.discountCoupon.upsert({
      where: { code: c.code },
      update: c,
      create: c,
    });
  }
  console.log('✓ Đã nạp DiscountCoupons.');

  // 2. Tài khoản quản trị Admin
  console.log('2. Đang nạp tài khoản Admin...');
  await prisma.adminAccount.upsert({
    where: { username: 'admin' },
    update: {
      password: 'autobank@2026',
      role: 'SUPER_ADMIN',
    },
    create: {
      username: 'admin',
      password: 'autobank@2026',
      role: 'SUPER_ADMIN',
    },
  });
  console.log('✓ Đã nạp AdminAccount (admin / autobank@2026).');

  // 3. Đọc dữ liệu 65+ ngân hàng từ web
  console.log('3. Đang nạp danh sách 65+ ngân hàng & ví điện tử...');
  const banksDataPath = path.resolve(__dirname, '../../web/assets/data/banks-data.js');
  let rawContent = fs.readFileSync(banksDataPath, 'utf-8');
  // Chuyển đổi export const BANKS_DATA thành đối tượng JSON
  rawContent = rawContent.replace(/export const BANK_CATEGORIES = \{[\s\S]*?\};/, '');
  rawContent = rawContent.replace(/export const BANKS_DATA =/, 'globalThis.__BANKS =');
  rawContent = rawContent.replace(/category: BANK_CATEGORIES\.(\w+)/g, 'category: "$1"');
  eval(rawContent);

  const banks = globalThis.__BANKS || [];
  let bankCount = 0;
  for (const b of banks) {
    const cat = (b.category || 'COMMERCIAL').toLowerCase();
    await prisma.bankApp.upsert({
      where: { id: b.id },
      update: {
        name: b.name,
        app: b.app,
        code: b.code,
        pkg: b.pkg,
        category: cat,
        logo: b.logo,
        guide: b.guide,
        isActive: true,
      },
      create: {
        id: b.id,
        name: b.name,
        app: b.app,
        code: b.code,
        pkg: b.pkg,
        category: cat,
        logo: b.logo,
        guide: b.guide,
        isActive: true,
      },
    });
    bankCount++;
  }
  console.log(`✓ Đã nạp thành công ${bankCount} Ngân Hàng & Ví Điện Tử.`);

  // 4. Nạp người dùng & thiết bị mobile
  console.log('4. Đang nạp danh sách người dùng & thiết bị mobile...');
  const sampleUsers = [
    { name: 'Nguyễn Văn An', email: 'an.nguyen.shop@gmail.com', device: 'Samsung Galaxy A54 (Android 14)', version: '1.2.0', packagePlan: '1 Năm', expiresAt: new Date('2027-10-10'), status: 'ACTIVE' },
    { name: 'Trần Thị Mai', email: 'mai.tran.cafe@gmail.com', device: 'Xiaomi Redmi Note 13', version: '1.2.0', packagePlan: '6 Tháng', expiresAt: new Date('2027-04-10'), status: 'ACTIVE' },
    { name: 'Lê Hoàng Nam', email: 'nam.le.tiemtaphoa@gmail.com', device: 'Oppo Reno 11 Pro', version: '1.1.8', packagePlan: '3 Tháng', expiresAt: new Date('2027-01-10'), status: 'ACTIVE' },
    { name: 'Phạm Minh Đức', email: 'duc.pham.food@gmail.com', device: 'Realme 12 5G', version: '1.2.0', packagePlan: 'Dùng thử 3 ngày', expiresAt: new Date('2026-10-14'), status: 'TRIAL' },
    { name: 'Hoàng Kim Yến', email: 'yen.hoang.fashion@gmail.com', device: 'Samsung Galaxy S23 Ultra', version: '1.2.0', packagePlan: '1 Năm', expiresAt: new Date('2027-08-15'), status: 'ACTIVE' },
    { name: 'Vũ Quốc Bảo', email: 'bao.vu.store@gmail.com', device: 'Vivo V30e', version: '1.0.0', packagePlan: '1 Tháng', expiresAt: new Date('2026-09-28'), status: 'EXPIRED' },
  ];

  for (const u of sampleUsers) {
    await prisma.appDeviceUser.upsert({
      where: { email: u.email },
      update: u,
      create: u,
    });
  }
  console.log(`✓ Đã nạp thành công ${sampleUsers.length} Người Dùng & Thiết Bị.`);

  // 5. Merchant mặc định & Đơn hàng
  console.log('5. Đang nạp Merchant & Đơn hàng...');
  const merchant = await prisma.merchant.upsert({
    where: { slug: 'autobank-system' },
    update: {},
    create: {
      name: 'Đọc Thông Báo Nhận Tiền System',
      slug: 'autobank-system',
      secretKey: 'ak_live_9f8d7c6b5a4e3d2c1b0a_2026',
    },
  });

  await prisma.bankAccount.upsert({
    where: {
      merchantId_bankCode_accountNumber: {
        merchantId: merchant.id,
        bankCode: 'MB',
        accountNumber: '0869226687',
      },
    },
    update: {
      accountName: 'TRẦN QUỐC VŨ',
      isActive: true,
    },
    create: {
      merchantId: merchant.id,
      bankCode: 'MB',
      accountNumber: '0869226687',
      accountName: 'TRẦN QUỐC VŨ',
      isActive: true,
    },
  });

  const sampleOrders = [
    { orderCode: 'ORD-892104', totalAmount: 299000, paidAmount: 299000, status: 'PAID', description: 'Gói 1 Năm (299.000đ)', customerName: 'Nguyễn Văn An', customerPhone: '0988123456' },
    { orderCode: 'ORD-763412', totalAmount: 179000, paidAmount: 179000, status: 'PAID', description: 'Gói 6 Tháng (179.000đ)', customerName: 'Trần Thị Mai', customerPhone: '0977234567' },
    { orderCode: 'ORD-610298', totalAmount: 99000, paidAmount: 99000, status: 'PAID', description: 'Gói 3 Tháng (99.000đ)', customerName: 'Lê Hoàng Nam', customerPhone: '0912345678' },
    { orderCode: 'ORD-504933', totalAmount: 39000, paidAmount: 0, status: 'PENDING', description: 'Gói 1 Tháng (39.000đ)', customerName: 'Khách hàng MoMo', customerPhone: '0933456789' },
  ];

  for (const ord of sampleOrders) {
    await prisma.order.upsert({
      where: { orderCode: ord.orderCode },
      update: {
        totalAmount: ord.totalAmount,
        paidAmount: ord.paidAmount,
        status: ord.status,
        description: ord.description,
        customerName: ord.customerName,
        customerPhone: ord.customerPhone,
      },
      create: {
        merchantId: merchant.id,
        orderCode: ord.orderCode,
        totalAmount: ord.totalAmount,
        paidAmount: ord.paidAmount,
        status: ord.status,
        description: ord.description,
        customerName: ord.customerName,
        customerPhone: ord.customerPhone,
      },
    });
  }
  console.log(`✓ Đã nạp thành công các đơn hàng mẫu.`);

  // 6. Thông báo Push Broadcast mẫu
  await prisma.pushBroadcast.create({
    data: {
      type: 'system_update',
      title: 'Chào mừng bản cập nhật 1.2.0',
      body: 'Tối ưu tốc độ đọc thông báo nhận tiền xuống dưới 0.3s, tương thích 100% Android 14!',
      action: 'open_app',
    },
  });
  console.log(`✓ Đã nạp thông báo Push Broadcast.`);

  console.log('\n======================================================');
  console.log('✅ TOÀN BỘ DỮ LIỆU ĐÃ ĐƯỢC LƯU VÀO MYSQL (autobank) THÀNH CÔNG!');
  console.log('======================================================');
}

main()
  .catch((e) => {
    console.error('Lỗi khi nạp dữ liệu:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
