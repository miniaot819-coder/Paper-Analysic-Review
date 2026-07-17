class JournalTopicMatrix {
  const JournalTopicMatrix({
    required this.journals,
    required this.topics,
    required this.values,
  });

  final List<String> journals;
  final List<String> topics;
  final List<List<int>> values;

  bool get isEmpty => journals.isEmpty || topics.isEmpty;
}
