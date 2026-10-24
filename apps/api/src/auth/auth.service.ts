import { Injectable, UnauthorizedException, ForbiddenException, HttpException, HttpStatus, Logger } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service.js';
import { MailService } from '../mail/mail.service.js';
import crypto from 'node:crypto';

export interface JwtPayload {
  email: string;
  sub: string;
  name?: string;
  role?: string;
  exp?: number;
  iat?: number;
}

@Injectable()
export class AuthService {
  private readonly logger = new Logger(AuthService.name);
  private readonly jwtSecret = process.env.JWT_SECRET || 'autobank_pro_production_secret_key_2026';

  constructor(
    private readonly prisma: PrismaService,
    private readonly mailService: MailService,
  ) {}

  /**
   * Tạo JWT Token an toàn theo chuẩn RFC 7519
   */
  signToken(payload: { email: string; sub: string; name?: string; role?: string }, expiresInSec = 86400 * 30): string {
    const base64url = (str: string) =>
      Buffer.from(str)
        .toString('base64')
        .replace(/=/g, '')
        .replace(/\+/g, '-')
        .replace(/\//g, '_');

    const header = base64url(JSON.stringify({ alg: 'HS256', typ: 'JWT' }));
    const iat = Math.floor(Date.now() / 1000);
    const exp = iat + expiresInSec;
    const body = base64url(JSON.stringify({ ...payload, exp, iat }));
    const signature = crypto
      .createHmac('sha256', this.jwtSecret)
      .update(`${header}.${body}`)
      .digest('base64')
      .replace(/=/g, '')
      .replace(/\+/g, '-')
      .replace(/\//g, '_');

    return `${header}.${body}.${signature}`;
  }

  /**
   * Xác minh JWT Token và giải mã payload
   */
  verifyToken(token: string): JwtPayload {
    if (!token) {
      throw new UnauthorizedException('Thiếu token xác thực');
    }
    const parts = token.split('.');
    if (parts.length !== 3) {
      throw new UnauthorizedException('Token không đúng định dạng');
    }

    const [header, body, signature] = parts;
    const expectedSig = crypto
      .createHmac('sha256', this.jwtSecret)
      .update(`${header}.${body}`)
      .digest('base64')
      .replace(/=/g, '')
      .replace(/\+/g, '-')
      .replace(/\//g, '_');

    if (signature !== expectedSig) {
      throw new UnauthorizedException('Chữ ký xác thực token không hợp lệ');
    }

    try {
      const payload: JwtPayload = JSON.parse(Buffer.from(body, 'base64').toString('utf8'));
      if (payload.exp && payload.exp * 1000 < Date.now()) {
        throw new UnauthorizedException('Phiên đăng nhập đã hết hạn, vui lòng đăng nhập lại');
      }
      return payload;
    } catch {
      throw new UnauthorizedException('Không thể giải mã dữ liệu token');
    }
  }

  /**
   * Xác thực Google ID Token với Google OAuth API chính thức
   */
  async verifyGoogleIdToken(idToken: string): Promise<{
    email: string;
    sub: string;
    name: string;
    picture?: string;
  }> {
    if (!idToken || typeof idToken !== 'string') {
      throw new UnauthorizedException('Google ID Token không được để trống');
    }

    const googleEndpoint = `https://oauth2.googleapis.com/tokeninfo?id_token=${encodeURIComponent(idToken.trim())}`;
    
    let res: Response;
    try {
      res = await fetch(googleEndpoint, { method: 'GET' });
    } catch (err) {
      this.logger.error(`Lỗi kết nối tới máy chủ Google OAuth: ${err}`);
      throw new UnauthorizedException('Không thể kết nối đến máy chủ xác thực Google. Vui lòng thử lại sau.');
    }

    if (!res.ok) {
      throw new UnauthorizedException('Google ID Token không hợp lệ hoặc đã hết hạn');
    }

    const data: any = await res.json();

    if (!data.email || !data.sub) {
      throw new UnauthorizedException('Dữ liệu xác thực tài khoản Google không đầy đủ thông tin bắt buộc');
    }

    // Xác thực issuer
    const validIssuers = ['accounts.google.com', 'https://accounts.google.com'];
    if (data.iss && !validIssuers.includes(data.iss)) {
      throw new UnauthorizedException('Issuer tài khoản Google không hợp lệ');
    }

    // Xác thực Google Client ID: Chấp nhận Web Client ID, Android Client ID hoặc cùng Project Google Cloud
    const configuredClientId = process.env.GOOGLE_CLIENT_ID;
    const androidClientId = process.env.GOOGLE_ANDROID_CLIENT_ID || '326124862102-mbibb162b8dp9fnoqij6ms3k3ba6mc71.apps.googleusercontent.com';
    const webClientId = '326124862102-oddd2tnbc6he6fk820bc15n3kpte3uo6.apps.googleusercontent.com';

    const validClients = [configuredClientId, androidClientId, webClientId].filter(Boolean);
    const tokenAud = data.aud || '';
    const tokenAzp = data.azp || '';

    const isAudValid = validClients.some(cid => cid && (tokenAud === cid || tokenAzp === cid)) ||
                       tokenAud.includes('326124862102') ||
                       tokenAzp.includes('326124862102');

    if (!isAudValid) {
      this.logger.warn(`Audience mismatch: expected one of ${JSON.stringify(validClients)}, received aud=${tokenAud}, azp=${tokenAzp}`);
      throw new UnauthorizedException('Google Client ID (Audience) không trùng khớp với cấu hình hệ thống');
    }

    return {
      email: data.email,
      sub: data.sub,
      name: data.name || data.email.split('@')[0],
      picture: data.picture,
    };
  }

  /**
   * Đăng nhập hoặc đăng ký tài khoản qua Google Token
   */
  async loginWithGoogle(dto: {
    idToken: string;
    deviceId?: string;
    deviceName?: string;
    shopName?: string;
    phone?: string;
  }) {
    const googleUser = await this.verifyGoogleIdToken(dto.idToken);

    let user = await this.prisma.appDeviceUser.findUnique({
      where: { email: googleUser.email },
    });

    if (user) {
      if (user.status === 'BLOCKED') {
        throw new ForbiddenException('Tài khoản của bạn đã bị tạm khóa bởi Quản trị viên. Vui lòng liên hệ hỗ trợ!');
      }

      // Cập nhật thông tin thiết bị nếu có - Luôn giữ nguyên tên quán đã lưu trong MySQL
      user = await this.prisma.appDeviceUser.update({
        where: { email: googleUser.email },
        data: {
          name: googleUser.name || user.name,
          device: dto.deviceName || user.device,
          deviceId: dto.deviceId || user.deviceId,
          phone: user.phone || dto.phone,
          shopName: user.shopName || dto.shopName,
        },
      });
    } else {
      // Người dùng mới: Chưa chọn gói, chưa kích hoạt dùng thử!
      // Bắt buộc người dùng phải chọn gói ngay trên app trước khi được vào dùng.
      const yesterday = new Date(Date.now() - 86400000);
      user = await this.prisma.appDeviceUser.create({
        data: {
          name: googleUser.name,
          email: googleUser.email,
          device: dto.deviceName || 'Thiết bị di động',
          deviceId: dto.deviceId,
          version: '1.2.0',
          packagePlan: 'Chưa kích hoạt gói',
          hasUsedTrial: false,
          expiresAt: yesterday,
          status: 'PENDING_PLAN',
          phone: dto.phone,
          shopName: dto.shopName || `Cửa hàng ${googleUser.name}`,
        },
      });
    }

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

    const token = this.signToken({
      email: user.email,
      sub: user.id,
      name: user.name,
      role: 'USER',
    });

    return {
      success: true,
      token,
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        device: user.device,
        deviceId: user.deviceId,
        phone: user.phone,
        shopName: user.shopName,
        packagePlan: user.packagePlan,
        hasUsedTrial: user.hasUsedTrial,
        expiresAt: user.expiresAt,
        status: user.status,
        createdAt: user.createdAt,
      },
    };
  }

  /**
   * Lấy thông tin tài khoản hiện tại từ session token
   */
  async getProfile(email: string) {
    const user = await this.prisma.appDeviceUser.findUnique({
      where: { email },
    });

    if (!user) {
      throw new UnauthorizedException('Không tìm thấy tài khoản người dùng trong hệ thống');
    }

    if (user.status === 'BLOCKED') {
      throw new ForbiddenException('Tài khoản đã bị tạm khóa bởi quản trị viên');
    }

    return {
      id: user.id,
      name: user.name,
      email: user.email,
      device: user.device,
      deviceId: user.deviceId,
      phone: user.phone,
      shopName: user.shopName,
      packagePlan: user.packagePlan,
      hasUsedTrial: user.hasUsedTrial,
      expiresAt: user.expiresAt,
      status: user.status,
      createdAt: user.createdAt,
      isExpired: new Date(user.expiresAt) < new Date(),
    };
  }

  // Bộ nhớ bảo vệ chống brute-force đăng nhập quản trị
  private adminLoginAttempts = new Map<string, { count: number; lockedUntil: number }>();

  /**
   * Đăng nhập Quản trị viên an toàn (xác thực backend + chống brute force)
   */
  async loginAdmin(dto: { username: string; password: string; clientIp?: string }) {
    const cleanUser = (dto.username || '').trim();
    const cleanPass = (dto.password || '').trim();
    const key = `${cleanUser}_${dto.clientIp || 'unknown'}`;
    const now = Date.now();
    const record = this.adminLoginAttempts.get(key) || { count: 0, lockedUntil: 0 };

    if (record.lockedUntil > now) {
      const waitMin = Math.ceil((record.lockedUntil - now) / 60000);
      throw new HttpException(
        `Phát hiện hành vi dò mật khẩu bất thường. Tài khoản tạm khóa bảo mật trong ${waitMin} phút!`,
        HttpStatus.TOO_MANY_REQUESTS,
      );
    }

    const envUser = process.env.ADMIN_USERNAME || 'admin';
    const envPass = process.env.ADMIN_PASSWORD || 'autobank@2026';

    let isValid = false;

    // 1. Kiểm tra tài khoản admin trong database
    try {
      const adminAcc = await this.prisma.adminAccount.findUnique({
        where: { username: cleanUser },
      });
      if (adminAcc && adminAcc.password === cleanPass) {
        isValid = true;
      }
    } catch (_) {}

    // 2. Kiểm tra fallback từ biến môi trường máy chủ
    if (!isValid && cleanUser === envUser && cleanPass === envPass) {
      isValid = true;
    }

    if (!isValid) {
      record.count += 1;
      if (record.count >= 5) {
        record.lockedUntil = now + 15 * 60 * 1000; // Khóa 15 phút
        this.adminLoginAttempts.set(key, record);
        this.logger.warn(`[Security Alert] Admin login brute force attempt from IP ${dto.clientIp || 'unknown'} - LOCKED for 15m`);
        throw new HttpException(
          'Đã nhập sai mật khẩu quá 5 lần! Hệ thống tạm thời khóa đăng nhập 15 phút để bảo vệ máy chủ.',
          HttpStatus.TOO_MANY_REQUESTS,
        );
      }
      this.adminLoginAttempts.set(key, record);
      throw new UnauthorizedException(`Tài khoản hoặc mật khẩu quản trị không chính xác (Còn ${5 - record.count} lần thử)`);
    }

    // Đăng nhập thành công -> Xóa bản ghi đếm số lần sai
    this.adminLoginAttempts.delete(key);

    // Ký token JWT đặc quyền SUPER_ADMIN
    const token = this.signToken(
      {
        email: cleanUser,
        sub: 'super_admin_id',
        name: 'Quản trị viên hệ thống',
        role: 'SUPER_ADMIN',
      },
      86400 * 7, // 7 ngày
    );

    return {
      success: true,
      token,
      role: 'SUPER_ADMIN',
      username: cleanUser,
      message: 'Đăng nhập Quản trị viên thành công',
    };
  }

  // Quản lý mã OTP cấp lại PIN trong bộ nhớ với thời hạn 10 phút và cooldown 60 giây chống spam
  private static otpMap = new Map<string, { otp: string; expiresAt: number; lastSentAt: number }>();

  /**
   * Gửi mã OTP 6 số về Gmail thật của người dùng
   */
  async sendPinResetOtp(email: string): Promise<{ success: boolean; message: string; cooldownSec?: number }> {
    const cleanEmail = (email || '').trim().toLowerCase();
    if (!cleanEmail || !cleanEmail.includes('@')) {
      throw new HttpException('Email không hợp lệ', HttpStatus.BAD_REQUEST);
    }

    const now = Date.now();
    const existing = AuthService.otpMap.get(cleanEmail);
    if (existing && now - existing.lastSentAt < 60000) {
      const waitSec = Math.ceil((60000 - (now - existing.lastSentAt)) / 1000);
      throw new HttpException(
        `Vui lòng đợi ${waitSec} giây trước khi yêu cầu gửi lại mã OTP mới`,
        HttpStatus.TOO_MANY_REQUESTS,
      );
    }

    // Sinh mã OTP 6 số ngẫu nhiên
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    const expiresAt = now + 10 * 60 * 1000; // 10 phút

    AuthService.otpMap.set(cleanEmail, {
      otp,
      expiresAt,
      lastSentAt: now,
    });

    // Gửi email thực qua MailService
    await this.mailService.sendPinOtpEmail(cleanEmail, otp);

    return {
      success: true,
      message: `Đã gửi mã xác thực OTP 6 số tới hộp thư ${cleanEmail}. Vui lòng kiểm tra Gmail.`,
    };
  }

  /**
   * Xác thực mã OTP 6 số khi đặt lại mã PIN
   */
  async verifyPinResetOtp(email: string, otp: string): Promise<{ success: boolean; message: string }> {
    const cleanEmail = (email || '').trim().toLowerCase();
    const cleanOtp = (otp || '').trim();

    const record = AuthService.otpMap.get(cleanEmail);
    if (!record) {
      throw new HttpException(
        'Không tìm thấy yêu cầu cấp lại mã PIN hoặc mã đã hết hạn. Vui lòng gửi lại yêu cầu.',
        HttpStatus.BAD_REQUEST,
      );
    }

    if (Date.now() > record.expiresAt) {
      AuthService.otpMap.delete(cleanEmail);
      throw new HttpException(
        'Mã OTP đã hết hạn (quá 10 phút). Vui lòng yêu cầu mã mới.',
        HttpStatus.BAD_REQUEST,
      );
    }

    if (record.otp !== cleanOtp) {
      throw new HttpException('Mã OTP không chính xác. Vui lòng kiểm tra lại.', HttpStatus.BAD_REQUEST);
    }

    // Xác thực thành công -> xóa mã để chống dùng lại
    AuthService.otpMap.delete(cleanEmail);

    return {
      success: true,
      message: 'Xác thực OTP thành công. Bạn có thể tiến hành đổi mã PIN bảo vệ mới.',
    };
  }
}
