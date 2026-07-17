class RankedItem {
  const RankedItem({
    required this.name,
    required this.count,
    this.subtitle,
    this.id,
  });

  final String name;
  final int count;
  final String? subtitle;
  final String? id;
}
