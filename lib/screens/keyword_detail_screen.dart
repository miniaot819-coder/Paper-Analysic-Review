import 'dart:async';

import 'package:flutter/material.dart';

import '../firebase/analytics_tracking_service.dart';
import '../models/keyword_insight.dart';
import '../utils/app_routes.dart';
import '../viewmodels/keyword_detail_view_model.dart';
import '../widgets/analysis_charts.dart';
import '../widgets/article_card.dart';

class KeywordDetailScreen extends StatelessWidget {
  const KeywordDetailScreen({required this.keyword, super.key});

  final KeywordInsight keyword;

  @override
  Widget build(BuildContext context) {
    final viewModel = KeywordDetailViewModel(keyword);

    return Scaffold(
      appBar: AppBar(title: const Text('Keyword Detail')),
      body: ListView(
        key: const Key('keyword_detail_screen'),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(
            key: const Key('keyword_detail_name'),
            viewModel.name,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            key: const Key('keyword_detail_summary'),
            '${viewModel.frequency} related works • '
            '${viewModel.totalCitations} citations',
            style: const TextStyle(color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 20),
          _DetailSection(
            key: const Key('keyword_detail_trend'),
            title: 'Publication trend over time',
            child: PublicationLineChart(data: viewModel.trend),
          ),
          const SizedBox(height: 16),
          _DetailSection(
            key: const Key('keyword_detail_related_journals'),
            title: 'Related journals',
            child: Column(
              children: viewModel.journals
                  .toList()
                  .asMap()
                  .entries
                  .map(
                    (entry) => ListTile(
                      key: ValueKey('keyword_detail_journal_${entry.key}'),
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.menu_book_rounded),
                      title: Text(entry.value.name),
                      trailing: Text('${entry.value.count} works'),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),
          _DetailSection(
            key: const Key('keyword_detail_top_authors'),
            title: 'Top contributing authors',
            child: Column(
              children: List.generate(viewModel.authors.length, (index) {
                final author = viewModel.authors[index];
                return ListTile(
                  key: ValueKey('keyword_detail_author_$index'),
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(child: Text('${index + 1}')),
                  title: Text(author.name),
                  trailing: Text('${author.count} works'),
                );
              }),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            key: const Key('keyword_detail_related_publications'),
            'Related publications',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          ...viewModel.publications
              .take(20)
              .toList()
              .asMap()
              .entries
              .map(
                (entry) => Padding(
                  key: ValueKey('keyword_detail_publication_${entry.key}'),
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ArticleCard(
                    publication: entry.value,
                    onTap: () {
                      final publication = entry.value;
                      unawaited(
                        AnalyticsTrackingService.instance.logViewPublication(
                          title: publication.title,
                          year: publication.publicationYear,
                        ),
                      );
                      Navigator.of(
                        context,
                      ).push(AppRoutes.publicationDetail(publication));
                    },
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.child, super.key});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}
