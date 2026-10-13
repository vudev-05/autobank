import { Module } from '@nestjs/common';
import { ThueApiController } from './thueapi.controller.js';
import { ThueApiService } from './thueapi.service.js';

@Module({
  controllers: [ThueApiController],
  providers: [ThueApiService],
  exports: [ThueApiService],
})
export class ThueApiModule {}
