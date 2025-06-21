class AuthenticationException implements Exception {
  final String message;
  AuthenticationException(this.message);
}

class DataValidationException implements Exception {
  final String message;
  DataValidationException(this.message);
}
