import { Injectable, UnauthorizedException, ForbiddenException, Logger } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service.js';
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

  constructor(private readonly prisma: PrismaService) {}

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

    // Xác thực Google Client ID nếu đã cấu hình trong .env
    const configuredClientId = process.env.GOOGLE_CLIENT_ID;
    if (configuredClientId) {
      if (data.aud !== configuredClientId) {
        this.logger.warn(`Audience mismatch: expected ${configuredClientId}, received ${data.aud}`);
        throw new UnauthorizedException('Google Client ID (Audience) không trùng khớp với cấu hình hệ thống');
      }
    } else {
      this.logger.warn('CẢNH BÁO: GOOGLE_CLIENT_ID chưa cấu hình trong .env (xem GOOGLE_OAUTH_SETUP.md)');
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

      // Cập nhật thông tin thiết bị nếu có
      user = await this.prisma.appDeviceUser.update({
        where: { email: googleUser.email },
        data: {
          name: googleUser.name || user.name,
          device: dto.deviceName || user.device,
          deviceId: dto.deviceId || user.deviceId,
          phone: dto.phone || user.phone,
          shopName: dto.shopName || user.shopName,
        },
      });
    } else {
      // Người dùng mới: cấp 3 ngày dùng thử miễn phí
      const trialExpiry = new Date(Date.now() + 3 * 86400000);
      user = await this.prisma.appDeviceUser.create({
        data: {
          name: googleUser.name,
          email: googleUser.email,
          device: dto.deviceName || 'Thiết bị di động',
          deviceId: dto.deviceId,
          version: '1.2.0',
          packagePlan: 'Dùng thử 3 ngày',
          hasUsedTrial: true,
          expiresAt: trialExpiry,
          status: 'ACTIVE',
          phone: dto.phone,
          shopName: dto.shopName || `Cửa hàng ${googleUser.name}`,
        },
      });
    }

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
      isExpired: new Date(user.expiresAt) < new Date(),
    };
  }
}
