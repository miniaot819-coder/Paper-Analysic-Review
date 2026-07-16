import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../firebase/remote_config_service.dart';
import '../models/openalex_search_state.dart';
import '../models/publication.dart';
import '../services/analytics_service.dart';
import '../viewmodels/research_tab_view_model.dart';
import '../widgets/analysis_charts.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  final TextEditingController _topicController = TextEditingController(
    text: 'AI',
  );
  final TextEditingController _publicationLimitController =
      TextEditingController(text: '20');
  final AnalyticsService _analyticsService = const AnalyticsService();

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
    _publicationLimitController.dispose();
    super.dispose();
  }

  Future<void> _searchTopic(String topic) async {
    final trimmedTopic = topic.trim();
    if (trimmedTopic.isEmpty) return;
    final viewModel = context.read<ResearchTabViewModel>();
    final publicationLimit = viewModel.normalizePublicationLimit(
      _publicationLimitController.text,
    );
    _topicController.text = trimmedTopic;
    _topicController.selection = TextSelection.collapsed(
      offset: _topicController.text.length,
    );
    _publicationLimitController.text = publicationLimit.toString();
    await viewModel.search(trimmedTopic, perPage: publicationLimit);
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ResearchTabViewModel>();
    final state = viewModel.state;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () => _searchTopic(viewModel.topic),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            _Header(
              controller: _topicController,
              isLoading: state.isLoading,
              publicationLimit: viewModel.publicationLimit,
              publicationLimitController: _publicationLimitController,
              onSubmitted: _searchTopic,
              onSearchTap: () => _searchTopic(_topicController.text),
            ),
            const SizedBox(height: 16),
            if (state.status == OpenAlexSearchStatus.idle)
              _ReadyPanel(
                topic: viewModel.topic,
                onLoad: () => _searchTopic(viewModel.topic),
              )
            else if (state.isLoading)
              const _LoadingPanel()
            else if (state.hasError)
              _ErrorPanel(
                message: state.errorMessage ?? 'Could not load trend data.',
                onRetry: () => _searchTopic(viewModel.topic),
              )
            else if (state.publications.isEmpty)
              _EmptyPanel(topic: viewModel.topic)
            else
              _AnalysisContent(
                topic: viewModel.topic,
                publications: state.publications,
                analyticsService: _analyticsService,
              ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.controller,
    required this.isLoading,
    required this.publicationLimit,
    required this.publicationLimitController,
    required this.onSubmitted,
    required this.onSearchTap,
  });

  final TextEditingController controller;
  final bool isLoading;
  final int publicationLimit;
  final TextEditingController publicationLimitController;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onSearchTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Trend Analysis',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Analyze real OpenAlex publication data by topic.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF6B7280),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                enabled: !isLoading,
                textInputAction: TextInputAction.search,
                onSubmitted: isLoading ? null : onSubmitted,
                decoration: InputDecoration(
                  hintText: 'Enter a research topic',
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: Color(0xFF2B6DE9),
                      width: 1.4,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 52,
              height: 52,
              child: FilledButton(
                onPressed: isLoading ? null : onSearchTap,
                style: FilledButton.styleFrom(
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.arrow_forward_rounded),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _PublicationLimitField(
          controller: publicationLimitController,
          enabled: !isLoading,
          onSubmitted: onSearchTap,
        ),
      ],
    );
  }
}

class _PublicationLimitField extends StatelessWidget {
  const _PublicationLimitField({
    required this.controller,
    required this.enabled,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => onSubmitted(),
      decoration: InputDecoration(
        labelText: 'Number of publications',
        hintText: 'Default: 20',
        prefixIcon: const Icon(Icons.filter_list_rounded),
        suffixText: 'works',
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF2B6DE9), width: 1.4),
        ),
      ),
    );
  }
}

class _AnalysisContent extends StatelessWidget {
  const _AnalysisContent({
    required this.topic,
    required this.publications,
    required this.analyticsService,
  });

  final String topic;
  final List<Publication> publications;
  final AnalyticsService analyticsService;

