# Firebase setup for Lab 03

The Android application id remains:

```text
com.example.journal_trend_analysis
```

## Firebase Console

1. Create or open a Firebase project and enable Google Analytics.
2. Register an Android app using the application id above.
3. Download `google-services.json` and place it at
   `android/app/google-services.json`.
4. Enable the Google provider under Authentication > Sign-in method.
5. Create the default Cloud Storage bucket.
6. Create and publish these Remote Config parameters:
   - `max_journals_displayed`: number, default `10`
   - `max_keywords_displayed`: number, default `10`
7. Use an Android emulator image that includes Google Play when testing FCM.

The Android Gradle plugins are applied only when `google-services.json` exists,
so the Lab 02 application remains buildable before the Firebase project file is
added.

## Optional CLI deployment

After installing and signing in to the Firebase CLI, deploy the Storage rules:

```powershell
firebase deploy --only storage
```

Never add a Firebase Admin service-account key or an FCM server credential to
the mobile application repository.
