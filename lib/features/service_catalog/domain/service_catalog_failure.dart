enum ServiceCatalogFailureType {
  unauthorized,
  connection,
  invalidResponse,
  server,
}

class ServiceCatalogFailure implements Exception {
  const ServiceCatalogFailure(this.type, this.message);

  final ServiceCatalogFailureType type;
  final String message;
}