  @override
  Widget build(BuildContext context) {
    final trend = analyticsService.getPublicationTrendByYear(publications);
    final citationTrend = analyticsService.getCitationTrendByYear(publications);
    final topKeywords = analyticsService.getTopKeywords(
      publications,
      limit: RemoteConfigService.instance.maxKeywords,
    );
    final quartileDistribution = analyticsService.getQuartileDistribution(
      publications,
    );
    final mostActiveYear = analyticsService.getMostActiveYear(publications);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SummaryStrip(
          topic: topic,
          publicationCount: publications.length,
          mostActiveYear: mostActiveYear,
          averageCitations: analyticsService.getAverageCitationCount(
            publications,
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final panels = <Widget>[
              _SectionPanel(
                title: 'Publication Trend',
                subtitle: 'Number of publications by year',
                child: PublicationLineChart(data: trend),
              ),
              _SectionPanel(
                title: 'Citation Trend',
                subtitle: 'Total publication citations by year',
                child: CitationLineChart(data: citationTrend),
              ),
              _SectionPanel(
                title: 'Popular Keywords',
                subtitle: 'Keywords that appear most often in publications',
                child: RankedHorizontalBarChart(
                  data: topKeywords,
                  semanticLabel: 'Horizontal keyword ranking chart',
                  unit: 'occurrences',
                ),
              ),
              _SectionPanel(
                title: 'Journal Distribution',
                subtitle: 'Relative Q1-Q4 distribution by journal citations',
                child: QuartileDonutChart(data: quartileDistribution),
              ),
            ];

            if (constraints.maxWidth < 760) {
              return Column(
                children: [
                  for (var index = 0; index < panels.length; index++) ...[
                    panels[index],
                    if (index != panels.length - 1) const SizedBox(height: 16),
                  ],
                ],
              );
            }

            return Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: panels[0]),
                    const SizedBox(width: 16),
                    Expanded(child: panels[1]),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: panels[2]),
                    const SizedBox(width: 16),
                    Expanded(child: panels[3]),
                  ],
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip({
    required this.topic,
    required this.publicationCount,
    required this.mostActiveYear,
    required this.averageCitations,
  });

  final String topic;
  final int publicationCount;
  final int mostActiveYear;
  final double averageCitations;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Topic: $topic',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: const Color(0xFF111827),
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MetricTile(
                label: 'Publications',
                value: publicationCount.toString(),
                icon: Icons.article_outlined,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricTile(
                label: 'Peak Year',
                value: mostActiveYear == 0 ? 'N/A' : mostActiveYear.toString(),
                icon: Icons.timeline_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricTile(
                label: 'Avg. Citations',
                value: averageCitations.toStringAsFixed(1),
                icon: Icons.format_quote_rounded,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF2B6DE9), size: 20),
          const SizedBox(height: 10),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: const Color(0xFF111827),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: const Color(0xFF6B7280),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionPanel extends StatelessWidget {
  const _SectionPanel({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: const Color(0xFF111827),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: const Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _LoadingPanel extends StatelessWidget {
  const _LoadingPanel();

  @override
  Widget build(BuildContext context) {
    return const _StatePanel(
      icon: Icons.sync_rounded,
      title: 'Loading OpenAlex Data',
      message: 'Retrieving real publication data for trend analysis.',
      child: Padding(
        padding: EdgeInsets.only(top: 16),
        child: LinearProgressIndicator(),
      ),
    );
  }
}

class _ReadyPanel extends StatelessWidget {
  const _ReadyPanel({required this.topic, required this.onLoad});

  final String topic;
  final VoidCallback onLoad;

  @override
  Widget build(BuildContext context) {
    return _StatePanel(
      icon: Icons.insights_rounded,
      title: 'Ready to Analyze',
      message: 'Load real OpenAlex data for "$topic" to generate trends.',
      child: Padding(
        padding: const EdgeInsets.only(top: 16),
        child: FilledButton.icon(
          onPressed: onLoad,
          icon: const Icon(Icons.cloud_download_outlined),
          label: const Text('Load Data'),
        ),
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _StatePanel(
      icon: Icons.error_outline_rounded,
      title: 'Could Not Load Analysis',
      message: message,
      child: Padding(
        padding: const EdgeInsets.only(top: 16),
        child: FilledButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Retry'),
        ),
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({required this.topic});

  final String topic;

  @override
  Widget build(BuildContext context) {
    return _StatePanel(
      icon: Icons.search_off_rounded,
      title: 'No Publications Found',
      message: 'OpenAlex returned no publications for "$topic".',
    );
  }
}

class _StatePanel extends StatelessWidget {
  const _StatePanel({
    required this.icon,
    required this.title,
    required this.message,
    this.child,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: const Color(0xFF2B6DE9)),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: const Color(0xFF111827),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF6B7280)),
          ),
          if (child != null) ...[child!],
        ],
      ),
    );
  }
}
