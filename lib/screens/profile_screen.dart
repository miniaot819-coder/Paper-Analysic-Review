import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../viewmodels/authentication_view_model.dart';
import '../viewmodels/firebase_demo_view_model.dart';
import '../viewmodels/report_export_view_model.dart';
import '../viewmodels/research_tab_view_model.dart';
import '../viewmodels/notification_center_view_model.dart';
import '../widgets/firebase_demo_card.dart';
import '../widgets/notification_center_card.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({required this.firebaseEnabled, super.key});

  final bool firebaseEnabled;

  Future<void> _signOut(
    BuildContext context,
    AuthenticationViewModel authViewModel,
    ReportExportViewModel reportViewModel,
  ) async {
    try {
      await reportViewModel.cancel();
      await authViewModel.signOut();
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not sign out. Please try again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _openReport(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    try {
      if (uri != null &&
          await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        return;
      }
    } catch (_) {
      // Platform/plugin failures use the same user-facing recovery message.
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not open the report link.')),
    );
  }

  Future<void> _copyUrl(BuildContext context, String url) async {
    await Clipboard.setData(ClipboardData(text: url));
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('PDF link copied.')));
  }

  @override
  Widget build(BuildContext context) {
    if (!firebaseEnabled) {
      return const SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Firebase is disabled in this test environment.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final authViewModel = context.watch<AuthenticationViewModel>();
    final homeViewModel = context.watch<ResearchTabViewModel>();
    final reportViewModel = context.watch<ReportExportViewModel>();
    final notificationViewModel = context.watch<NotificationCenterViewModel>();
    final firebaseDemoViewModel = context.read<FirebaseDemoViewModel>();
    final user = authViewModel.currentUser;
    final publications = homeViewModel.state.publications;

    return SafeArea(
      child: ListView(
        key: const Key('profile_screen'),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        children: [
          Text(
            'Profile',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            'Account, reports, and Firebase configuration',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: const Color(0xFF64748B)),
          ),
          const SizedBox(height: 20),
          Card(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: const Color(0xFFEFF6FF),
                    backgroundImage: user?.photoURL == null
                        ? null
                        : NetworkImage(user!.photoURL!),
                    child: user?.photoURL == null
                        ? const Icon(Icons.person_rounded, size: 32)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          key: const Key('profile_user_name'),
                          user?.displayName ?? 'Firebase user',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          key: const Key('profile_user_email'),
                          user?.email ?? 'No email available',
                          style: const TextStyle(color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          NotificationCenterCard(viewModel: notificationViewModel),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Report Export',
            icon: Icons.picture_as_pdf_rounded,
            children: [
              _ReportSummary(
                topic: homeViewModel.topic,
                publicationCount: publications.length,
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: const Key('export_pdf_button'),
                  onPressed: reportViewModel.isBusy
                      ? null
                      : () => unawaited(
                          reportViewModel.export(
                            userId: user?.uid,
                            topic: homeViewModel.topic,
                            publications: publications,
                          ),
                        ),
                  icon: reportViewModel.isBusy
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.cloud_upload_rounded),
                  label: Text(
                    reportViewModel.isBusy
                        ? 'Processing report...'
                        : 'Generate & Upload PDF',
                  ),
                ),
              ),
              if (reportViewModel.isBusy) ...[
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  key: const Key('report_upload_progress'),
                  value: reportViewModel.status == ReportExportStatus.generating
                      ? null
                      : reportViewModel.progress,
                ),
                const SizedBox(height: 6),
                Text(
                  reportViewModel.status == ReportExportStatus.generating
                      ? 'Generating PDF document...'
                      : 'Uploading to Firebase Storage '
                            '${(reportViewModel.progress * 100).round()}%',
                  style: const TextStyle(color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    key: const Key('cancel_pdf_button'),
                    onPressed: () => unawaited(reportViewModel.cancel()),
                    icon: const Icon(Icons.close_rounded),
                    label: const Text('Cancel export'),
                  ),
                ),
              ],
              if (reportViewModel.status == ReportExportStatus.failure ||
                  reportViewModel.status == ReportExportStatus.cancelled) ...[
                const SizedBox(height: 12),
                _StatusMessage(
                  key: Key(
                    reportViewModel.status == ReportExportStatus.cancelled
                        ? 'report_export_cancelled'
                        : 'report_export_error',
                  ),
                  icon: reportViewModel.status == ReportExportStatus.cancelled
                      ? Icons.cancel_outlined
                      : Icons.error_outline_rounded,
                  color: reportViewModel.status == ReportExportStatus.cancelled
                      ? const Color(0xFF475569)
                      : const Color(0xFFB91C1C),
                  background:
                      reportViewModel.status == ReportExportStatus.cancelled
                      ? const Color(0xFFF1F5F9)
                      : const Color(0xFFFEF2F2),
                  message:
                      reportViewModel.errorMessage ??
                      'Could not export report.',
                ),
                if (reportViewModel.canRetry) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      key: const Key('retry_pdf_button'),
                      onPressed: () => unawaited(reportViewModel.retry()),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Retry'),
                    ),
                  ),
                ],
              ],
              if (reportViewModel.status == ReportExportStatus.success &&
                  reportViewModel.downloadUrl != null) ...[
                const SizedBox(height: 12),
                const _StatusMessage(
                  key: Key('report_export_success'),
                  icon: Icons.check_circle_outline_rounded,
                  color: Color(0xFF047857),
                  background: Color(0xFFECFDF5),
                  message: 'PDF uploaded to Firebase Storage.',
                ),
                const SizedBox(height: 10),
                SelectableText(
                  reportViewModel.downloadUrl!,
                  key: const Key('report_download_url'),
                  style: const TextStyle(
                    color: Color(0xFF1D4ED8),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton.icon(
                      key: const Key('open_pdf_button'),
                      onPressed: () => unawaited(
                        _openReport(context, reportViewModel.downloadUrl!),
                      ),
                      icon: const Icon(Icons.open_in_new_rounded),
                      label: const Text('Open PDF'),
                    ),
                    TextButton.icon(
                      key: const Key('copy_pdf_url_button'),
                      onPressed: () => unawaited(
                        _copyUrl(context, reportViewModel.downloadUrl!),
                      ),
                      icon: const Icon(Icons.copy_rounded),
                      label: const Text('Copy URL'),
                    ),
                  ],
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          FirebaseDemoCard(viewModel: firebaseDemoViewModel),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            key: const Key('profile_sign_out_button'),
            onPressed: () => _signOut(context, authViewModel, reportViewModel),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}

class _ReportSummary extends StatelessWidget {
  const _ReportSummary({required this.topic, required this.publicationCount});

  final String topic;
  final int publicationCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Home topic', style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 3),
          Text(
            topic,
            key: const Key('report_topic'),
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text('$publicationCount publications will be included'),
        ],
      ),
    );
  }
}

class _StatusMessage extends StatelessWidget {
  const _StatusMessage({
    required this.icon,
    required this.color,
    required this.background,
    required this.message,
    super.key,
  });

  final IconData icon;
  final Color color;
  final Color background;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: TextStyle(color: color)),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            ...children,
          ],
        ),
      ),
    );
  }
}
