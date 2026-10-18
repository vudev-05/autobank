import {
  Injectable,
  CanActivate,
  ExecutionContext,
  UnauthorizedException,
  ForbiddenException,
  SetMetadata,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { AuthService } from '../auth/auth.service.js';

export const IS_PUBLIC_KEY = 'isPublic';
export const Public = () => SetMetadata(IS_PUBLIC_KEY, true);

@Injectable()
export class AdminGuard implements CanActivate {
  constructor(
    private readonly authService: AuthService,
    private readonly reflector: Reflector,
  ) {}

  canActivate(context: ExecutionContext): boolean {
    const isPublic = this.reflector.getAllAndOverride<boolean>(IS_PUBLIC_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);

    if (isPublic) {
      return true;
    }

    const request = context.switchToHttp().getRequest();
    const authHeader = request.headers['authorization'];

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      throw new UnauthorizedException('Yêu cầu Token Quản trị viên trong tiêu đề Authorization');
    }

    const token = authHeader.substring(7).trim();
    try {
      const payload = this.authService.verifyToken(token);
      if (payload.role !== 'SUPER_ADMIN') {
        throw new ForbiddenException('Bạn không có quyền Quản trị viên để thực hiện thao tác này');
      }
      request.admin = payload;
      return true;
    } catch (err: any) {
      throw new UnauthorizedException(err.message || 'Phiên quản trị không hợp lệ hoặc đã hết hạn');
    }
  }
}
