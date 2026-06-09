import 'package:flutter/foundation.dart';

enum ReceivableSettlementType { full, partial }

@immutable
class ReceivableSettlement {
  final String id;
  final double amount;
  final double remainingAfter;
  final String? note;
  final DateTime settledAt;

  const ReceivableSettlement({
    required this.id,
    required this.amount,
    required this.remainingAfter,
    this.note,
    required this.settledAt,
  });

  ReceivableSettlement copyWith({
    String? id,
    double? amount,
    double? remainingAfter,
    String? note,
    DateTime? settledAt,
  }) {
    return ReceivableSettlement(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      remainingAfter: remainingAfter ?? this.remainingAfter,
      note: note ?? this.note,
      settledAt: settledAt ?? this.settledAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'remainingAfter': remainingAfter,
      'note': note,
      'settledAt': settledAt.toIso8601String(),
    };
  }

  static ReceivableSettlement fromJson(Map<dynamic, dynamic> json) {
    return ReceivableSettlement(
      id: json['id'] as String,
      amount: (json['amount'] as num).toDouble(),
      remainingAfter: (json['remainingAfter'] as num).toDouble(),
      note: json['note'] as String?,
      settledAt: DateTime.parse(json['settledAt'] as String),
    );
  }
}

/// Receivable model for tracking money owed to user
@immutable
class Receivable {
  final String id;
  final String userId;
  final String fromPerson;
  final double amount;
  final double remainingAmount;
  final String? description;
  final DateTime dueDate;
  final bool isPaid;
  final List<ReceivableSettlement> settlements;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Receivable({
    required this.id,
    required this.userId,
    required this.fromPerson,
    required this.amount,
    double? remainingAmount,
    this.description,
    required this.dueDate,
    required this.isPaid,
    List<ReceivableSettlement>? settlements,
    required this.createdAt,
    this.updatedAt,
  })  : remainingAmount = remainingAmount ?? amount,
        settlements = settlements ?? const [];

  Receivable copyWith({
    String? id,
    String? userId,
    String? fromPerson,
    double? amount,
    double? remainingAmount,
    String? description,
    DateTime? dueDate,
    bool? isPaid,
    List<ReceivableSettlement>? settlements,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Receivable(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fromPerson: fromPerson ?? this.fromPerson,
      amount: amount ?? this.amount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      isPaid: isPaid ?? this.isPaid,
      settlements: settlements ?? this.settlements,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
