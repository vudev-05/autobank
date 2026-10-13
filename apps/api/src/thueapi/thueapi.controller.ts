import { Controller, Post, Get, Body, Headers } from '@nestjs/common';
import { ThueApiService, ThueApiWebhookDto } from './thueapi.service.js';

@Controller()
export class ThueApiController {
  constructor(private readonly thueApiService: ThueApiService) {}

  /**
   * Endpoint tiếp nhận Webhook biến động số dư từ ThueApi.Pro
   */
  @Post('webhooks/thueapi')
  async receiveWebhook(
    @Body() payload: ThueApiWebhookDto,
    @Headers('x-signature') signature?: string,
  ) {
    return this.thueApiService.handleWebhook(payload, signature);
  }

  /**
   * Admin lấy cấu hình kết nối ThueApi.Pro
   */
  @Get('admin/thueapi/config')
  async getConfig() {
    return this.thueApiService.getConfig();
  }

  /**
   * Admin cập nhật cấu hình ThueApi.Pro
   */
  @Post('admin/thueapi/config')
  async updateConfig(@Body() body: any) {
    return this.thueApiService.updateConfig(body);
  }

  /**
   * Admin kiểm tra kết nối với nhà cung cấp ThueApi.Pro
   */
  @Post('admin/thueapi/test')
  async testConnection() {
    return this.thueApiService.testConnection();
  }

  /**
   * Admin xem nhật ký Webhook ThueApi.Pro
   */
  @Get('admin/thueapi/webhooks')
  async getWebhookLogs() {
    return this.thueApiService.getWebhookLogs();
  }
}
