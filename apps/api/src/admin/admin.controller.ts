import { Controller, Get, Post, Body, Param, Delete, Put, UseGuards } from '@nestjs/common';
import { AdminService } from './admin.service.js';
import { AdminGuard, Public } from './admin.guard.js';

@Controller(['admin', 'api/admin', 'api'])
@UseGuards(AdminGuard)
export class AdminController {
  constructor(private readonly adminService: AdminService) {}

  @Public()
  @Get(['configs', 'config'])
  async getConfig() {
    return this.adminService.getConfig();
  }

  @Post(['configs', 'config'])
  async updateConfig(@Body() body: any) {
    return this.adminService.updateConfig(body);
  }

  @Public()
  @Get('banks')
  async getBanks() {
    return this.adminService.getBanks();
  }

  @Post('banks')
  async saveBank(@Body() body: any) {
    return this.adminService.saveBank(body);
  }

  @Delete('banks/:id')
  async deleteBank(@Param('id') id: string) {
    return this.adminService.deleteBank(id);
  }

  @Put('banks/:id/toggle')
  async toggleBank(@Param('id') id: string) {
    return this.adminService.toggleBank(id);
  }

  @Public()
  @Post('users')
  async upsertUser(@Body() body: any) {
    return this.adminService.upsertUser(body);
  }

  @Get('users')
  async getUsers() {
    return this.adminService.getUsers();
  }

  @Public()
  @Get('users/:email')
  async getUserByEmail(@Param('email') email: string) {
    return this.adminService.getUserByEmail(email);
  }

  @Put('users/:email/extend')
  async extendUser(@Param('email') email: string, @Body('days') days: number) {
    return this.adminService.extendUser(email, days || 30);
  }

  @Put('users/:email/toggle-block')
  async toggleBlockUser(@Param('email') email: string) {
    return this.adminService.toggleBlockUser(email);
  }

  @Delete('users/:email')
  async deleteUser(@Param('email') email: string) {
    return this.adminService.deleteUser(email);
  }

  @Get('stats')
  async getStats() {
    return this.adminService.getStats();
  }

  @Get('logs')
  async getLogs() {
    return this.adminService.getLogs();
  }

  @Get('orders')
  async getOrders() {
    return this.adminService.getOrders();
  }

  @Post('orders')
  async createOrder(@Body() body: any) {
    return this.adminService.createOrder(body);
  }

  @Put('orders/:orderCode/approve')
  async approveOrder(@Param('orderCode') orderCode: string) {
    return this.adminService.approveOrder(orderCode);
  }

  @Delete('orders/:orderCode')
  async deleteOrder(@Param('orderCode') orderCode: string) {
    return this.adminService.deleteOrder(orderCode);
  }

  @Public()
  @Get('live-pin')
  async getLivePin() {
    return await this.adminService.getLivePin();
  }

  @Public()
  @Post('live-pin')
  async setLivePin(@Body('pin') pin: string, @Body('email') email?: string) {
    return await this.adminService.setLivePin(pin, email);
  }

  @Public()
  @Post('verify-live-pin')
  async verifyLivePin(@Body('pin') pin: string, @Body('email') email?: string) {
    return await this.adminService.verifyLivePin(pin, email);
  }

  @Public()
  @Post('phone-heartbeat')
  recordPhoneHeartbeat(@Body() body: any) {
    return this.adminService.recordPhoneHeartbeat(body);
  }

  @Public()
  @Get('phone-status')
  getPhoneStatus() {
    return this.adminService.getPhoneStatus();
  }

  @Get('push')
  async getPushes() {
    return this.adminService.getPushes();
  }

  @Post('push')
  async sendPush(@Body() body: any) {
    return this.adminService.sendPush(body);
  }

  @Put('push/:id')
  async updatePush(@Param('id') id: string, @Body() body: any) {
    return this.adminService.updatePush(id, body);
  }

  @Delete('push/:id')
  async deletePush(@Param('id') id: string) {
    return this.adminService.deletePush(id);
  }

  @Get('coupons')
  async getCoupons() {
    return this.adminService.getCoupons();
  }

  @Post('coupons')
  async saveCoupon(@Body() body: any) {
    return this.adminService.saveCoupon(body);
  }

  @Put('coupons/:id/toggle')
  async toggleCoupon(@Param('id') id: string) {
    return this.adminService.toggleCoupon(id);
  }

  @Delete('coupons/:id')
  async deleteCoupon(@Param('id') id: string) {
    return this.adminService.deleteCoupon(id);
  }

  @Public()
  @Get('coupons/active')
  async getActiveCoupons(@Param('email') email?: string) {
    return this.adminService.getActiveDiscounts(email);
  }

  @Public()
  @Post('coupons/validate')
  async validateCoupon(@Body() body: { code: string; amount: number; email?: string }) {
    return this.adminService.validateCoupon(body.code, body.amount || 0, body.email);
  }

  @Public()
  @Post('device/bind')
  async bindDevice(@Body() body: any) {
    return this.adminService.bindDevice(body);
  }

  @Public()
  @Post('device/unbind')
  async unbindDevice(@Body('email') email: string) {
    return this.adminService.unbindDevice(email);
  }

  @Get('api-keys')
  async getApiKeys() {
    return this.adminService.getApiKeys();
  }

  @Post('api-keys')
  async saveApiKey(@Body() body: any) {
    return this.adminService.saveApiKey(body);
  }

  @Delete('api-keys/:id')
  async deleteApiKey(@Param('id') id: string) {
    return this.adminService.deleteApiKey(id);
  }

  @Get('server-keys')
  async getServerKeys() {
    return this.adminService.getServerKeys();
  }

  @Post('server-keys')
  async updateServerKeys(@Body() body: any) {
    return this.adminService.updateServerKeys(body);
  }

  @Public()
  @Post('marketing/send-trial-reminders')
  async sendTrialReminders() {
    return this.adminService.sendTrialExpiryReminders();
  }

  // ==========================================
  // QUẢN LÝ GIỚI THIỆU BẠN BÈ & RÚT TIỀN HOA HỒNG
  // ==========================================

  @Get('affiliate/overview')
  async getAffiliateOverview() {
    return this.adminService.getAffiliateOverview();
  }

  @Post('affiliate/withdrawals/:id/approve')
  async approveWithdrawal(@Param('id') id: string) {
    return this.adminService.approveWithdrawal(id);
  }

  @Post('affiliate/withdrawals/:id/reject')
  async rejectWithdrawal(@Param('id') id: string, @Body('reason') reason?: string) {
    return this.adminService.rejectWithdrawal(id, reason);
  }

  @Public()
  @Post('affiliate/withdraw')
  async recordWithdrawalRequest(@Body() body: any) {
    return this.adminService.recordWithdrawalRequest(body);
  }

  @Public()
  @Post('affiliate/bind')
  async recordReferralBind(@Body() body: any) {
    return this.adminService.recordReferralBind(body);
  }

  @Public()
  @Get('affiliate/stats')
  async getAffiliateStats(@Param('code') code?: string, @Param('email') email?: string) {
    return this.adminService.getAffiliateStats(code, email);
  }
}
