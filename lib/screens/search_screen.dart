import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../firebase/analytics_tracking_service.dart';
import '../models/publication.dart';
import '../utils/app_routes.dart';
import '../viewmodels/research_tab_view_model.dart';
import '../widgets/article_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  static const List<String> _topics = <String>[
    'AI',
    'Software Engineering',
    'Data Science',
    'Cybersecurity',
    'Biomedicine',
    'IoT',
  ];

  final TextEditingController _searchController = TextEditingController(
    text: 'AI',
  );
  final TextEditingController _publicationLimitController =
      TextEditingController(text: '20');
  int _selectedTopicIndex = 0;
  int _sortIndex = 0;

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
    _searchController.dispose();
    _publicationLimitController.dispose();
    super.dispose();
  }

  Future<void> _searchTopic(String keyword) async {
    final trimmed = keyword.trim();
    if (trimmed.isEmpty) return;
    final viewModel = context.read<ResearchTabViewModel>();
    final publicationLimit = viewModel.normalizePublicationLimit(
      _publicationLimitController.text,
    );
    _publicationLimitController.text = publicationLimit.toString();
    await viewModel.search(trimmed, perPage: publicationLimit);
    if (!mounted) return;
    setState(() {
      _selectedTopicIndex = _topics.indexOf(trimmed);
    });
  }

  void _submitSearch() {
    _searchTopic(_searchController.text);
  }

  void _selectTopic(int index) {
    setState(() {
      _selectedTopicIndex = index;
      _searchController.text = _topics[index];
      _searchController.selection = TextSelection.collapsed(
        offset: _searchController.text.length,
      );
    });
    _searchTopic(_topics[index]);
  }

  void _applyRecentSearch(String keyword) {
    setState(() {
      _searchController.text = keyword;
      _searchController.selection = TextSelection.collapsed(
        offset: _searchController.text.length,
      );
    });
    _searchTopic(keyword);
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ResearchTabViewModel>();
    final state = viewModel.state;
    final publications = _sortedPublications(state.publications);
    final isInitialState =
        !state.isLoading && !state.hasError && publications.isEmpty;

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            floating: false,
            automaticallyImplyLeading: false,
            backgroundColor: const Color(0xFFF5F7FB),
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            toolbarHeight: 164,
            titleSpacing: 0,
            title: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              child: _HeaderSearchBar(
                controller: _searchController,
                publicationLimitController: _publicationLimitController,
                publicationLimit: viewModel.publicationLimit,
                isLoading: state.isLoading,
                onSubmitted: (_) => _submitSearch(),
                onSearchTap: _submitSearch,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HeroCard(
                    query: _searchController.text.trim().isEmpty
                        ? 'Explore Publications'
                        : _searchController.text.trim(),
                    count: state.publications.length,
                  ),
                  const SizedBox(height: 16),
                  _SectionHeader(
                    title: 'Popular Topics',
                    actionText: '',
                    onActionTap: () {},
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 38,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemBuilder: (context, index) {
                        return _TopicChip(
                          label: _topics[index],
                          selected: index == _selectedTopicIndex,
                          onTap: () => _selectTopic(index),
                        );
                      },
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: 10),
                      itemCount: _topics.length,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _SectionHeader(
                    title: 'Recent Searches',
                    actionText: viewModel.recentSearches.isEmpty ? '' : 'Clear',
                    onActionTap: viewModel.clearRecentSearches,
                  ),
                  const SizedBox(height: 10),
                  if (viewModel.recentSearches.isEmpty)
                    _EmptyHint(
                      icon: Icons.history_rounded,
                      message: 'No recent searches yet.',
                    )
                  else
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: viewModel.recentSearches
                          .map(
                            (keyword) => _RecentSearchChip(
                              label: keyword,
                              onTap: () => _applyRecentSearch(keyword),
                            ),
                          )
                          .toList(),
                    ),
                  const SizedBox(height: 18),
                  _SectionHeader(
                    title: 'Search Results',
                    actionText: _sortLabel(_sortIndex),
                    onActionTap: () {
                      setState(() {
                        _sortIndex = (_sortIndex + 1) % 3;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  if (state.isLoading)
                    const _LoadingList()
                  else if (state.hasError)
                    _StatusCard(
                      message:
                          state.errorMessage ??
                          'An error occurred while loading data.',
                    )
                  else if (publications.isEmpty)
                    _StatusCard(
                      message: isInitialState
                          ? 'Enter a keyword to start searching publications.'
                          : 'No matching results. Try another keyword.',
                    )
                  else
                    ListView.separated(
                      itemCount: publications.length,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        final publication = publications[index];
                        return ArticleCard(
                          publication: publication,
                          onTap: () {
                            unawaited(
                              AnalyticsTrackingService.instance
                                  .logViewPublication(
                                    title: publication.title,
                                    year: publication.publicationYear,
                                  ),
                            );
                            Navigator.of(
                              context,
                            ).push(AppRoutes.publicationDetail(publication));
                          },
                        );
                      },
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 14),
                    ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Publication> _sortedPublications(List<Publication> publications) {
    final sorted = List<Publication>.from(publications);
    switch (_sortIndex) {
      case 1:
        sorted.sort((a, b) => b.publicationYear.compareTo(a.publicationYear));
        break;
      case 2:
        sorted.sort((a, b) => b.citationCount.compareTo(a.citationCount));
        break;
      default:
        break;
    }
    return sorted;
  }

  String _sortLabel(int index) {
    switch (index) {
      case 1:
        return 'Newest';
      case 2:
        return 'Most Cited';
      default:
        return 'Default';
    }
  }
}

class _HeaderSearchBar extends StatelessWidget {
  const _HeaderSearchBar({
    required this.controller,
    required this.publicationLimitController,
    required this.publicationLimit,
    required this.isLoading,
    required this.onSubmitted,
    required this.onSearchTap,
  });

  final TextEditingController controller;
  final TextEditingController publicationLimitController;
  final int publicationLimit;
  final bool isLoading;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onSearchTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE8ECF2)),
              ),
              child: IconButton(
                onPressed: () {
                  Navigator.of(context).maybePop();
                },
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: Color(0xFF111827),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFE8ECF2)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.search_rounded,
                      size: 24,
                      color: Color(0xFF6B7280),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: controller,
                        onSubmitted: onSubmitted,
                        textInputAction: TextInputAction.search,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isCollapsed: true,
                          hintText: 'Search research topics...',
                        ),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: const Color(0xFF111827),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    InkWell(
                      onTap: isLoading ? null : onSearchTap,
                      borderRadius: BorderRadius.circular(14),
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Icons.arrow_forward_rounded,
                                size: 22,
                                color: Color(0xFF111827),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          controller: publicationLimitController,
          enabled: !isLoading,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => onSearchTap(),
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
          ),
        ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.query, required this.count});

  final String query;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF2B6DE9), Color(0xFF5B8DEF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2B6DE9).withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  query,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  count > 0
                      ? 'Found $count matching publications.'
                      : 'Enter a keyword to start exploring.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
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
        if (actionText.isNotEmpty)
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

class _RecentSearchChip extends StatelessWidget {
  const _RecentSearchChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InputChip(
      onPressed: onTap,
      label: Text(label),
      avatar: const Icon(Icons.history_rounded, size: 16),
      backgroundColor: const Color(0xFFF8FAFC),
      side: const BorderSide(color: Color(0xFFE5E7EB)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    );
  }
}

class _TopicChip extends StatelessWidget {
  const _TopicChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF2B6DE9) : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? const Color(0xFF2B6DE9) : const Color(0xFFE5E7EB),
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : const Color(0xFF374151),
          ),
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: const Color(0xFF374151),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F7FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: const Color(0xFF2B6DE9)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF4B5563),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingList extends StatelessWidget {
  const _LoadingList();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (index) => Padding(
          padding: EdgeInsets.only(bottom: index == 2 ? 0 : 14),
          child: Container(
            height: 170,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE9EEF5)),
            ),
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ),
        ),
      ),
    );
  }
}
