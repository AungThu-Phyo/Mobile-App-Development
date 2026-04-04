class RepositoryException implements Exception {
  final String code;
  final String message;
  final Object? cause;

  const RepositoryException({
    required this.code,
    required this.message,
    this.cause,
  });

  @override
  String toString() => 'RepositoryException($code): $message';
}
