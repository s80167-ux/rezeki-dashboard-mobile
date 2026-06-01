class ServiceCacheEntry<T> {
  const ServiceCacheEntry({required this.value, required this.savedAt});

  final T value;
  final DateTime savedAt;

  bool isFresh(Duration ttl) {
    return DateTime.now().difference(savedAt) < ttl;
  }
}
