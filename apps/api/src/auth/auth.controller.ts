import { Controller, Post, Get, Body, Headers, UnauthorizedException } from '@nestjs/common';
import { AuthService } from './auth.service.js';

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

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
}
