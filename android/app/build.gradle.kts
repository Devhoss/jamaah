import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Branding comes from branding.yaml via tool/sync_branding.dart (committed output).
// Fallbacks keep a fresh clone building before the tool is ever run.
val brandingProps = Properties().apply {
    val f = rootProject.file("app/branding.properties")
    if (f.exists()) f.inputStream().use { load(it) }
}
val brandingAppName = brandingProps.getProperty("appName", "Awqaity")
val brandingApplicationId = brandingProps.getProperty("applicationId", "dev.awqaity.app")

android {
    namespace = brandingApplicationId
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = brandingApplicationId
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        resValue("string", "app_name", brandingAppName)
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

flutter {
    source = "../.."
}
