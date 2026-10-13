import { Controller, Post, Get, Body, Param, Query } from '@nestjs/common';
import { OrdersService } from './orders.service.js';
import { CreateOrderDto } from './dto/create-order.dto.js';

@Controller('orders')
export class OrdersController {
  constructor(private readonly ordersService: OrdersService) {}

  @Post()
  async create(@Body() createOrderDto: CreateOrderDto) {
    return this.ordersService.create(createOrderDto);
  }

  @Get()
  async findAll(@Query('limit') limit?: string) {
    const take = limit ? parseInt(limit, 10) : 50;
    return this.ordersService.findAll(take);
  }

  @Get(':code')
  async findOne(@Param('code') code: string) {
    return this.ordersService.findByCode(code);
  }

  @Get(':code/status')
  async getStatus(@Param('code') code: string) {
    return this.ordersService.getStatus(code);
  }
}
