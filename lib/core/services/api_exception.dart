enum ApiErrorType {
  timeout,
  noConnection,
  serverError,
  notFound,
  unauthorized,
  forbidden,
  conflict,
  validation,
  unknown,
}

class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.statusCode,
    required this.type,
  });

  final String message;
  final int? statusCode;
  final ApiErrorType type;

  @override
  String toString() => message;
}
