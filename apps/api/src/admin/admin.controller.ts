import { Controller, Get, Post, Body, Param, Delete, Put } from '@nestjs/common';
import { AdminService } from './admin.service.js';

@Controller('admin')
export class AdminController {
  constructor(private readonly adminService: AdminService) {}

  @Get('configs')
  async getConfig() {
    return this.adminService.getConfig();
  }

  @Post('configs')
  async updateConfig(@Body() body: any) {
    return this.adminService.updateConfig(body);
  }

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

  @Post('users')
  async upsertUser(@Body() body: any) {
    return this.adminService.upsertUser(body);
  }

  @Get('users')
  async getUsers() {
    return this.adminService.getUsers();
  }

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

  @Get('live-pin')
  getLivePin() {
    return this.adminService.getLivePin();
  }

  @Post('live-pin')
  setLivePin(@Body('pin') pin: string) {
    return this.adminService.setLivePin(pin);
  }

  @Post('verify-live-pin')
  verifyLivePin(@Body('pin') pin: string) {
    return this.adminService.verifyLivePin(pin);
  }

  @Post('phone-heartbeat')
  recordPhoneHeartbeat(@Body() body: any) {
    return this.adminService.recordPhoneHeartbeat(body);
  }

  @Get('phone-status')
  getPhoneStatus() {
    return this.adminService.getPhoneStatus();
  }

  @Post('push')
  async sendPush(@Body() body: any) {
    return this.adminService.sendPush(body);
  }

  @Get('coupons')
  async getCoupons() {
    return this.adminService.getCoupons();
  }

  @Post('coupons/validate')
  async validateCoupon(@Body() body: { code: string; amount: number }) {
    return this.adminService.validateCoupon(body.code, body.amount || 0);
  }

  @Post('device/bind')
  async bindDevice(@Body() body: any) {
    return this.adminService.bindDevice(body);
  }

  @Post('device/unbind')
  async unbindDevice(@Body('email') email: string) {
    return this.adminService.unbindDevice(email);
  }
}
