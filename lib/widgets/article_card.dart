import 'package:flutter/material.dart';

import '../models/publication.dart';

class ArticleCard extends StatelessWidget {
  const ArticleCard({super.key, required this.publication, this.onTap});

  final Publication publication;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final logoColor = _colorFromCitations(publication.citationCount);
    final abstractSnippet = _snippet(publication.abstractText);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE9EEF5)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: logoColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: logoColor,
                          borderRadius: BorderRadius.circular(6),
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
                          publication.journalName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF2B6DE9),
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Year ${publication.publicationYear}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: const Color(0xFF8A94A6),
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F7FF),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.format_quote_rounded,
                          size: 14,
                          color: Color(0xFF2B6DE9),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${publication.citationCount} citations',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF2B6DE9),
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                publication.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                  color: const Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 10),
              if (abstractSnippet != null) ...[
                Text(
                  abstractSnippet,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF4B5563),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  _MetaPill(
                    icon: Icons.people_alt_rounded,
                    label: publication.authors.isEmpty
                        ? 'Unknown authors'
                        : '${publication.authors.length} authors',
                  ),
                  const SizedBox(width: 8),
                  _MetaPill(
                    icon: Icons.arrow_forward_rounded,
                    label: 'View details',
                    accent: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({
    required this.icon,
    required this.label,
    this.accent = false,
  });

  final IconData icon;
  final String label;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: accent ? const Color(0xFFF1F7FF) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: accent ? const Color(0xFFDBEAFE) : const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: accent ? const Color(0xFF2B6DE9) : const Color(0xFF6B7280),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: accent ? const Color(0xFF2B6DE9) : const Color(0xFF4B5563),
            ),
          ),
        ],
      ),
    );
  }
}

Color _colorFromCitations(int citations) {
  const palette = <Color>[
    Color(0xFF1E7BF6),
    Color(0xFF00A676),
    Color(0xFFFF8A00),
    Color(0xFF8B5CF6),
    Color(0xFFEF4444),
    Color(0xFF2563EB),
  ];

  if (citations <= 0) return palette.first;
  return palette[citations % palette.length];
}

String? _snippet(String? abstractText) {
  final text = abstractText?.trim();
  if (text == null || text.isEmpty) return null;
  if (text.length <= 180) return text;
  return '${text.substring(0, 180)}...';
}
