class ServerException implements Exception {
  final String message;
  const ServerException([this.message = 'Server Exception occurred.']);
}

class CacheException implements Exception {
  final String message;
  const CacheException([this.message = 'Cache Exception occurred.']);
}

class NetworkException implements Exception {
  final String message;
  const NetworkException([this.message = 'Network Exception occurred.']);
}

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);
}
