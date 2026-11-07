abstract class Failure {
  final String message;
  final int? statusCode;

  const Failure(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class ServerFailure extends Failure {
  const ServerFailure([String message = 'सर्वर से संपर्क नहीं हो पाया (Server Error)', int? code])
      : super(message, code);
}

class NetworkFailure extends Failure {
  const NetworkFailure([String message = 'इंटरनेट कनेक्शन उपलब्ध नहीं है (Network Error)'])
      : super(message);
}

class AuthFailure extends Failure {
  const AuthFailure([String message = 'प्रमाणीकरण असफल रहा (Authentication Error)'])
      : super(message);
}

class CacheFailure extends Failure {
  const CacheFailure([String message = 'स्थानीय डेटा लोड करने में त्रुटि (Cache Error)'])
      : super(message);
}

class ValidationFailure extends Failure {
  const ValidationFailure(String message) : super(message);
}

