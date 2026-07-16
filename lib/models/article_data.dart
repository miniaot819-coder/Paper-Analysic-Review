import 'package:flutter/material.dart';

class ArticleData {
  const ArticleData({
    required this.title,
    required this.journalName,
    required this.publicationTime,
    required this.citationCount,
    required this.logoColor,
  });

  final String title;
  final String journalName;
  final String publicationTime;
  final String citationCount;
  final Color logoColor;
}
