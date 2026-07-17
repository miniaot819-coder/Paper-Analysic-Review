import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../firebase/analytics_tracking_service.dart';
import '../models/dashboard_data.dart';
import '../models/openalex_search_state.dart';
import '../models/publication.dart';
import '../models/ranked_item.dart';
import '../models/trend_data.dart';
import '../utils/app_routes.dart';
import '../viewmodels/dashboard_view_model.dart';
import '../viewmodels/research_tab_view_model.dart';
import '../widgets/article_card.dart';
import '../widgets/openalex_pagination_controls.dart';

enum _RankTarget { author, journal }

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({required this.onOpenNotifications, super.key});

  final VoidCallback onOpenNotifications;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static final DashboardViewModel _dashboardViewModel = DashboardViewModel();

  final TextEditingController _topicController = TextEditingController(
    text: 'Artificial Intelligence',
  );
  final FocusNode _topicFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ResearchTabViewModel>().loadInitial();
      }
    });
  }

  @override
  void dispose() {
    _topicController.dispose();
    _topicFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadTopic(String topic) async {
    final trimmed = topic.trim();
    if (trimmed.isEmpty) return;
    final viewModel = context.read<ResearchTabViewModel>();
    _topicController.text = trimmed;
    _topicController.selection = TextSelection.collapsed(
      offset: _topicController.text.length,
    );
    await viewModel.search(trimmed);
  }

  void _searchFromInput() {
    _loadTopic(_topicController.text);
  }

  void _focusTopicSearch() {
    _topicFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ResearchTabViewModel>();
    final state = viewModel.state;
    final publications = state.publications;
    final errorMessage = state.hasError
        ? state.errorMessage ?? 'Could not load OpenAlex data.'
        : state.status == OpenAlexSearchStatus.success && publications.isEmpty
        ? 'No matching data was found for this topic.'
        : null;
    final presentation = _dashboardViewModel.presentationFor(publications);
    final dashboard = presentation.dashboard;
    final trend = presentation.trend;
    final topJournals = presentation.topJournals;
    final topAuthors = presentation.topAuthors;
    final topPaper = presentation.mostInfluentialPublication;

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        key: const Key('home_screen'),
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: _TopBar(
                title: 'Overview',
                subtitle: 'OpenAlex research summary for your selected topic',
                onSearchTap: _focusTopicSearch,
                onNotificationTap: widget.onOpenNotifications,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _TopicSummaryCard(
                controller: _topicController,
                focusNode: _topicFocusNode,
                selectedTopic: viewModel.topic,
                sourceLabel: 'OpenAlex',
                isLoading: state.isLoading,
                onSearch: _searchFromInput,
              ),
            ),
          ),
          if (state.status == OpenAlexSearchStatus.success &&
              publications.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: OpenAlexPaginationControls(
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
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _SectionHeader(
                title: 'Key Metrics',
                actionText: 'Refresh',
                onActionTap: _searchFromInput,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: _MetricsGrid(dashboard: dashboard),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _SectionHeader(
                title: 'Publication Trend',
                actionText: '',
                onActionTap: () {},
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: _TrendCard(trend: trend, selectedTopic: viewModel.topic),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _SectionHeader(
                title: 'Most Influential Publication',
                actionText: '',
                onActionTap: () {},
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: _MostInfluentialCard(
                publication: topPaper,
                onTap: topPaper == null
                    ? null
                    : () {
                        unawaited(
                          AnalyticsTrackingService.instance.logViewPublication(
                            title: topPaper.title,
                            year: topPaper.publicationYear,
                          ),
                        );
                        Navigator.of(
                          context,
                        ).push(AppRoutes.publicationDetail(topPaper));
                      },
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _SectionHeader(
                title: 'Top Journals',
                actionText: '',
                onActionTap: () {},
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: _RankList(
                items: topJournals,
                leadingColor: const Color(0xFF00A676),
                countLabel: 'works',
                onItemTap: (item) => _showRankedPublications(
                  context,
                  item: item,
                  target: _RankTarget.journal,
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _SectionHeader(
                title: 'Top Authors',
                actionText: '',
                onActionTap: () {},
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
              child: _RankList(
                items: topAuthors,
                leadingColor: const Color(0xFFFF8A00),
                countLabel: 'works',
                onItemTap: (item) => _showRankedPublications(
                  context,
                  item: item,
                  target: _RankTarget.author,
                ),
              ),
            ),
          ),
          if (errorMessage != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                child: _NoticeBanner(message: errorMessage),
              ),
            ),
        ],
      ),
    );
  }

  void _showRankedPublications(
    BuildContext context, {
    required RankedItem item,
    required _RankTarget target,
  }) {
    final id = item.id?.trim();
    if (id == null || id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('OpenAlex did not return an ID for ${item.name}.'),
        ),
      );
      return;
    }

    if (target == _RankTarget.journal) {
      unawaited(AnalyticsTrackingService.instance.logViewJournal(item.name));
    }

    final viewModel = context.read<ResearchTabViewModel>();
    final publicationsFuture = target == _RankTarget.author
        ? viewModel.getWorksByAuthor(id, perPage: item.count)
        : viewModel.getWorksByJournal(id, perPage: item.count);
    final titlePrefix = target == _RankTarget.author ? 'Author' : 'Journal';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.78,
          minChildSize: 0.45,
          maxChildSize: 0.92,
          builder: (context, scrollController) {
            return _RankedPublicationSheet(
              title: '$titlePrefix: ${item.name}',
              publicationsFuture: publicationsFuture,
              scrollController: scrollController,
              onPublicationTap: (publication) {
                unawaited(
                  AnalyticsTrackingService.instance.logViewPublication(
                    title: publication.title,
                    year: publication.publicationYear,
                  ),
                );
                Navigator.of(sheetContext).pop();
                Navigator.of(
                  context,
                ).push(AppRoutes.publicationDetail(publication));
              },
            );
          },
        );
      },
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    required this.subtitle,
    required this.onSearchTap,
    required this.onNotificationTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onSearchTap;
  final VoidCallback onNotificationTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [Color(0xFF2B6DE9), Color(0xFF5B8DEF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2B6DE9).withValues(alpha: 0.22),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.auto_awesome_rounded, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
        _ActionIcon(onTap: onSearchTap, icon: Icons.search_rounded),
        const SizedBox(width: 10),
        _ActionIcon(
          onTap: onNotificationTap,
          icon: Icons.notifications_none_rounded,
        ),
      ],
    );
  }
}

