import 'package:flutter/material.dart';

import '../models/publication.dart';
import '../screens/publication_detail_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const String publicationDetailName = '/publication-detail';

  static Route<void> publicationDetail(Publication publication) {
    return MaterialPageRoute<void>(
      settings: RouteSettings(
        name: publicationDetailName,
        arguments: publication.id,
      ),
      builder: (_) => PublicationDetailScreen(publication: publication),
    );
  }
}
