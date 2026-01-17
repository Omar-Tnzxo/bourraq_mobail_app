/// نموذج المحفظة
class Wallet {
  final String id;
  final String userId;
  final double balance;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Wallet({
    required this.id,
    required this.userId,
    required this.balance,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Wallet.empty(String userId) {
    return Wallet(
      id: '',
      userId: userId,
      balance: 0.0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {'user_id': userId, 'balance': balance};

  /// Format balance with commas (e.g., 10,000.00)
  String get formattedBalance {
    return balance
        .toStringAsFixed(2)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }
}

/// أنواع المعاملات
enum TransactionType {
  deposit, // إيداع رصيد
  withdrawal, // سحب رصيد
  refund, // استرداد
  payment, // دفع طلب
}

extension TransactionTypeExtension on TransactionType {
  String get value {
    switch (this) {
      case TransactionType.deposit:
        return 'deposit';
      case TransactionType.withdrawal:
        return 'withdrawal';
      case TransactionType.refund:
        return 'refund';
      case TransactionType.payment:
        return 'payment';
    }
  }

  String get labelAr {
    switch (this) {
      case TransactionType.deposit:
        return 'إيداع';
      case TransactionType.withdrawal:
        return 'سحب';
      case TransactionType.refund:
        return 'استرداد';
      case TransactionType.payment:
        return 'دفع';
    }
  }

  String get labelEn {
    switch (this) {
      case TransactionType.deposit:
        return 'Deposit';
      case TransactionType.withdrawal:
        return 'Withdrawal';
      case TransactionType.refund:
        return 'Refund';
      case TransactionType.payment:
        return 'Payment';
    }
  }

  String get translationKey {
    switch (this) {
      case TransactionType.deposit:
        return 'wallet.transaction.deposit';
      case TransactionType.withdrawal:
        return 'wallet.transaction.withdrawal';
      case TransactionType.refund:
        return 'wallet.transaction.refund';
      case TransactionType.payment:
        return 'wallet.transaction.payment';
    }
  }

  static TransactionType fromString(String value) {
    switch (value) {
      case 'deposit':
        return TransactionType.deposit;
      case 'withdrawal':
        return TransactionType.withdrawal;
      case 'refund':
        return TransactionType.refund;
      case 'payment':
        return TransactionType.payment;
      default:
        return TransactionType.deposit;
    }
  }
}

/// نموذج المعاملة
class WalletTransaction {
  final String id;
  final String walletId;
  final TransactionType type;
  final double amount;
  final double balanceAfter;
  final String? orderId;
  final String? description;
  final DateTime createdAt;

  const WalletTransaction({
    required this.id,
    required this.walletId,
    required this.type,
    required this.amount,
    required this.balanceAfter,
    this.orderId,
    this.description,
    required this.createdAt,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: json['id'] as String,
      walletId: json['wallet_id'] as String,
      type: TransactionTypeExtension.fromString(
        json['type'] as String? ?? 'deposit',
      ),
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      balanceAfter: (json['balance_after'] as num?)?.toDouble() ?? 0.0,
      orderId: json['order_id'] as String?,
      description: json['description'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'wallet_id': walletId,
    'type': type.value,
    'amount': amount,
    'balance_after': balanceAfter,
    'order_id': orderId,
    'description': description,
  };

  /// Is this a credit (money in) or debit (money out)?
  bool get isCredit =>
      type == TransactionType.deposit || type == TransactionType.refund;

  /// Format amount with + or -
  String get formattedAmount {
    final prefix = isCredit ? '+' : '-';
    return '$prefix ${amount.toStringAsFixed(2)}';
  }
}
