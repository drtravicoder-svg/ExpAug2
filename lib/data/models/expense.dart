import 'package:equatable/equatable.dart';

/// Expense status enumeration
enum ExpenseStatus {
  pending,
  approved,
  rejected
}

/// Enhanced Expense model for SQLite database
class Expense extends Equatable {
  final String id;
  final String tripId;
  final String payerId;
  final String title;
  final String? description;
  final double amount;
  final String currency;
  final String category;
  final DateTime date;
  final ExpenseStatus status;
  final String? receiptPath;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Expense({
    required this.id,
    required this.tripId,
    required this.payerId,
    required this.title,
    this.description,
    required this.amount,
    required this.currency,
    required this.category,
    required this.date,
    required this.status,
    this.receiptPath,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create Expense from SQLite database map
  factory Expense.fromSQLite(Map<String, dynamic> data) {
    return Expense(
      id: data['id'],
      tripId: data['trip_id'],
      payerId: data['payer_id'],
      title: data['title'],
      description: data['description'],
      amount: (data['amount'] as num).toDouble(),
      currency: data['currency'] ?? 'INR',
      category: data['category'] ?? 'general',
      date: DateTime.parse(data['date']),
      status: ExpenseStatus.values.firstWhere(
        (e) => e.toString().split('.').last == data['status'],
        orElse: () => ExpenseStatus.pending,
      ),
      receiptPath: data['receipt_path'],
      createdAt: DateTime.parse(data['created_at']),
      updatedAt: DateTime.parse(data['updated_at']),
    );
  }

  /// Create Expense from JSON
  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'],
      tripId: json['tripId'],
      payerId: json['payerId'],
      title: json['title'],
      description: json['description'],
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] ?? 'INR',
      category: json['category'] ?? 'general',
      date: DateTime.parse(json['date']),
      status: ExpenseStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => ExpenseStatus.pending,
      ),
      receiptPath: json['receiptPath'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  /// Convert to SQLite-compatible map
  Map<String, dynamic> toSQLiteMap() {
    return {
      'id': id,
      'trip_id': tripId,
      'payer_id': payerId,
      'title': title,
      'description': description,
      'amount': amount,
      'currency': currency,
      'category': category,
      'date': date.toIso8601String(),
      'status': status.toString().split('.').last,
      'receipt_path': receiptPath,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tripId': tripId,
      'payerId': payerId,
      'title': title,
      'description': description,
      'amount': amount,
      'currency': currency,
      'category': category,
      'date': date.toIso8601String(),
      'status': status.toString().split('.').last,
      'receiptPath': receiptPath,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

  /// Helper getters
  bool get isPending => status == ExpenseStatus.pending;
  bool get isApproved => status == ExpenseStatus.approved;
  bool get isRejected => status == ExpenseStatus.rejected;
  bool get hasReceipt => receiptPath != null && receiptPath!.isNotEmpty;

  /// Create a copy with updated fields
  Expense copyWith({
    String? id,
    String? tripId,
    String? payerId,
    String? title,
    String? description,
    double? amount,
    String? currency,
    String? category,
    DateTime? date,
    ExpenseStatus? status,
    String? receiptPath,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Expense(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      payerId: payerId ?? this.payerId,
      title: title ?? this.title,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      category: category ?? this.category,
      date: date ?? this.date,
      status: status ?? this.status,
      receiptPath: receiptPath ?? this.receiptPath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    tripId,
    payerId,
    title,
    description,
    amount,
    currency,
    category,
    date,
    status,
    receiptPath,
    createdAt,
    updatedAt,
  ];

  @override
  String toString() {
    return 'Expense(id: $id, title: $title, amount: $amount $currency, status: $status)';
  }
}

/// Expense split model for splitting expenses among members
class ExpenseSplit extends Equatable {
  final String id;
  final String expenseId;
  final String memberId;
  final double amount;
  final bool isSettled;
  final DateTime? settledAt;

  const ExpenseSplit({
    required this.id,
    required this.expenseId,
    required this.memberId,
    required this.amount,
    required this.isSettled,
    this.settledAt,
  });

  /// Create ExpenseSplit from SQLite database map
  factory ExpenseSplit.fromSQLite(Map<String, dynamic> data) {
    return ExpenseSplit(
      id: data['id'],
      expenseId: data['expense_id'],
      memberId: data['member_id'],
      amount: (data['amount'] as num).toDouble(),
      isSettled: data['is_settled'] == 1,
      settledAt: data['settled_at'] != null ? DateTime.parse(data['settled_at']) : null,
    );
  }

  /// Convert to SQLite-compatible map
  Map<String, dynamic> toSQLiteMap() {
    return {
      'id': id,
      'expense_id': expenseId,
      'member_id': memberId,
      'amount': amount,
      'is_settled': isSettled ? 1 : 0,
      'settled_at': settledAt?.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  ExpenseSplit copyWith({
    String? id,
    String? expenseId,
    String? memberId,
    double? amount,
    bool? isSettled,
    DateTime? settledAt,
  }) {
    return ExpenseSplit(
      id: id ?? this.id,
      expenseId: expenseId ?? this.expenseId,
      memberId: memberId ?? this.memberId,
      amount: amount ?? this.amount,
      isSettled: isSettled ?? this.isSettled,
      settledAt: settledAt ?? this.settledAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    expenseId,
    memberId,
    amount,
    isSettled,
    settledAt,
  ];

  @override
  String toString() {
    return 'ExpenseSplit(id: $id, memberId: $memberId, amount: $amount, settled: $isSettled)';
  }
}

/// Receipt model for expense receipts
class Receipt extends Equatable {
  final String id;
  final String expenseId;
  final String filePath;
  final String fileName;
  final int fileSize;
  final String mimeType;
  final DateTime uploadedAt;

  const Receipt({
    required this.id,
    required this.expenseId,
    required this.filePath,
    required this.fileName,
    required this.fileSize,
    required this.mimeType,
    required this.uploadedAt,
  });

  /// Create Receipt from SQLite database map
  factory Receipt.fromSQLite(Map<String, dynamic> data) {
    return Receipt(
      id: data['id'],
      expenseId: data['expense_id'],
      filePath: data['file_path'],
      fileName: data['file_name'],
      fileSize: data['file_size'],
      mimeType: data['mime_type'],
      uploadedAt: DateTime.parse(data['uploaded_at']),
    );
  }

  /// Convert to SQLite-compatible map
  Map<String, dynamic> toSQLiteMap() {
    return {
      'id': id,
      'expense_id': expenseId,
      'file_path': filePath,
      'file_name': fileName,
      'file_size': fileSize,
      'mime_type': mimeType,
      'uploaded_at': uploadedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
    id,
    expenseId,
    filePath,
    fileName,
    fileSize,
    mimeType,
    uploadedAt,
  ];

  @override
  String toString() {
    return 'Receipt(id: $id, fileName: $fileName, size: ${fileSize}B)';
  }
}
