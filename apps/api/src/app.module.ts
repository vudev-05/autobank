import { Module } from '@nestjs/common';
import { AppController } from './app.controller.js';
import { AppService } from './app.service.js';
import { AuthModule } from './auth/auth.module.js';
import { MerchantsModule } from './merchants/merchants.module.js';
import { BankConnectionsModule } from './bank-connections/bank-connections.module.js';
import { TransactionsModule } from './transactions/transactions.module.js';
import { OrdersModule } from './orders/orders.module.js';
import { PrismaModule } from './prisma/prisma.module.js';
import { AdminModule } from './admin/admin.module.js';
import { TtsModule } from './tts/tts.module.js';
import { ThueApiModule } from './thueapi/thueapi.module.js';
import { MailModule } from './mail/mail.module.js';

@Module({
  imports: [
    PrismaModule,
    MailModule,
    AuthModule,
    MerchantsModule,
    BankConnectionsModule,
    TransactionsModule,
    OrdersModule,
    AdminModule,
    TtsModule,
    ThueApiModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
