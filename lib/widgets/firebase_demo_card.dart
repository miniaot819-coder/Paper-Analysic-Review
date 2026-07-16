import 'dart:async';

import 'package:flutter/material.dart';

import '../viewmodels/firebase_demo_view_model.dart';

class FirebaseDemoCard extends StatelessWidget {
  const FirebaseDemoCard({required this.viewModel, super.key});

  final FirebaseDemoViewModel viewModel;

  Future<void> _confirmTestCrash(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: const Key('test_crash_confirmation_dialog'),
        icon: const Icon(Icons.warning_amber_rounded, color: Color(0xFFB91C1C)),
        title: const Text('Crash the app for testing?'),
        content: const Text(
          'The app will close immediately and any unsaved work may be lost. '
          'Continue only when you are collecting Crashlytics evidence.',
        ),
        actions: [
          TextButton(
            key: const Key('cancel_test_crash_button'),
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('confirm_test_crash_button'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFB91C1C),
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Crash app'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await viewModel.triggerTestCrash();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) => _buildCard(context),
    );
  }

  Widget _buildCard(BuildContext context) {
    return Card(
      key: const Key('firebase_demo_card'),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.science_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Text(
                  'Firebase Demo',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              'Remote Config',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            _ConfigRow(
              key: const Key('max_journals_config'),
              valueKey: const Key('max_journals_config_value'),
              label: 'Maximum journals displayed',
              value: viewModel.maxJournals.toString(),
            ),
            const Divider(height: 24),
            _ConfigRow(
              key: const Key('max_keywords_config'),
              valueKey: const Key('max_keywords_config_value'),
              label: 'Maximum keywords displayed',
              value: viewModel.maxKeywords.toString(),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              key: const Key('refresh_remote_config_button'),
              onPressed: viewModel.isRefreshingConfig
                  ? null
                  : () => unawaited(viewModel.refreshRemoteConfig()),
              icon: viewModel.isRefreshingConfig
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded),
              label: Text(
                viewModel.isRefreshingConfig
                    ? 'Fetching configuration...'
                    : 'Fetch & Activate',
              ),
            ),
            if (viewModel.remoteConfigMessage != null)
              _FeedbackText(
                key: const Key('remote_config_success'),
                text: viewModel.remoteConfigMessage!,
                isError: false,
              ),
            if (viewModel.remoteConfigError != null)
              _FeedbackText(
                key: const Key('remote_config_error'),
                text: viewModel.remoteConfigError!,
                isError: true,
              ),
            const Divider(height: 32),
            Text(
              'Crashlytics',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            const Text(
              'A handled exception keeps the app running. A test crash closes it immediately.',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  key: const Key('record_handled_exception_button'),
                  onPressed: viewModel.isRecordingHandledException
                      ? null
                      : () => unawaited(viewModel.recordHandledException()),
                  icon: viewModel.isRecordingHandledException
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.bug_report_outlined),
                  label: const Text('Handled exception'),
                ),
                FilledButton.icon(
                  key: const Key('test_crash_button'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFB91C1C),
                  ),
                  onPressed: () => unawaited(_confirmTestCrash(context)),
                  icon: const Icon(Icons.warning_amber_rounded),
                  label: const Text('Test crash'),
                ),
              ],
            ),
            if (viewModel.crashlyticsMessage != null)
              _FeedbackText(
                key: const Key('crashlytics_success'),
                text: viewModel.crashlyticsMessage!,
                isError: false,
              ),
            if (viewModel.crashlyticsError != null)
              _FeedbackText(
                key: const Key('crashlytics_error'),
                text: viewModel.crashlyticsError!,
                isError: true,
              ),
          ],
        ),
      ),
    );
  }
}

class _FeedbackText extends StatelessWidget {
  const _FeedbackText({required this.text, required this.isError, super.key});

  final String text;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Text(
        text,
        style: TextStyle(
          color: isError ? const Color(0xFFB91C1C) : const Color(0xFF047857),
        ),
      ),
    );
  }
}

class _ConfigRow extends StatelessWidget {
  const _ConfigRow({
    required this.label,
    required this.value,
    required this.valueKey,
    super.key,
  });

  final String label;
  final String value;
  final Key valueKey;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            key: valueKey,
            value,
            style: const TextStyle(
              color: Color(0xFF1D4ED8),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}
