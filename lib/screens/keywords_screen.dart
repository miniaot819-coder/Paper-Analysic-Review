import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../firebase/analytics_tracking_service.dart';
import '../firebase/remote_config_service.dart';
import '../models/keyword_insight.dart';
import '../models/openalex_search_state.dart';
import '../utils/analysis_routes.dart';
import '../viewmodels/keywords_view_model.dart';
import '../widgets/analysis_charts.dart';
import '../widgets/openalex_pagination_controls.dart';
import '../widgets/topic_search_panel.dart';

class KeywordsScreen extends StatefulWidget {
  const KeywordsScreen({super.key});

  @override
  State<KeywordsScreen> createState() => _KeywordsScreenState();
}

class _KeywordsScreenState extends State<KeywordsScreen> {
  final TextEditingController _controller = TextEditingController(
    text: 'Artificial Intelligence',
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<KeywordsViewModel>().loadInitial();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search() {
    return context.read<KeywordsViewModel>().search(_controller.text);
  }

  void _openKeyword(KeywordInsight keyword) {
    unawaited(AnalyticsTrackingService.instance.logViewKeyword(keyword.name));
    Navigator.of(context).push(AnalysisRoutes.keywordDetail(keyword));
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<KeywordsViewModel>();
    final state = viewModel.state;
    final limit = RemoteConfigService.instance.maxKeywords.clamp(1, 100);
    final allKeywords = viewModel.keywords;
    final keywords = allKeywords.take(limit).toList();
    final trending = viewModel.trendingKeywords.take(5).toList();
    final hasLoadedPublications =
        state.status == OpenAlexSearchStatus.success &&
        state.publications.isNotEmpty;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _search,
        child: ListView(
          key: const Key('keywords_screen'),
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            TopicSearchPanel(
              title: 'Keyword Analysis',
              subtitle:
                  'Keyword frequency and trends based on loaded OpenAlex works',
              controller: _controller,
              isLoading: state.isLoading,
              onSearch: _search,
              fieldKey: const Key('keywords_topic_search_field'),
              buttonKey: const Key('keywords_topic_search_button'),
            ),
            const SizedBox(height: 18),
            if (hasLoadedPublications) ...[
              OpenAlexPaginationControls(
                loadedCount: state.loadedCount,
                totalCount: state.displayTotalCount,
                hasMore: state.hasMore,
                isLoadingMore: state.isLoadingMore,
                reachedResultLimit: state.reachedResultLimit,
                maximumLoadedWorks: viewModel.maximumLoadedWorks,
                pageSize: viewModel.pageSize,
                isAutoLoading: state.isAutoLoading,
                isAutoLoadCancellationPending:
                    state.isAutoLoadCancellationPending,
                autoLoadFailed: state.autoLoadFailed,
                loadMoreErrorMessage: state.loadMoreErrorMessage,
                onLoadMore: () => unawaited(viewModel.loadMore()),
                onLoadUpToLimit: () => unawaited(viewModel.loadUpToLimit()),
                onCancelAutoLoad: viewModel.cancelLoadUpToLimit,
                onRetry: () => unawaited(viewModel.retryLoadMore()),
              ),
              const SizedBox(height: 18),
            ],
            if (state.status == OpenAlexSearchStatus.idle || state.isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 72),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (state.hasError)
              _KeywordMessage(
                message: state.errorMessage ?? 'Could not load keyword data.',
              )
            else if (keywords.isEmpty)
              const _KeywordMessage(
                message: 'No keywords were found for this topic.',
              )
            else ...[
              _KeywordSummary(
                works: state.publications.length,
                uniqueKeywords: allKeywords.length,
                topKeyword: keywords.first.name,
              ),
              const SizedBox(height: 18),
              _KeywordSection(
                title: 'Keyword frequency',
                child: _FrequencyChart(keywords: keywords),
              ),
              const SizedBox(height: 18),
              _KeywordSection(
                title: 'Trending keywords',
                child: Column(
                  children: trending
                      .map(
                        (keyword) => ListTile(
                          onTap: () => _openKeyword(keyword),
                          contentPadding: EdgeInsets.zero,
                          leading: const CircleAvatar(
                            child: Icon(Icons.trending_up_rounded),
                          ),
                          title: Text(
                            keyword.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            '${keyword.frequency} works • growth ${keyword.growth >= 0 ? '+' : ''}${keyword.growth}',
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded),
                        ),
                      )
                      .toList(),
                ),
              ),
              if (trending.isNotEmpty) ...[
                const SizedBox(height: 18),
                _KeywordSection(
                  title: 'Trend: ${trending.first.name}',
                  child: PublicationLineChart(data: trending.first.trend),
                ),
              ],
              const SizedBox(height: 18),
              Text(
                'Most frequent keywords',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              ...keywords.asMap().entries.map((entry) {
                final keyword = entry.value;
                return Padding(
                  key: ValueKey('keyword_item_${entry.key}'),
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Card(
                    elevation: 0,
                    child: ListTile(
                      onTap: () => _openKeyword(keyword),
                      leading: const CircleAvatar(
                        child: Icon(Icons.key_rounded),
                      ),
                      title: Text(
                        keyword.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text(
                        '${keyword.frequency} works • ${keyword.totalCitations} citations',
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                    ),
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}

class _KeywordSummary extends StatelessWidget {
  const _KeywordSummary({
    required this.works,
    required this.uniqueKeywords,
    required this.topKeyword,
  });

  final int works;
  final int uniqueKeywords;
  final String topKeyword;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 24,
          runSpacing: 16,
          children: [
            _SummaryValue(
              valueKey: const Key('keywords_summary_works'),
              label: 'Works',
              value: '$works',
            ),
            _SummaryValue(
              valueKey: const Key('keywords_summary_unique'),
              label: 'Unique keywords',
              value: '$uniqueKeywords',
            ),
            _SummaryValue(
              valueKey: const Key('keywords_summary_top'),
              label: 'Top keyword',
              value: topKeyword,
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryValue extends StatelessWidget {
  const _SummaryValue({
    required this.valueKey,
    required this.label,
    required this.value,
  });

  final Key valueKey;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF64748B))),
          const SizedBox(height: 4),
          Text(
            key: valueKey,
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _FrequencyChart extends StatelessWidget {
  const _FrequencyChart({required this.keywords});

  final List<KeywordInsight> keywords;

  @override
  Widget build(BuildContext context) {
    final maxFrequency = keywords.first.frequency;
    return Column(
      children: keywords.map((keyword) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      keyword.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text('${keyword.frequency}'),
                ],
              ),
              const SizedBox(height: 6),
              LinearProgressIndicator(
                value: keyword.frequency / maxFrequency,
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

class _KeywordSection extends StatelessWidget {
  const _KeywordSection({required this.title, required this.child});

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

class _KeywordMessage extends StatelessWidget {
  const _KeywordMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            const Icon(Icons.key_off_rounded, size: 38),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
