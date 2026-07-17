import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../firebase/analytics_tracking_service.dart';
import '../models/journal_insight.dart';
import '../models/openalex_search_state.dart';
import '../utils/analysis_routes.dart';
import '../viewmodels/journals_view_model.dart';
import '../widgets/openalex_pagination_controls.dart';
import '../widgets/topic_search_panel.dart';

class JournalsScreen extends StatefulWidget {
  const JournalsScreen({super.key});

  @override
  State<JournalsScreen> createState() => _JournalsScreenState();
}

class _JournalsScreenState extends State<JournalsScreen> {
  final TextEditingController _controller = TextEditingController(
    text: 'Artificial Intelligence',
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<JournalsViewModel>().loadInitial();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search() {
    return context.read<JournalsViewModel>().search(_controller.text);
  }

  void _openJournal(JournalInsight journal) {
    unawaited(AnalyticsTrackingService.instance.logViewJournal(journal.name));
    Navigator.of(context).push(AnalysisRoutes.journalDetail(journal));
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<JournalsViewModel>();
    final state = viewModel.state;
    final journals = viewModel.journals;
    final hasLoadedPublications =
        state.status == OpenAlexSearchStatus.success &&
        state.publications.isNotEmpty;

    final header = <Widget>[
      TopicSearchPanel(
        title: 'Journal Analysis',
        subtitle: 'Journal rankings based on loaded OpenAlex works',
        controller: _controller,
        isLoading: state.isLoading,
        onSearch: _search,
        fieldKey: const Key('journals_topic_search_field'),
        buttonKey: const Key('journals_topic_search_button'),
      ),
      const SizedBox(height: 18),
    ];

    if (hasLoadedPublications) {
      header.addAll([
        OpenAlexPaginationControls(
          loadedCount: state.loadedCount,
          totalCount: state.displayTotalCount,
          hasMore: state.hasMore,
          isLoadingMore: state.isLoadingMore,
          reachedResultLimit: state.reachedResultLimit,
          maximumLoadedWorks: viewModel.maximumLoadedWorks,
          pageSize: viewModel.pageSize,
          isAutoLoading: state.isAutoLoading,
          isAutoLoadCancellationPending: state.isAutoLoadCancellationPending,
          autoLoadFailed: state.autoLoadFailed,
          loadMoreErrorMessage: state.loadMoreErrorMessage,
          onLoadMore: () => unawaited(viewModel.loadMore()),
          onLoadUpToLimit: () => unawaited(viewModel.loadUpToLimit()),
          onCancelAutoLoad: viewModel.cancelLoadUpToLimit,
          onRetry: () => unawaited(viewModel.retryLoadMore()),
        ),
        const SizedBox(height: 18),
      ]);
    }

    if (state.status == OpenAlexSearchStatus.idle || state.isLoading) {
      header.add(const _LoadingState());
    } else if (state.hasError) {
      header.add(
        _MessageCard(
          icon: Icons.cloud_off_rounded,
          message: state.errorMessage ?? 'Could not load journal data.',
        ),
      );
    } else if (journals.isEmpty) {
      header.add(
        const _MessageCard(
          icon: Icons.menu_book_outlined,
          message: 'No journals were found in the loaded works.',
        ),
      );
    } else {
      header.addAll([
        _JournalSummary(
          publicationCount: state.publications.length,
          journalCount: journals.length,
          citationCount: viewModel.totalCitations,
        ),
        const SizedBox(height: 18),
        _Section(
          title: 'Journal contribution',
          child: _JournalContributionChart(journals: journals.take(8).toList()),
        ),
        const SizedBox(height: 18),
        Text(
          'Top journals',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
      ]);
    }

    final journalItemCount = journals.isEmpty ? 0 : journals.length;
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _search,
        child: ListView.builder(
          key: const Key('journals_screen'),
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          itemCount: header.length + journalItemCount,
          itemBuilder: (context, index) {
            if (index < header.length) return header[index];

            final contentIndex = index - header.length;
            if (contentIndex < journalItemCount) {
              final journal = journals[contentIndex];
              return Padding(
                key: ValueKey('journal_${journal.id ?? journal.name}'),
                padding: const EdgeInsets.only(bottom: 10),
                child: _JournalTile(
                  key: ValueKey('journal_item_$contentIndex'),
                  journal: journal,
                  onTap: () => _openJournal(journal),
                ),
              );
            }

            throw StateError('Unexpected journal list index: $index');
          },
        ),
      ),
    );
  }
}

class _JournalSummary extends StatelessWidget {
  const _JournalSummary({
    required this.publicationCount,
    required this.journalCount,
    required this.citationCount,
  });

  final int publicationCount;
  final int journalCount;
  final int citationCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _SummaryMetric(
          valueKey: const Key('journals_summary_works'),
          label: 'Works',
          value: '$publicationCount',
        ),
        const SizedBox(width: 10),
        _SummaryMetric(
          valueKey: const Key('journals_summary_journals'),
          label: 'Journals',
          value: '$journalCount',
        ),
        const SizedBox(width: 10),
        _SummaryMetric(
          valueKey: const Key('journals_summary_citations'),
          label: 'Citations',
          value: '$citationCount',
        ),
      ],
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.valueKey,
    required this.label,
    required this.value,
  });

  final Key valueKey;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
          child: Column(
            children: [
              Text(
                key: valueKey,
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(color: Color(0xFF64748B))),
            ],
          ),
        ),
      ),
    );
  }
}

class _JournalContributionChart extends StatelessWidget {
  const _JournalContributionChart({required this.journals});

  final List<JournalInsight> journals;

  @override
  Widget build(BuildContext context) {
    final maxCount = journals.isEmpty ? 1 : journals.first.publicationCount;
    return Column(
      children: journals.map((journal) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      journal.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text('${journal.publicationCount} works'),
                ],
              ),
              const SizedBox(height: 6),
              LinearProgressIndicator(
                value: journal.publicationCount / maxCount,
                minHeight: 8,
                borderRadius: BorderRadius.circular(99),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _JournalTile extends StatelessWidget {
  const _JournalTile({required this.journal, required this.onTap, super.key});

  final JournalInsight journal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: ListTile(
        onTap: onTap,
        leading: const CircleAvatar(child: Icon(Icons.menu_book_rounded)),
        title: Text(
          journal.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          '${journal.publicationCount} works • ${journal.totalCitations} citations • avg ${journal.averageCitations.toStringAsFixed(1)}',
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

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
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 72),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            Icon(icon, size: 38, color: const Color(0xFF64748B)),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
