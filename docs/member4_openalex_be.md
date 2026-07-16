# Member 4 BE - OpenAlex API Integration

## Files added or updated

- `lib/models/publication.dart`
- `lib/models/openalex_search_state.dart`
- `lib/services/openalex_service.dart`
- `lib/repositories/openalex_repository.dart`
- `android/app/src/main/AndroidManifest.xml`
- `pubspec.yaml`
- `test/openalex_service_test.dart`

## What was implemented

### Models

`Publication` is still the shared model used by Analytics and Dashboard. It now has:

```dart
factory Publication.fromOpenAlexJson(Map<String, dynamic> json)
```

This parser maps OpenAlex work JSON into app data:

- `id`
- `title`
- `publicationYear`
- `citationCount`
- `journalName`
- `authors`
- `doi`
- `abstractText`

`OpenAlexSearchState` was added for UI loading/error handling:

- `idle`
- `loading`
- `success`
- `failure`

### Service

`OpenAlexService` calls the OpenAlex Works API:

```dart
final service = OpenAlexService();
final publications = await service.searchTopic('artificial intelligence');
final detail = await service.getPublicationDetail('W123456789');
```

Responsibilities:

- Build OpenAlex `/works` search URL.
- Build OpenAlex `/works/{id}` detail URL.
- Send HTTP GET request.
- Parse JSON response.
- Convert `results` into `List<Publication>`.
- Convert one work detail response into `Publication`.
- Reconstruct abstract text from OpenAlex inverted index when available.
- Throw `OpenAlexException` for invalid keyword, network timeout, bad HTTP status, and invalid JSON.

Android release builds can call the API because `INTERNET` permission was added to the main Android manifest.

### Repository

`OpenAlexRepository` wraps `OpenAlexService` and exposes a `ValueNotifier` state for FE:

```dart
final repository = OpenAlexRepository();

repository.state.addListener(() {
  final state = repository.state.value;
  print(state.status);
});

final publications = await repository.searchTopic('machine learning');
final detail = await repository.getPublicationDetail(publications.first.id);
```

Responsibilities:

- Set state to `loading` before API call.
- Set state to `success` with publications after API success.
- Set state to `failure` with error message when API fails.
- Return an empty list instead of crashing the UI on error.

## FE usage example

```dart
final repository = OpenAlexRepository();

ValueListenableBuilder(
  valueListenable: repository.state,
  builder: (context, state, child) {
    if (state.isLoading) {
      return const CircularProgressIndicator();
    }

    if (state.hasError) {
      return Text(state.errorMessage ?? 'Unknown error');
    }

    return ListView(
      children: state.publications
          .map((publication) => Text(publication.title))
          .toList(),
    );
  },
);
```

## Notes for integration with analytics

The returned `List<Publication>` can be passed directly into `AnalyticsService`:

```dart
final publications = await repository.searchTopic('data science');
final dashboard = const AnalyticsService().generateDashboardData(publications);
final trend = const AnalyticsService().getPublicationTrendByYear(publications);
```

## Tests

`test/openalex_service_test.dart` covers:

- Successful OpenAlex JSON parsing.
- Successful OpenAlex detail parsing.
- Server error handling.
- Empty keyword validation.
- Empty publication id validation.
