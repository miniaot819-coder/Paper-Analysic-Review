enum ResearchNotificationSource { foreground, background, opened }

class ResearchNotification {
  const ResearchNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.receivedAt,
    required this.source,
    required this.isRead,
    this.type,
    this.topic,
  });

  final String id;
  final String title;
  final String body;
  final DateTime receivedAt;
  final ResearchNotificationSource source;
  final bool isRead;
  final String? type;
  final String? topic;

  ResearchNotification copyWith({
    ResearchNotificationSource? source,
    bool? isRead,
  }) {
    return ResearchNotification(
      id: id,
      title: title,
      body: body,
      receivedAt: receivedAt,
      source: source ?? this.source,
      isRead: isRead ?? this.isRead,
      type: type,
      topic: topic,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'receivedAt': receivedAt.toIso8601String(),
      'source': source.name,
      'isRead': isRead,
      'type': type,
      'topic': topic,
    };
  }

  factory ResearchNotification.fromJson(Map<String, Object?> json) {
    final sourceName = json['source'] as String?;
    final source = ResearchNotificationSource.values.firstWhere(
      (value) => value.name == sourceName,
      orElse: () => ResearchNotificationSource.background,
    );

    return ResearchNotification(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      receivedAt: DateTime.parse(json['receivedAt'] as String),
      source: source,
      isRead: json['isRead'] as bool? ?? false,
      type: json['type'] as String?,
      topic: json['topic'] as String?,
    );
  }
}