class _TopicSummaryCard extends StatelessWidget {
  const _TopicSummaryCard({
    required this.controller,
    required this.focusNode,
    required this.selectedTopic,
    required this.sourceLabel,
    required this.isLoading,
    required this.onSearch,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String selectedTopic;
  final String sourceLabel;
  final bool isLoading;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFFEEF4FF), Color(0xFFF9FBFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: const Color(0xFFDDE9FF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Topic Summary',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Topic: $selectedTopic',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF4B5563),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Data source: $sourceLabel',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF4B5563)),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  key: const Key('home_topic_search_field'),
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => onSearch(),
                  decoration: InputDecoration(
                    hintText:
                        'Enter a topic, for example: Artificial Intelligence',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(color: Color(0xFF2B6DE9)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 52,
                child: FilledButton(
                  key: const Key('home_topic_search_button'),
                  onPressed: isLoading ? null : onSearch,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2B6DE9),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
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
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({required this.dashboard});

  final DashboardData dashboard;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.08,
      children: [
        _MetricCard(
          title: 'Total Publications',
          value: '${dashboard.totalPublications}',
          subtitle: 'Works retrieved from OpenAlex',
          icon: Icons.article_rounded,
          color: const Color(0xFF2B6DE9),
        ),
        _MetricCard(
          title: 'Average Citations',
          value: dashboard.averageCitationCount.toStringAsFixed(1),
          subtitle: 'Average cited-by count per work',
          icon: Icons.format_quote_rounded,
          color: const Color(0xFF00A676),
        ),
        _MetricCard(
          title: 'Most Active Year',
          value: dashboard.mostActiveYear > 0
              ? '${dashboard.mostActiveYear}'
              : 'N/A',
          subtitle: 'Year with the most publications',
          icon: Icons.calendar_month_rounded,
          color: const Color(0xFFFF8A00),
        ),
        _MetricCard(
          title: 'Top Journal',
          value: dashboard.topJournal,
          subtitle: 'Journal with the most publications',
          icon: Icons.menu_book_rounded,
          color: const Color(0xFF8B5CF6),
        ),
        _MetricCard(
          title: 'Top Author',
          value: dashboard.topAuthor,
          subtitle: 'Author with the most loaded publications',
          icon: Icons.person_search_rounded,
          color: const Color(0xFF0F766E),
        ),
        _MetricCard(
          title: 'Top Paper Citations',
          value: dashboard.mostInfluentialPaperCitations.toString(),
          subtitle: dashboard.mostInfluentialPaper,
          icon: Icons.workspace_premium_rounded,
          color: const Color(0xFFBE123C),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE9EEF5)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const Spacer(),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: const Color(0xFF6B7280),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: const Color(0xFF9CA3AF),
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendCard extends StatelessWidget {
  const _TrendCard({required this.trend, required this.selectedTopic});

  final List<TrendData> trend;
  final String selectedTopic;

  @override
  Widget build(BuildContext context) {
    final maxCount = trend.isEmpty
        ? 1
        : trend
              .map((item) => item.publicationCount)
              .reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE9EEF5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Publication Trend Chart',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Publications by year for "$selectedTopic"',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: const Color(0xFF6B7280)),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 180,
            child: CustomPaint(
              painter: _TrendPainter(trend: trend, maxCount: maxCount),
              child: const SizedBox.expand(),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: trend
                .map(
                  (item) => _LegendPill(
                    label: '${item.year}',
                    value: '${item.publicationCount} works',
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  _TrendPainter({required this.trend, required this.maxCount});

  final List<TrendData> trend;
  final int maxCount;

  @override
  void paint(Canvas canvas, Size size) {
    if (trend.isEmpty) return;

    final gridPaint = Paint()
      ..color = const Color(0xFFE5E7EB)
      ..strokeWidth = 1;

    for (var i = 0; i < 4; i++) {
      final y = size.height * (i / 3);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final barWidth = size.width / (trend.length * 1.6);
    final spacing = barWidth * 0.6;
    final barPaint = Paint()..color = const Color(0xFF2B6DE9);

    for (var i = 0; i < trend.length; i++) {
      final item = trend[i];
      final barHeight = (item.publicationCount / maxCount) * (size.height - 20);
      final left = i * (barWidth + spacing) + spacing * 0.2;
      final top = size.height - barHeight;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, barWidth, barHeight),
        const Radius.circular(10),
      );
      canvas.drawRRect(rect, barPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) {
    return oldDelegate.trend != trend || oldDelegate.maxCount != maxCount;
  }
}

class _MostInfluentialCard extends StatelessWidget {
  const _MostInfluentialCard({required this.publication, required this.onTap});

  final Publication? publication;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if (publication == null) {
      return _NoticeBanner(
        message: 'No influential publication is available in the current data.',
      );
    }

    final p = publication!;

    return Material(
      key: const Key('most_influential_publication_card'),
      color: Colors.white,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFFE9EEF5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F7FF),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: Color(0xFF2B6DE9),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF111827),
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          p.journalName,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: const Color(0xFF6B7280),
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _TagPill(label: 'Year ${p.publicationYear}'),
                  _TagPill(label: '${p.citationCount} citations'),
                  _TagPill(label: '${p.authors.length} authors'),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                p.abstractText?.trim().isNotEmpty == true
                    ? p.abstractText!
                    : 'No abstract is available from OpenAlex.',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF4B5563),
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RankList extends StatelessWidget {
  const _RankList({
    required this.items,
    required this.leadingColor,
    required this.countLabel,
    required this.onItemTap,
  });

  final List<RankedItem> items;
  final Color leadingColor;
  final String countLabel;
  final ValueChanged<RankedItem> onItemTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE9EEF5)),
      ),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            _RankRow(
              index: i + 1,
              item: items[i],
              leadingColor: leadingColor,
              countLabel: countLabel,
              onTap: () => onItemTap(items[i]),
            ),
            if (i != items.length - 1) const Divider(height: 24),
          ],
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('No data available'),
            ),
        ],
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow({
    required this.index,
    required this.item,
    required this.leadingColor,
    required this.countLabel,
    required this.onTap,
  });

  final int index;
  final RankedItem item;
  final Color leadingColor;
  final String countLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: leadingColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    '$index',
                    style: TextStyle(
                      color: leadingColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.subtitle ?? 'Publication',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Text(
                  '${item.count} $countLabel',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF334155),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
            ],
          ),
        ),
      ),
    );
  }
}

