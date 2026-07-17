import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Keep the Lab 02 app buildable before its Firebase Console file is added.
// Both plugins become active automatically once google-services.json exists.
if (file("google-services.json").exists()) {
    apply(plugin = "com.google.gms.google-services")
    apply(plugin = "com.google.firebase.crashlytics")
}

val releaseKeystoreProperties = Properties()
val releaseKeystorePropertiesFile = rootProject.file("key.properties")
if (releaseKeystorePropertiesFile.exists()) {
    releaseKeystorePropertiesFile.inputStream().use {
        releaseKeystoreProperties.load(it)
    }
}
val requiredReleaseSigningProperties =
    listOf("keyAlias", "keyPassword", "storeFile", "storePassword")
val hasReleaseSigningConfig =
    releaseKeystorePropertiesFile.exists() &&
        requiredReleaseSigningProperties.all {
            !releaseKeystoreProperties.getProperty(it).isNullOrBlank()
        }

android {
    namespace = "com.example.journal_trend_analysis"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.journal_trend_analysis"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    val releaseSigningConfig =
        if (hasReleaseSigningConfig) {
            signingConfigs.create("release") {
                keyAlias = releaseKeystoreProperties.getProperty("keyAlias")
                keyPassword = releaseKeystoreProperties.getProperty("keyPassword")
                storeFile = file(releaseKeystoreProperties.getProperty("storeFile"))
                storePassword = releaseKeystoreProperties.getProperty("storePassword")
            }
        } else {
            null
        }

    buildTypes {
        release {
            // A release without key.properties remains unsigned instead of
            // silently falling back to the public Android debug key.
            releaseSigningConfig?.let { signingConfig = it }
        }
    }
}

flutter {
    source = "../.."
}
