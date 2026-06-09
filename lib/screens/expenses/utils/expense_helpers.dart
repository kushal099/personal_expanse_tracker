String? inferPaymentMethod(String? notes) {
  if (notes == null || notes.trim().isEmpty) {
    return null;
  }
  final text = notes.toLowerCase();
  if (text.contains('gpay')) {
    return 'GPay';
  }
  if (text.contains('phonepe')) {
    return 'PhonePe';
  }
  if (text.contains('paytm')) {
    return 'Paytm';
  }
  if (text.contains('bank') || text.contains('transfer')) {
    return 'Bank Transfer';
  }
  if (text.contains('card')) {
    return 'Card';
  }
  if (text.contains('cash')) {
    return 'Cash';
  }
  return null;
}

String formatPaymentMethod(String? notes) {
  return inferPaymentMethod(notes) ?? 'Not recorded';
}

String formatNotes(String? notes) {
  final value = notes?.trim();
  if (value == null || value.isEmpty) {
    return 'No notes';
  }
  return value;
}
