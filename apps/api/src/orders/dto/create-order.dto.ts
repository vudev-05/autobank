export class CreateOrderDto {
  orderCode!: string;
  totalAmount!: number;
  description?: string;
  customerName?: string;
  customerPhone?: string;
  merchantSlug?: string;
  bankCode?: string;
  accountNumber?: string;
}
