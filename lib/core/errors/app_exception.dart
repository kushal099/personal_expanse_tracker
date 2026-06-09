/// Base exception class for the app
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final Exception? originalException;

  AppException({required this.message, this.code, this.originalException});

  @override
  String toString() => message;
}

/// Firebase related exceptions
class FirebaseException extends AppException {
  FirebaseException({
    required super.message,
    super.code,
    super.originalException,
  });
}

/// Authentication exceptions
class AuthException extends AppException {
  AuthException({required super.message, super.code, super.originalException});
}

/// Data/Repository exceptions
class DataException extends AppException {
  DataException({required super.message, super.code, super.originalException});
}

/// Network exceptions
class NetworkException extends AppException {
  NetworkException({
    required super.message,
    super.code,
    super.originalException,
  });
}
