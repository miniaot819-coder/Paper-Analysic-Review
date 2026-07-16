import 'package:flutter_test/flutter_test.dart';
import 'package:journal_trend_analysis/firebase/remote_config_service.dart';
import 'package:journal_trend_analysis/models/publication.dart';
import 'package:journal_trend_analysis/viewmodels/dashboard_view_model.dart';

void main() {
  test('derives dashboard analytics and most influential work', () {
    final viewModel = DashboardViewModel(
      remoteConfig: _FakeRemoteConfig(maxJournals: 1),
    );
    final publications = [
      const Publication(
        id: '1',
        title: 'First',
        publicationYear: 2023,
        citationCount: 2,
        journalName: 'Journal A',
        authors: ['Author A'],
      ),
      const Publication(
        id: '2',
        title: 'Most cited',
        publicationYear: 2024,
        citationCount: 20,
        journalName: 'Journal B',
        authors: ['Author B'],
      ),
    ];

    final presentation = viewModel.presentationFor(publications);

    expect(presentation.dashboard.totalPublications, 2);
    expect(presentation.dashboard.topAuthor, isNotEmpty);
    expect(presentation.topJournals, hasLength(1));
    expect(presentation.mostInfluentialPublication?.title, 'Most cited');
  });

  test('reuses presentation for the same publication list and config', () {
    final viewModel = DashboardViewModel(
      remoteConfig: _FakeRemoteConfig(maxJournals: 5),
    );
    final publications = <Publication>[];

    expect(
      identical(
        viewModel.presentationFor(publications),
        viewModel.presentationFor(publications),
      ),
      isTrue,
    );
  });
}

class _FakeRemoteConfig implements RemoteConfigGateway {
  _FakeRemoteConfig({required this.maxJournals});

  @override
  final int maxJournals;

  @override
  int get maxKeywords => 10;

  @override
  Future<bool> refreshForDemo() async => false;
}
