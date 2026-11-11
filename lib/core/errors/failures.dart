abstract class Failure {
  final String message;
  final int? statusCode;

  const Failure(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class ServerFailure extends Failure {
  const ServerFailure([String message = 'Unable to connect to server. Please try again.', int? code])
      : super(message, code);
}

class NetworkFailure extends Failure {
  const NetworkFailure([String message = 'No internet connection. Please check your network.'])
      : super(message);
}

class AuthFailure extends Failure {
  const AuthFailure([String message = 'Authentication failed. Please log in again.'])
      : super(message);
}

class CacheFailure extends Failure {
  const CacheFailure([String message = 'Unable to load local cached data.'])
      : super(message);
}

class ValidationFailure extends Failure {
  const ValidationFailure(String message) : super(message);
}

