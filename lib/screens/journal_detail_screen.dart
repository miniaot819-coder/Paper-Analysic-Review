import 'dart:async';

import 'package:flutter/material.dart';

import '../firebase/analytics_tracking_service.dart';
import '../models/journal_insight.dart';
import '../utils/app_routes.dart';
import '../viewmodels/journal_detail_view_model.dart';
import '../widgets/article_card.dart';

class JournalDetailScreen extends StatelessWidget {
  const JournalDetailScreen({required this.journal, super.key});

  final JournalInsight journal;

  @override
  Widget build(BuildContext context) {
    final viewModel = JournalDetailViewModel(journal);

    return Scaffold(
      appBar: AppBar(title: const Text('Journal Detail')),
      body: ListView(
        key: const Key('journal_detail_screen'),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(
            key: const Key('journal_detail_name'),
            viewModel.name,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 16),
          Wrap(
            key: const Key('journal_detail_metrics'),
            spacing: 10,
            runSpacing: 10,
            children: [
              _Metric(
                valueKey: const Key('journal_detail_publication_count'),
                label: 'Publications',
                value: viewModel.publicationCount.toString(),
              ),
              _Metric(
                valueKey: const Key('journal_detail_total_citations'),
                label: 'Total citations',
                value: viewModel.totalCitations.toString(),
              ),
              _Metric(
                valueKey: const Key('journal_detail_average_citations'),
                label: 'Average citations',
                value: viewModel.averageCitations.toStringAsFixed(1),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            key: const Key('journal_detail_related_publications'),
            'Related publications',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          ...viewModel.publications.asMap().entries.map(
            (entry) => Padding(
              key: ValueKey('journal_detail_publication_${entry.key}'),
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

class _Metric extends StatelessWidget {
  const _Metric({
    required this.valueKey,
    required this.label,
    required this.value,
  });

  final Key valueKey;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF64748B))),
          const SizedBox(height: 6),
          Text(
            key: valueKey,
            value,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}
