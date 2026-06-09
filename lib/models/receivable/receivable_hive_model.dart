import 'package:hive/hive.dart';

part 'receivable_hive_model.g.dart';

@HiveType(typeId: 1)
class ReceivableHive {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final String fromPerson;

  @HiveField(3)
  final double amount;

  @HiveField(4)
  final String? description;

  @HiveField(5)
  final DateTime dueDate;

  @HiveField(6)
  final bool isPaid;

  @HiveField(7)
  final DateTime createdAt;

  @HiveField(8)
  final DateTime? updatedAt;

  ReceivableHive({
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

  ReceivableHive copyWith({
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
    return ReceivableHive(
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