class _RankedPublicationSheet extends StatelessWidget {
  const _RankedPublicationSheet({
    required this.title,
    required this.publicationsFuture,
    required this.scrollController,
    required this.onPublicationTap,
  });

  final String title;
  final Future<List<Publication>> publicationsFuture;
  final ScrollController scrollController;
  final ValueChanged<Publication> onPublicationTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: FutureBuilder<List<Publication>>(
        future: publicationsFuture,
        builder: (context, snapshot) {
          final publications = snapshot.data ?? const <Publication>[];

          return ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF111827),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              if (snapshot.connectionState == ConnectionState.waiting)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 36),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (publications.isEmpty)
                const _NoticeBanner(
                  message:
                      'No OpenAlex publications are available for this item.',
                )
              else
                for (var index = 0; index < publications.length; index++) ...[
                  ArticleCard(
                    publication: publications[index],
                    onTap: () => onPublicationTap(publications[index]),
                  ),
                  if (index != publications.length - 1)
                    const SizedBox(height: 12),
                ],
            ],
          );
        },
      ),
    );
  }
}

class _LegendPill extends StatelessWidget {
  const _LegendPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Text(
        '$label · $value',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: const Color(0xFF334155),
        ),
      ),
    );
  }
}

class _TagPill extends StatelessWidget {
  const _TagPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F7FF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFDDE9FF)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: const Color(0xFF2B6DE9),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.actionText,
    required this.onActionTap,
  });

  final String title;
  final String actionText;
  final VoidCallback onActionTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF111827),
          ),
        ),
        TextButton(
          onPressed: onActionTap,
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF2B6DE9),
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            actionText,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({required this.onTap, required this.icon});

  final VoidCallback onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Icon(icon, color: const Color(0xFF6B7280)),
      ),
    );
  }
}

class _NoticeBanner extends StatelessWidget {
  const _NoticeBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: const Color(0xFF92400E),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
