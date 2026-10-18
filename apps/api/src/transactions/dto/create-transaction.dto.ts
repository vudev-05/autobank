export class CreateTransactionDto {
  bankCode!: string;
  accountNumber!: string;
  amount!: number;
  type!: 'credit' | 'debit';
  content!: string;
  orderCode?: string;
  transactionTime!: string;
  rawContent!: string;
  fingerprint!: string;
  merchantSlug?: string;
  userEmail?: string;
  category?: string;
  note?: string;
}
