class OpenAlexPage<T> {
  const OpenAlexPage({
    required this.items,
    required this.totalCount,
    this.nextCursor,
    this.costUsd,
  });

  final List<T> items;
  final int totalCount;
  final String? nextCursor;
  final double? costUsd;
}
