import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
}

// A2: release builds are signed with the upload key, never the debug key. The key comes from
// android/key.properties (storeFile relative to android/app, storePassword, keyAlias, keyPassword;
// git-ignored) or, in CI, the CL_ANDROID_KEYSTORE / _STORE_PASSWORD / _KEY_ALIAS / _KEY_PASSWORD
// environment variables. Play App Signing re-signs what reaches the store.
val keyProperties = Properties().apply {
    rootProject.file("key.properties").takeIf { it.exists() }?.inputStream()?.use(::load)
}
fun signingValue(key: String, env: String): String? =
    keyProperties.getProperty(key) ?: System.getenv(env)?.takeIf { it.isNotEmpty() }
val uploadKeystore = signingValue("storeFile", "CL_ANDROID_KEYSTORE")

android {
    namespace = "app.childlife.child_life"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // flutter_local_notifications schedules with java.time on older Android (S7 reminders).
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "app.childlife.child_life"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // Android 8.0 and later (implementation plan §6: minimum API 26).
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // dev and prod are separate Firebase projects with separate app ids (implementation plan §3.7).
    // Each flavor reads its own google-services.json from src/<flavor>/; prod has none until
    // child-life-ecosystem exists, so prod builds fail fast instead of silently using dev.
    flavorDimensions += "environment"
    productFlavors {
        create("dev") {
            dimension = "environment"
            applicationId = "app.childlife.dev"
            manifestPlaceholders["appName"] = "Child Life Dev"
        }
        create("prod") {
            dimension = "environment"
            applicationId = "app.childlife"
            manifestPlaceholders["appName"] = "Child Life"
        }
    }

    signingConfigs {
        if (uploadKeystore != null) {
            create("release") {
                storeFile = file(uploadKeystore)
                storePassword = signingValue("storePassword", "CL_ANDROID_STORE_PASSWORD")
                keyAlias = signingValue("keyAlias", "CL_ANDROID_KEY_ALIAS")
                keyPassword = signingValue("keyPassword", "CL_ANDROID_KEY_PASSWORD")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.findByName("release")
        }
    }
}

// Without the upload key a release build stops here instead of producing an unsigned or
// debug-signed app (debug and profile builds keep the debug key).
gradle.taskGraph.whenReady {
    val packagingRelease = allTasks.any { it.project == project && it.name.matches(Regex("(package|sign)\\w*Release\\w*")) }
    if (packagingRelease && uploadKeystore == null) {
        throw GradleException(
            "Release builds need the upload key: android/key.properties or CL_ANDROID_KEYSTORE (A2, docs/product/android-plan.md).",
        )
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

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    // 10j background uploads (A3): jobs that outlive the app, and their notification.
    implementation("androidx.work:work-runtime-ktx:2.10.1")
    implementation("androidx.core:core-ktx:1.15.0")
    // A6: PushService extends the firebase_messaging plugin's service; the BoM the plugins use.
    implementation(platform("com.google.firebase:firebase-bom:34.19.0"))
    implementation("com.google.firebase:firebase-messaging")
    // Native code gets ID tokens from the same Firebase Auth session (AuthToken).
    implementation("com.google.firebase:firebase-auth")
    testImplementation("junit:junit:4.13.2")
    // The real org.json in JVM tests (android.jar only has stubs).
    testImplementation("org.json:json:20240303")
}
