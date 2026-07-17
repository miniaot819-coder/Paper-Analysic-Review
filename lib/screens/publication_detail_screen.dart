import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/publication.dart';

class PublicationDetailScreen extends StatelessWidget {
  const PublicationDetailScreen({super.key, required this.publication});

  final Publication publication;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('publication_detail_screen'),
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => Navigator.pop(context),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: Color(0xFF111827),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth = 700.0;
              final padding = constraints.maxWidth >= 720 ? 40.0 : 20.0;

              return Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: padding,
                      vertical: 24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Title Section
                        _TitleSection(publication: publication),
                        const SizedBox(height: 40),

                        // Metadata Row
                        _MetadataRow(publication: publication),
                        const SizedBox(height: 32),

                        // Divider
                        Container(height: 1, color: const Color(0xFFF0F0F0)),
                        const SizedBox(height: 32),

                        // Publication Info
                        _PublicationInfo(publication: publication),
                        const SizedBox(height: 40),

                        // Divider
                        Container(height: 1, color: const Color(0xFFF0F0F0)),
                        const SizedBox(height: 32),

                        // Abstract
                        _AbstractSection(publication: publication),
                        const SizedBox(height: 40),

                        // Divider
                        Container(height: 1, color: const Color(0xFFF0F0F0)),
                        const SizedBox(height: 32),

                        // Action Buttons
                        _ActionButtons(publication: publication),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TitleSection extends StatelessWidget {
  const _TitleSection({required this.publication});

  final Publication publication;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Year tag
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F5FF),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFDEE8F7), width: 0.5),
          ),
          child: Text(
            key: const Key('publication_detail_year'),
            'Year ${_yearText(publication.publicationYear)}',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2B6DE9),
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Title
        Text(
          key: const Key('publication_detail_title'),
          _textOrFallback(publication.title),
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w900,
            color: const Color(0xFF111827),
            height: 1.2,
            fontSize: 32,
          ),
        ),
      ],
    );
  }
}

class _MetadataRow extends StatelessWidget {
  const _MetadataRow({required this.publication});

  final Publication publication;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Journal Name - Prominent Display
        _JournalHighlight(
          journalName: _textOrFallback(publication.journalName),
        ),
        const SizedBox(height: 24),
        // Metadata Grid
        Row(
          children: [
            Expanded(
              child: _MetadataItem(
                valueKey: const Key('publication_detail_citation_count'),
                icon: Icons.person_rounded,
                label: 'Citation Count',
                value: publication.citationCount.toString(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _JournalHighlight extends StatelessWidget {
  const _JournalHighlight({required this.journalName});

  final String journalName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F5FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFDEE8F7), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF2B6DE9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Journal / Publisher',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF9CA3AF),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  key: const Key('publication_detail_journal'),
                  journalName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                    height: 1.3,
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

class _MetadataItem extends StatelessWidget {
  const _MetadataItem({
    required this.label,
    required this.value,
    this.valueKey,
    this.icon,
  });

  final String label;
  final String value;
  final Key? valueKey;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F5FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF2B6DE9), size: 18),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF9CA3AF),
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                key: valueKey,
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PublicationInfo extends StatelessWidget {
  const _PublicationInfo({required this.publication});

  final Publication publication;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _InfoGroup(
          contentKey: const Key('publication_detail_authors'),
          title: 'Authors',
          content: _authorsText(publication.authors),
        ),
        const SizedBox(height: 28),
        _InfoGroup(
          title: 'DOI (Digital Object Identifier)',
          content: _textOrFallback(publication.doi),
        ),
      ],
    );
  }
}

class _InfoGroup extends StatelessWidget {
  const _InfoGroup({
    required this.title,
    required this.content,
    this.contentKey,
  });

  final String title;
  final String content;
  final Key? contentKey;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF9CA3AF),
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          key: contentKey,
          content,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Color(0xFF374151),
            height: 1.6,
          ),
        ),
      ],
    );
  }
}

class _AbstractSection extends StatelessWidget {
  const _AbstractSection({required this.publication});

  final Publication publication;

