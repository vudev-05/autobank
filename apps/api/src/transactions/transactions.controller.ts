import { Controller, Post, Get, Delete, Body, Param, Query } from '@nestjs/common';
import { TransactionsService } from './transactions.service.js';
import { CreateTransactionDto } from './dto/create-transaction.dto.js';

@Controller(['transactions', 'api/transactions'])
export class TransactionsController {
  constructor(private readonly transactionsService: TransactionsService) {}

  @Post()
  async create(@Body() createTransactionDto: CreateTransactionDto) {
    return this.transactionsService.ingestTransaction(createTransactionDto);
  }

  @Get()
  async findAll(
    @Query('limit') limit?: string,
    @Query('userEmail') userEmail?: string,
  ) {
    const take = limit ? parseInt(limit, 10) : 100;
    return this.transactionsService.findAll(take, userEmail);
  }

  @Get(':id')
  async findOne(@Param('id') id: string) {
    return this.transactionsService.findOne(id);
  }

  @Delete(':id')
  async remove(
    @Param('id') id: string,
    @Query('userEmail') userEmail?: string,
  ) {
    return this.transactionsService.delete(id, userEmail);
  }

  @Delete()
  async clearAll(@Query('userEmail') userEmail: string) {
    return this.transactionsService.clearUserTransactions(userEmail);
  }
}

