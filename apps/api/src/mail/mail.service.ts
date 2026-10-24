import { Injectable, Logger } from '@nestjs/common';
import * as nodemailer from 'nodemailer';

@Injectable()
export class MailService {
  private readonly logger = new Logger(MailService.name);
  private transporter: any = null;

  constructor() {
    this.initTransporter();
  }

  private initTransporter() {
    const host = process.env.SMTP_HOST || 'smtp.gmail.com';
    const port = parseInt(process.env.SMTP_PORT || '465', 10);
    const secure = process.env.SMTP_SECURE === 'true' || port === 465;
    const user = (process.env.SMTP_USER || '').trim();
    const pass = (process.env.SMTP_PASS || '').replace(/\s+/g, '').replace(/["']/g, '');

    if (user && pass) {
      try {
        this.transporter = nodemailer.createTransport({
          host,
          port,
          secure,
          auth: { user, pass },
        });
        this.logger.log(`[MailService] Khởi tạo SMTP Transporter thành công (${host}:${port}, user: ${user})`);
      } catch (err: any) {
        this.logger.error(`[MailService] Lỗi khởi tạo SMTP Transporter: ${err.message}`);
        this.transporter = null;
      }
    } else {
      this.logger.warn(
        `[MailService] Chưa cấu hình SMTP_USER / SMTP_PASS trong .env. Email sẽ được ghi log vào hệ thống.`,
      );
    }
  }

  /**
   * 1. GỬI MÃ OTP CẤP LẠI MÃ PIN 6 SỐ
   */
  async sendPinOtpEmail(to: string, otp: string): Promise<boolean> {
    const subject = `[AutoBank] Mã xác thực cấp lại mã PIN của bạn: ${otp}`;
    const html = `
      <div style="font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; max-width: 540px; margin: 0 auto; background: #ffffff; border: 1px solid #e2e8f0; border-radius: 16px; overflow: hidden; box-shadow: 0 4px 16px rgba(0,0,0,0.06);">
        <div style="background: linear-gradient(135deg, #0284c7 0%, #0369a1 100%); padding: 28px 24px; text-align: center; color: #ffffff;">
          <h1 style="margin: 0; font-size: 24px; font-weight: 800; letter-spacing: -0.5px;">AutoBank</h1>
          <p style="margin: 6px 0 0; font-size: 14px; opacity: 0.9;">Xác thực bảo mật tài khoản</p>
        </div>
        <div style="padding: 32px 24px;">
          <p style="margin: 0 0 16px; font-size: 15px; color: #334155; line-height: 1.6;">
            Xin chào bạn, chúng tôi nhận được yêu cầu <strong>cấp lại Mã PIN bảo vệ ứng dụng</strong> cho tài khoản <strong>${to}</strong>.
          </p>
          <div style="background: #f0fdf4; border: 1.5px dashed #22c55e; border-radius: 12px; padding: 20px; text-align: center; margin: 24px 0;">
            <span style="display: block; font-size: 13px; font-weight: 700; color: #15803d; text-transform: uppercase; letter-spacing: 0.5px;">Mã OTP Của Bạn</span>
            <span style="display: block; font-size: 38px; font-weight: 900; color: #166534; letter-spacing: 6px; margin: 8px 0;">${otp}</span>
            <span style="display: block; font-size: 12px; color: #64748b;">(Mã có hiệu lực trong 10 phút, vui lòng không chia sẻ cho bất kỳ ai)</span>
          </div>
          <p style="margin: 0 0 12px; font-size: 13px; color: #64748b; line-height: 1.5;">
            Nếu bạn không thực hiện yêu cầu này, vui lòng bỏ qua email hoặc đổi mật khẩu tài khoản Google để đảm bảo an toàn.
          </p>
        </div>
        <div style="background: #f8fafc; border-top: 1px solid #e2e8f0; padding: 16px 24px; text-align: center; font-size: 12px; color: #94a3b8;">
          AutoBank · Tiền vừa sang, máy báo vang · <a href="https://docthongbaobank.com" style="color: #0284c7; text-decoration: none;">docthongbaobank.com</a>
        </div>
      </div>
    `;

    return this.sendMail(to, subject, html);
  }

  /**
   * 2. GỬI HÓA ĐƠN & CHÚC MỪNG KÍCH HOẠT GÓI BẢN QUYỀN
   */
  async sendSubscriptionSuccessEmail(
    to: string,
    details: {
      packageName: string;
      amount: number;
      expiresAt: Date;
      orderCode: string;
    },
  ): Promise<boolean> {
    const formattedAmount = new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(details.amount);
    const expiryStr = details.expiresAt.getFullYear() > 2090
      ? 'Trọn đời (Vĩnh viễn)'
      : `${details.expiresAt.getDate().toString().padStart(2, '0')}/${(details.expiresAt.getMonth() + 1).toString().padStart(2, '0')}/${details.expiresAt.getFullYear()}`;

    const subject = `[AutoBank] Chúc mừng kích hoạt thành công Gói ${details.packageName}`;
    const html = `
      <div style="font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; max-width: 560px; margin: 0 auto; background: #ffffff; border: 1px solid #e2e8f0; border-radius: 16px; overflow: hidden; box-shadow: 0 4px 16px rgba(0,0,0,0.06);">
        <div style="background: linear-gradient(135deg, #10b981 0%, #059669 100%); padding: 28px 24px; text-align: center; color: #ffffff;">
          <h1 style="margin: 0; font-size: 24px; font-weight: 800;">🎉 KÍCH HOẠT THÀNH CÔNG!</h1>
          <p style="margin: 6px 0 0; font-size: 14px; opacity: 0.95;">Cảm ơn bạn đã tin tưởng dịch vụ AutoBank</p>
        </div>
        <div style="padding: 28px 24px;">
          <p style="margin: 0 0 16px; font-size: 15px; color: #334155; line-height: 1.6;">
            Xin chào <strong>${to}</strong>, hệ thống đã xác nhận thanh toán thành công và kích hoạt ngay bản quyền sử dụng cho bạn:
          </p>
          <table style="width: 100%; border-collapse: collapse; margin: 18px 0; font-size: 14px;">
            <tr style="border-bottom: 1px solid #f1f5f9;">
              <td style="padding: 10px 0; color: #64748b;">Mã đơn hàng:</td>
              <td style="padding: 10px 0; text-align: right; font-weight: 700; color: #0f172a;">${details.orderCode}</td>
            </tr>
            <tr style="border-bottom: 1px solid #f1f5f9;">
              <td style="padding: 10px 0; color: #64748b;">Gói bản quyền:</td>
              <td style="padding: 10px 0; text-align: right; font-weight: 700; color: #0284c7;">${details.packageName}</td>
            </tr>
            <tr style="border-bottom: 1px solid #f1f5f9;">
              <td style="padding: 10px 0; color: #64748b;">Số tiền thanh toán:</td>
              <td style="padding: 10px 0; text-align: right; font-weight: 700; color: #16a34a;">${formattedAmount}</td>
            </tr>
            <tr>
              <td style="padding: 10px 0; color: #64748b;">Hạn sử dụng đến:</td>
              <td style="padding: 10px 0; text-align: right; font-weight: 700; color: #d97706;">${expiryStr}</td>
            </tr>
          </table>
          <div style="text-align: center; margin-top: 24px;">
            <a href="https://docthongbaobank.com" style="display: inline-block; background: #0284c7; color: #ffffff; padding: 12px 28px; border-radius: 10px; font-weight: 700; text-decoration: none; font-size: 14px;">Mở Ứng Dụng Ngay</a>
          </div>
        </div>
        <div style="background: #f8fafc; border-top: 1px solid #e2e8f0; padding: 16px 24px; text-align: center; font-size: 12px; color: #94a3b8;">
          AutoBank · Tiền vừa sang, máy báo vang · Hotline / Zalo: 0393.208.528
        </div>
      </div>
    `;

    return this.sendMail(to, subject, html);
  }

  /**
   * 3. GỬI EMAIL NHẮC NHỞ SẮP HẾT HẠN BẢN QUYỀN
   */
  async sendSubscriptionExpiryWarningEmail(
    to: string,
    details: {
      packageName: string;
      daysLeft: number;
      expiresAt: Date;
    },
  ): Promise<boolean> {
    const expiryStr = `${details.expiresAt.getDate().toString().padStart(2, '0')}/${(details.expiresAt.getMonth() + 1).toString().padStart(2, '0')}/${details.expiresAt.getFullYear()}`;
    const subject = `[AutoBank Nhắc Nhở] Gói bản quyền của bạn sẽ hết hạn sau ${details.daysLeft} ngày`;
    const html = `
      <div style="font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; max-width: 540px; margin: 0 auto; background: #ffffff; border: 1px solid #e2e8f0; border-radius: 16px; overflow: hidden;">
        <div style="background: #f59e0b; padding: 24px; text-align: center; color: #ffffff;">
          <h2 style="margin: 0; font-size: 20px;">⚠️ NHẮC NHỞ GIA HẠN DỊCH VỤ</h2>
        </div>
        <div style="padding: 24px;">
          <p style="font-size: 14px; color: #334155; line-height: 1.6;">
            Xin chào <strong>${to}</strong>, gói <strong>${details.packageName}</strong> của bạn trên hệ thống AutoBank sẽ hết hạn vào ngày <strong>${expiryStr}</strong> (còn <strong>${details.daysLeft} ngày</strong>).
          </p>
          <p style="font-size: 14px; color: #334155; line-height: 1.6;">
            Để tính năng đọc thông báo nhận tiền và đồng bộ sổ sách không bị gián đoạn tại quầy, vui lòng truy cập ứng dụng để gia hạn.
          </p>
          <div style="text-align: center; margin-top: 20px;">
            <a href="https://docthongbaobank.com" style="display: inline-block; background: #0284c7; color: #ffffff; padding: 10px 24px; border-radius: 8px; font-weight: 700; text-decoration: none;">Gia Hạn Bản Quyền</a>
          </div>
        </div>
      </div>
    `;
    return this.sendMail(to, subject, html);
  }

  /**
   * 4. GỬI EMAIL THÔNG BÁO SẮP HẾT HẠN DÙNG THỬ 3 NGÀY & TẶNG MÃ NGUOIMOI GIẢM 10%
   */
  async sendTrialExpiringEmail(
    to: string,
    details: {
      hoursLeft: number;
      expiresAt: Date;
      couponCode?: string;
      discountPercent?: number;
    },
  ): Promise<boolean> {
    const code = details.couponCode || 'NGUOIMOI';
    const pct = details.discountPercent || 10;
    const hours = Math.max(1, Math.round(details.hoursLeft));
    const expiryStr = `${details.expiresAt.getHours().toString().padStart(2, '0')}:${details.expiresAt.getMinutes().toString().padStart(2, '0')} ngày ${details.expiresAt.getDate().toString().padStart(2, '0')}/${(details.expiresAt.getMonth() + 1).toString().padStart(2, '0')}/${details.expiresAt.getFullYear()}`;

    const subject = `⏳ [Ưu Đãi Tân Thủ] Gói dùng thử AutoBank của bạn sắp hết hạn - Giảm ngay ${pct}% với mã ${code}`;
    const html = `
      <div style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; max-width: 560px; margin: 0 auto; background: #ffffff; border: 1px solid #e2e8f0; border-radius: 20px; overflow: hidden; box-shadow: 0 8px 30px rgba(0,0,0,0.08);">
        <!-- Header -->
        <div style="background: linear-gradient(135deg, #ea580c 0%, #dc2626 50%, #991b1b 100%); padding: 32px 24px; text-align: center; color: #ffffff;">
          <div style="display: inline-block; background: rgba(255,255,255,0.2); padding: 6px 14px; border-radius: 999px; font-size: 12px; font-weight: 800; letter-spacing: 0.5px; text-transform: uppercase; margin-bottom: 12px;">
            ⏳ THÔNG BÁO QUAN TRỌNG
          </div>
          <h1 style="margin: 0; font-size: 23px; font-weight: 900; line-height: 1.3;">Gói Dùng Thử Của Bạn Sắp Hết Hạn!</h1>
          <p style="margin: 8px 0 0; font-size: 14px; opacity: 0.95;">Chỉ còn khoảng <strong>${hours} giờ</strong> để nâng cấp với ưu đãi đặc quyền</p>
        </div>

        <!-- Body -->
        <div style="padding: 32px 24px;">
          <p style="margin: 0 0 16px; font-size: 15px; color: #1e293b; line-height: 1.6;">
            Xin chào <strong>${to}</strong>,<br>
            Thời gian <strong>3 ngày trải nghiệm miễn phí 100% tính năng</strong> trên ứng dụng <em>Đọc Thông Báo Nhận Tiền AutoBank</em> của bạn sẽ kết thúc vào lúc <strong>${expiryStr}</strong>.
          </p>
          <p style="margin: 0 0 20px; font-size: 14px; color: #475569; line-height: 1.6;">
            Khi gói dùng thử kết thúc, tính năng phát loa giọng đọc biến động số dư và đồng bộ tài khoản sẽ tạm ngưng. Để việc kinh doanh tại quầy không bị gián đoạn, hãy nâng cấp gói bản quyền ngay hôm nay!
          </p>

          <!-- Voucher Box -->
          <div style="background: linear-gradient(135deg, #fff7ed 0%, #fef2f2 100%); border: 2px dashed #f97316; border-radius: 16px; padding: 22px 20px; text-align: center; margin: 24px 0;">
            <span style="display: block; font-size: 12px; font-weight: 800; color: #ea580c; text-transform: uppercase; letter-spacing: 0.5px;">
              🎁 QUÀ TẶNG DÀNH RIÊNG CHO THÀNH VIÊN MỚI
            </span>
            <div style="margin: 12px auto; display: inline-block; background: #ffffff; border: 1.5px solid #fdba74; padding: 10px 22px; border-radius: 10px; box-shadow: 0 4px 10px rgba(234, 88, 12, 0.1);">
              <span style="font-family: monospace; font-size: 26px; font-weight: 900; color: #c2410c; letter-spacing: 4px;">${code}</span>
            </div>
            <p style="margin: 6px 0 0; font-size: 14px; font-weight: 700; color: #9a3412;">
              GIẢM NGAY ${pct}% CHO TẤT CẢ CÁC GÓI CƯỚC (1 Tháng, 3 Tháng, 6 Tháng, 1 Năm)
            </p>
            <p style="margin: 4px 0 0; font-size: 12px; color: #94a3b8;">
              (Áp dụng trực tiếp tại mục Đăng ký trong ứng dụng hoặc trên website)
            </p>
          </div>

          <!-- CTA Buttons -->
          <div style="text-align: center; margin-top: 28px;">
            <a href="https://docthongbaobank.com/#pricing" style="display: inline-block; background: linear-gradient(135deg, #0284c7 0%, #0369a1 100%); color: #ffffff; padding: 14px 32px; border-radius: 12px; font-weight: 800; text-decoration: none; font-size: 15px; box-shadow: 0 4px 14px rgba(2, 132, 199, 0.35);">
              🚀 Nâng Cấp Ngay Với Mã ${code} (-${pct}%)
            </a>
            <div style="margin-top: 12px;">
              <a href="https://play.google.com/store/apps/details?id=com.docthongbaobank.app" style="color: #64748b; font-size: 13px; text-decoration: underline;">
                Mở ứng dụng trên Android
              </a>
            </div>
          </div>
        </div>

        <!-- Footer -->
        <div style="background: #f8fafc; border-top: 1px solid #e2e8f0; padding: 20px 24px; text-align: center; font-size: 12px; color: #94a3b8; line-height: 1.5;">
          AutoBank · Hệ thống Đọc Thông Báo Nhận Tiền 24/7<br>
          Website: <a href="https://docthongbaobank.com" style="color: #0284c7; text-decoration: none; font-weight: 600;">docthongbaobank.com</a> · Hỗ trợ Zalo/Hotline 24/7
        </div>
      </div>
    `;

    return this.sendMail(to, subject, html);
  }

  private async sendMail(to: string, subject: string, html: string): Promise<boolean> {
    const from = process.env.SMTP_FROM || 'AutoBank <docthongbaobank@gmail.com>';
    if (this.transporter) {
      try {
        await this.transporter.sendMail({
          from,
          to,
          subject,
          html,
        });
        this.logger.log(`[MailService] Đã gửi thành công email tới ${to} (Tiêu đề: ${subject})`);
        return true;
      } catch (err: any) {
        this.logger.error(`[MailService] Lỗi khi gửi email qua SMTP: ${err.message}`);
        // Fallback: log nội dung email để xem xét
        this.logger.log(`[MailService Log Fallback]: To: ${to} | Subject: ${subject}`);
        return false;
      }
    } else {
      this.logger.log(`[MailService Console Sim]: To: ${to} | Subject: ${subject}`);
      return true;
    }
  }
}