  @override
  Widget build(BuildContext context) {
    final abstractText = _textOrFallback(publication.abstractText);
    final hasAbstract = abstractText != 'N/A';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Abstract',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF9CA3AF),
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 16),
        if (hasAbstract)
          Text(
            abstractText,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Color(0xFF4B5563),
              height: 1.8,
            ),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFA),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFEEEEEE)),
            ),
            child: const Text(
              'No abstract available',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFFA0A0A0),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({required this.publication});

  final Publication publication;

  void _showCopyMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Information copied!'),
        duration: const Duration(milliseconds: 1500),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF111827),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.only(bottom: 20, left: 16, right: 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasDoi = _textOrFallback(publication.doi) != 'N/A';
    final originalUri = _originalPublicationUri(publication);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (originalUri != null) ...[
          _ModernButton(
            label: 'Open original publication',
            icon: Icons.open_in_new_rounded,
            isPrimary: true,
            onPressed: () async {
              var opened = false;
              try {
                opened = await launchUrl(
                  originalUri,
                  mode: LaunchMode.externalApplication,
                );
              } catch (_) {
                // Platform/plugin failures use the same friendly feedback.
              }
              if (!opened && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Could not open the link.')),
                );
              }
            },
          ),
          const SizedBox(height: 12),
        ],
        if (hasDoi) ...[
          _ModernButton(
            label: 'Copy publication identifier',
            icon: Icons.content_copy_rounded,
            isPrimary: originalUri == null,
            onPressed: () {
              final doi = _textOrFallback(publication.doi);
              Clipboard.setData(ClipboardData(text: doi));
              _showCopyMessage(context);
            },
          ),
          const SizedBox(height: 12),
        ],
        _ModernButton(
          label: 'Copy Citation',
          icon: Icons.content_copy_rounded,
          isPrimary: false,
          onPressed: () {
            final citation = _citationText(publication);
            Clipboard.setData(ClipboardData(text: citation));
            _showCopyMessage(context);
          },
        ),
      ],
    );
  }
}

class _ModernButton extends StatefulWidget {
  const _ModernButton({
    required this.label,
    required this.icon,
    required this.isPrimary,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool isPrimary;
  final VoidCallback onPressed;

  @override
  State<_ModernButton> createState() => _ModernButtonState();
}

class _ModernButtonState extends State<_ModernButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 52,
          decoration: BoxDecoration(
            color: widget.isPrimary
                ? (_isHovered
                      ? const Color(0xFF1E40AF)
                      : const Color(0xFF2B6DE9))
                : Colors.transparent,
            border: Border.all(
              color: widget.isPrimary
                  ? Colors.transparent
                  : const Color(0xFFDEE8F7),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                size: 18,
                color: widget.isPrimary
                    ? Colors.white
                    : const Color(0xFF2B6DE9),
              ),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: widget.isPrimary
                      ? Colors.white
                      : const Color(0xFF2B6DE9),
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _textOrFallback(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) return 'N/A';
  return trimmed;
}

String _authorsText(List<String> authors) {
  final validAuthors = authors
      .map((author) => author.trim())
      .where((author) => author.isNotEmpty)
      .toList();

  if (validAuthors.isEmpty) return 'N/A';
  return validAuthors.join(', ');
}

String _yearText(int year) {
  if (year <= 0) return 'N/A';
  return year.toString();
}

String _citationText(Publication publication) {
  final authors = publication.authors.isEmpty
      ? 'Unknown author'
      : publication.authors.join(', ');
  final year = _yearText(publication.publicationYear);
  final journal = _textOrFallback(publication.journalName);
  final doi = _textOrFallback(publication.doi);

  return '$authors ($year). ${_textOrFallback(publication.title)}. $journal. DOI: $doi';
}

Uri? _originalPublicationUri(Publication publication) {
  final doi = publication.doi?.trim();
  if (doi != null && doi.isNotEmpty) {
    final normalized = doi.startsWith('http')
        ? doi
        : 'https://doi.org/${doi.replaceFirst('doi:', '').trim()}';
    return Uri.tryParse(normalized);
  }

  final id = publication.id.trim();
  if (id.startsWith('http://') || id.startsWith('https://')) {
    return Uri.tryParse(id);
  }
  return null;
}
