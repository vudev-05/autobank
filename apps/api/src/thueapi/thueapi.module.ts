import { Module } from '@nestjs/common';
import { ThueApiController } from './thueapi.controller.js';
import { ThueApiService } from './thueapi.service.js';
import { AdminModule } from '../admin/admin.module.js';
import { AuthModule } from '../auth/auth.module.js';

@Module({
  imports: [AdminModule, AuthModule],
  controllers: [ThueApiController],
  providers: [ThueApiService],
  exports: [ThueApiService],
})
export class ThueApiModule {}
