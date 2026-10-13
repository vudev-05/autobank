import { Controller, Post, Get, Body, Param, Query } from '@nestjs/common';
import { TransactionsService } from './transactions.service.js';
import { CreateTransactionDto } from './dto/create-transaction.dto.js';

@Controller('transactions')
export class TransactionsController {
  constructor(private readonly transactionsService: TransactionsService) {}

  @Post()
  async create(@Body() createTransactionDto: CreateTransactionDto) {
    return this.transactionsService.ingestTransaction(createTransactionDto);
  }

  @Get()
  async findAll(@Query('limit') limit?: string) {
    const take = limit ? parseInt(limit, 10) : 50;
    return this.transactionsService.findAll(take);
  }

  @Get(':id')
  async findOne(@Param('id') id: string) {
    return this.transactionsService.findOne(id);
  }
}
