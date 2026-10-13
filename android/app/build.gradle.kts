import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Branding comes from branding.yaml via tool/sync_branding.dart. The app label is
// a value in android/app/src/main/res/values/branding.xml (generated), so no
// resValue feature flag is needed.
val brandingProps = Properties().apply {
    val f = rootProject.file("app/branding.properties")
    if (f.exists()) f.inputStream().use { load(it) }
}
val brandingApplicationId = brandingProps.getProperty("applicationId", "dev.jamaah.app")

android {
    namespace = brandingApplicationId
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // flutter_local_notifications uses java.time APIs below API 26, which
        // requires core library desugaring. Keep this in sync with the
        // coreLibraryDesugaring dependency at the bottom of this file.
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = brandingApplicationId
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // The label itself lives in res/values/branding.xml, generated from
        // branding.yaml, and is referenced as @string/app_name by the manifest.
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    // Required by flutter_local_notifications for java.time on older Android.
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}

flutter {
    source = "../.."
}
