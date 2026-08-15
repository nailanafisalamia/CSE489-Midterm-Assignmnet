class AppException implements Exception {
  final String message;
  const AppException(this.message);
  @override
  String toString() => message;
}

class NetworkException extends AppException {
  const NetworkException(super.message);
}

class ApiException extends AppException {
  final int? statusCode;
  const ApiException(super.message, {this.statusCode});
}
