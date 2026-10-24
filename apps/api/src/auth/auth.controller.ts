import { Controller, Post, Get, Body, Headers, Req, UnauthorizedException } from '@nestjs/common';
import type { Request } from 'express';
import { AuthService } from './auth.service.js';

@Controller(['auth', 'api/auth'])
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  /**
   * Đăng nhập Quản trị viên an toàn (Backend Authentication + JWT)
   */
  @Post('admin/login')
  async loginAdmin(
    @Body() body: { username?: string; password?: string },
    @Req() req: Request,
  ) {
    if (!body || !body.username || !body.password) {
      throw new UnauthorizedException('Vui lòng nhập đầy đủ tài khoản và mật khẩu quản trị');
    }
    const clientIp = (req.headers['x-forwarded-for'] as string) || req.socket?.remoteAddress || req.ip;
    return this.authService.loginAdmin({
      username: body.username,
      password: body.password,
      clientIp,
    });
  }

  /**
   * Đăng nhập / Xác thực tài khoản bằng Google ID Token
   */
  @Post('google')
  async loginWithGoogle(
    @Body()
    body: {
      idToken: string;
      deviceId?: string;
      deviceName?: string;
      shopName?: string;
      phone?: string;
    },
  ) {
    if (!body || !body.idToken) {
      throw new UnauthorizedException('Yêu cầu cung cấp idToken của Google để xác thực');
    }
    return this.authService.loginWithGoogle(body);
  }

  /**
   * Lấy thông tin tài khoản đang đăng nhập từ Bearer Token
   */
  @Get('me')
  async getProfile(@Headers('authorization') authHeader: string) {
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      throw new UnauthorizedException('Thiếu Bearer Token trong tiêu đề Authorization');
    }
    const token = authHeader.substring(7).trim();
    const payload = this.authService.verifyToken(token);
    return this.authService.getProfile(payload.email);
  }

  /**
   * Đăng xuất phiên làm việc
   */
  @Post('logout')
  logout() {
    return {
      success: true,
      message: 'Đăng xuất tài khoản thành công',
    };
  }

  /**
   * Kiểm tra tính hợp lệ của token
   */
  @Post('verify-token')
  verifyToken(@Body('token') token: string) {
    if (!token) {
      throw new UnauthorizedException('Token không được để trống');
    }
    const payload = this.authService.verifyToken(token);
    return {
      valid: true,
      payload,
    };
  }

  /**
   * Gửi mã OTP cấp lại PIN về Gmail thật
   */
  @Post('send-pin-otp')
  async sendPinOtp(@Body('email') email: string) {
    return this.authService.sendPinResetOtp(email);
  }

  /**
   * Xác thực mã OTP 6 số để đổi mã PIN
   */
  @Post('verify-pin-otp')
  async verifyPinOtp(@Body() body: { email: string; otp: string }) {
    return this.authService.verifyPinResetOtp(body.email, body.otp);
  }
}
