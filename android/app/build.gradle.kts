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

// Release signing (Option A, 2026-11-04). The keystore lives outside every
// repo (E:/dev/keys/jamaah-release.jks) and reaches the build through the
// untracked android/key.properties (gitignored, like keytool artifacts and
// *.jks). When key.properties is absent — CI, another machine — the build
// falls back to debug signing so `flutter run --release` keeps working; a
// release build signed with the debug key can only ever be handed out as a
// clearly-labelled test artifact, never as a release.
val releaseSigning = Properties().apply {
    val f = rootProject.file("key.properties")
    if (f.exists()) f.inputStream().use { load(it) }
}
val hasReleaseSigning = releaseSigning.getProperty("storeFile") != null

android {
    if (hasReleaseSigning) {
        signingConfigs {
            create("release") {
                // storeType before storeFile: PKCS12 keystores are read by
                // type, not by content sniff.
                storeType = releaseSigning.getProperty("storeType", "PKCS12")
                storeFile = file(releaseSigning.getProperty("storeFile"))
                storePassword = releaseSigning.getProperty("storePassword")
                keyAlias = releaseSigning.getProperty("keyAlias")
                keyPassword = releaseSigning.getProperty("keyPassword")
            }
        }
    }

    namespace = brandingApplicationId
    compileSdk = flutter.compileSdkVersion
    // MACHINE WORKAROUND — keep this uncommitted (it never belongs in history).
    // Pinned to the NDK that is actually installed on the development machine.
    // flutter.ndkVersion (28.2.13676358) resolves to a broken stub here, and
    // AGP's automatic download path needs a drive with free space. This app has
    // no native C++ code, so any recent NDK is acceptable.
    ndkVersion = "27.1.12297006"

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
            // Signed with the release key when key.properties is present; the
            // debug-key fallback keeps `flutter run --release` working on
            // machines without the keystore (see the signing comment above).
            signingConfig = if (hasReleaseSigning) signingConfigs.getByName("release")
                else signingConfigs.getByName("debug")
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
    // The app's own FileProvider (android/app/src/main/AndroidManifest.xml):
    // androidx.core is on the runtime classpath through plugins, and here
    // through this explicit dependency for the AndroidManifest-baked
    // class the in-app updater's installer hands the APK over with.
    implementation("androidx.core:core:1.16.0")
    testImplementation("junit:junit:4.13.2")
}

flutter {
    source = "../.."
}
