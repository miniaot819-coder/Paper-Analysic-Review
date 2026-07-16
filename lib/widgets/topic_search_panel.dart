import 'package:flutter/material.dart';

class TopicSearchPanel extends StatelessWidget {
  const TopicSearchPanel({
    required this.title,
    required this.subtitle,
    required this.controller,
    required this.isLoading,
    required this.onSearch,
    this.fieldKey = const Key('topic_search_field'),
    this.buttonKey = const Key('topic_search_button'),
    super.key,
  });

  final String title;
  final String subtitle;
  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onSearch;
  final Key fieldKey;
  final Key buttonKey;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: const Color(0xFFEEF4FF),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(subtitle, style: const TextStyle(color: Color(0xFF64748B))),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    key: fieldKey,
                    controller: controller,
                    textInputAction: TextInputAction.search,
                    onSubmitted: isLoading ? null : (_) => onSearch(),
                    decoration: InputDecoration(
                      hintText: 'Enter a research topic',
                      prefixIcon: const Icon(Icons.search_rounded),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 56,
                  child: FilledButton(
                    key: buttonKey,
                    onPressed: isLoading ? null : onSearch,
                    child: isLoading
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Search'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
