import 'package:flutter/material.dart';

class OpenAlexPaginationControls extends StatelessWidget {
  const OpenAlexPaginationControls({
    required this.loadedCount,
    required this.totalCount,
    required this.hasMore,
    required this.isLoadingMore,
    required this.reachedResultLimit,
    required this.maximumLoadedWorks,
    required this.pageSize,
    required this.onLoadMore,
    required this.onLoadUpToLimit,
    required this.onCancelAutoLoad,
    required this.onRetry,
    this.isAutoLoading = false,
    this.isAutoLoadCancellationPending = false,
    this.autoLoadFailed = false,
    this.loadMoreErrorMessage,
    super.key,
  });

  final int loadedCount;
  final int totalCount;
  final bool hasMore;
  final bool isLoadingMore;
  final bool reachedResultLimit;
  final int maximumLoadedWorks;
  final int pageSize;
  final bool isAutoLoading;
  final bool isAutoLoadCancellationPending;
  final bool autoLoadFailed;
  final String? loadMoreErrorMessage;
  final VoidCallback onLoadMore;
  final VoidCallback onLoadUpToLimit;
  final VoidCallback onCancelAutoLoad;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final displayTotal = totalCount < loadedCount ? loadedCount : totalCount;
    final errorMessage = loadMoreErrorMessage?.trim();
    final loadedLabel = _formatCount(loadedCount);
    final totalLabel = _formatCount(displayTotal);
    final limitLabel = _formatCount(maximumLoadedWorks);
    final cappedTotal = displayTotal > maximumLoadedWorks
        ? maximumLoadedWorks
        : displayTotal;
    final autoLoadTarget = cappedTotal > loadedCount
        ? cappedTotal
        : maximumLoadedWorks;
    final autoLoadTargetLabel = _formatCount(autoLoadTarget);
    final autoLoadProgress = autoLoadTarget <= 0
        ? null
        : (loadedCount / autoLoadTarget).clamp(0.0, 1.0).toDouble();
    final autoLoadButtonLabel = displayTotal <= maximumLoadedWorks
        ? 'Load all $autoLoadTargetLabel'
        : 'Load up to $limitLabel';

    return Card(
      elevation: 0,
      color: const Color(0xFFF8FAFC),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.cloud_download_outlined, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    displayTotal > 0
                        ? 'Loaded $loadedLabel of $totalLabel matching works'
                        : 'Loaded $loadedLabel works',
                    key: const Key('openalex_loaded_status'),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'OpenAlex returns up to ${_formatCount(pageSize)} works per '
              'request. Metrics refresh after every loaded page.',
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
            ),
            if (isAutoLoading) ...[
              const SizedBox(height: 14),
              Semantics(
                liveRegion: true,
                value: '$loadedLabel of $autoLoadTargetLabel works loaded',
                child: Column(
                  key: const Key('openalex_auto_load_progress'),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LinearProgressIndicator(value: autoLoadProgress),
                    const SizedBox(height: 8),
                    Text(
                      isAutoLoadCancellationPending
                          ? 'Stopping after the current request...'
                          : 'Loading $loadedLabel of up to '
                                '$autoLoadTargetLabel works...',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      key: const Key('openalex_auto_load_cancel'),
                      onPressed: isAutoLoadCancellationPending
                          ? null
                          : onCancelAutoLoad,
                      icon: const Icon(Icons.stop_circle_outlined),
                      label: Text(
                        isAutoLoadCancellationPending ? 'Stopping' : 'Cancel',
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (isLoadingMore) ...[
              const SizedBox(height: 14),
              const Row(
                key: Key('openalex_load_more_progress'),
                children: [
                  SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 10),
                  Text('Loading more works...'),
                ],
              ),
            ] else if (errorMessage != null && errorMessage.isNotEmpty) ...[
              const SizedBox(height: 12),
              Semantics(
                liveRegion: true,
                child: Text(
                  errorMessage,
                  key: const Key('openalex_load_more_error'),
                  style: const TextStyle(
                    color: Color(0xFFB91C1C),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (hasMore) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  key: const Key('openalex_load_more_retry'),
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(
                    autoLoadFailed ? 'Retry automatic load' : 'Retry',
                  ),
                ),
              ],
            ] else if (reachedResultLimit) ...[
              const SizedBox(height: 12),
              Text(
                'Reached the $limitLabel-work app limit. '
                'Refine your topic to explore a different result set.',
                key: const Key('openalex_cap_notice'),
                style: const TextStyle(
                  color: Color(0xFF92400E),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ] else if (hasMore) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  FilledButton.tonalIcon(
                    key: const Key('openalex_load_more_button'),
                    onPressed: onLoadMore,
                    icon: const Icon(Icons.add_rounded),
                    label: Text('Load next ${_formatCount(pageSize)}'),
                  ),
                  FilledButton.icon(
                    key: const Key('openalex_auto_load_button'),
                    onPressed: onLoadUpToLimit,
                    icon: const Icon(Icons.downloading_rounded),
                    label: Text(autoLoadButtonLabel),
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 10),
              const Text(
                'All available matching works are loaded.',
                style: TextStyle(
                  color: Color(0xFF047857),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatCount(int value) {
    return value.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ',',
    );
  }
}
