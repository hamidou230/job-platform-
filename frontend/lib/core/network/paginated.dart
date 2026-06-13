/// Réponse paginée générique renvoyée par l'API ({ data, meta }).
class Paginated<T> {
  final List<T> data;
  final int total;
  final int page;
  final int limit;
  final int totalPages;
  final bool hasNextPage;

  const Paginated({
    required this.data,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
    required this.hasNextPage,
  });

  factory Paginated.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromItem,
  ) {
    final meta = json['meta'] as Map<String, dynamic>? ?? {};
    return Paginated<T>(
      data: (json['data'] as List<dynamic>? ?? [])
          .map((e) => fromItem(e as Map<String, dynamic>))
          .toList(),
      total: meta['total'] ?? 0,
      page: meta['page'] ?? 1,
      limit: meta['limit'] ?? 10,
      totalPages: meta['totalPages'] ?? 1,
      hasNextPage: meta['hasNextPage'] ?? false,
    );
  }
}
