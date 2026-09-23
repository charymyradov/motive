/// Exceptions thrown by the data layer. Repositories translate them into
/// [Failure]s so the domain and presentation layers never see them.
class CacheException implements Exception {
  const CacheException([this.message = 'Local storage error']);
  final String message;
  @override
  String toString() => 'CacheException: $message';
}

class NetworkException implements Exception {
  const NetworkException([this.message = 'No internet connection']);
  final String message;
  @override
  String toString() => 'NetworkException: $message';
}

class ServerException implements Exception {
  const ServerException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
  @override
  String toString() => 'ServerException($statusCode): $message';
}
