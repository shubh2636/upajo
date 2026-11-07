class ServerException implements Exception {
  final String message;
  final int? statusCode;

  const ServerException([this.message = 'Server Exception Occurred', this.statusCode]);

  @override
  String toString() => message;
}

class NetworkException implements Exception {
  final String message;

  const NetworkException([this.message = 'Network connection unavailable']);

  @override
  String toString() => message;
}

class AuthException implements Exception {
  final String message;

  const AuthException([this.message = 'Authentication error']);

  @override
  String toString() => message;
}

class CacheException implements Exception {
  final String message;

  const CacheException([this.message = 'Cache exception']);

  @override
  String toString() => message;
}
