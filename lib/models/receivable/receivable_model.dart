import 'package:flutter/foundation.dart';

/// Receivable model for tracking money owed to user
@immutable
class Receivable {
  final String id;
  final String userId;
  final String fromPerson;
  final double amount;
  final String? description;
  final DateTime dueDate;
  final bool isPaid;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Receivable({
    required this.id,
    required this.userId,
    required this.fromPerson,
    required this.amount,
    this.description,
    required this.dueDate,
    required this.isPaid,
    required this.createdAt,
    this.updatedAt,
  });

  Receivable copyWith({
    String? id,
    String? userId,
    String? fromPerson,
    double? amount,
    String? description,
    DateTime? dueDate,
    bool? isPaid,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Receivable(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fromPerson: fromPerson ?? this.fromPerson,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      isPaid: isPaid ?? this.isPaid,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
