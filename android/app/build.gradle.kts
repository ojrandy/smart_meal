import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing comes only from android/key.properties, which is
// gitignored and points at a keystore kept outside the repo
// (docs/RELEASE.md). There is deliberately no fallback to the debug key.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties().apply {
    if (keystorePropertiesFile.exists()) {
        keystorePropertiesFile.inputStream().use { load(it) }
    }
}
val requiredSigningKeys = listOf("storeFile", "storePassword", "keyAlias", "keyPassword")

android {
    namespace = "com.ojtech.smartmeal"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.ojtech.smartmeal"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (requiredSigningKeys.all { !keystoreProperties.getProperty(it).isNullOrBlank() }) {
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

// Fail a release build up front, with instructions, instead of producing an
// unsigned or debug-signed artifact. Debug builds are unaffected.
tasks.configureEach {
    if (name == "preReleaseBuild") {
        doFirst {
            val missing = requiredSigningKeys.filter {
                keystoreProperties.getProperty(it).isNullOrBlank()
            }
            val storePath = keystoreProperties.getProperty("storeFile")
            val problem = when {
                !keystorePropertiesFile.exists() ->
                    "android/key.properties not found."
                missing.isNotEmpty() ->
                    "android/key.properties is missing: ${missing.joinToString()}."
                !file(storePath).exists() ->
                    "Keystore not found at storeFile=$storePath."
                else -> null
            }
            if (problem != null) {
                throw GradleException(
                    "Release signing is not configured: $problem\n" +
                        "Release builds never fall back to the debug key. Create " +
                        "android/key.properties (gitignored) pointing at the upload " +
                        "keystore kept outside the repo; see docs/RELEASE.md → Signing.",
                )
            }
        }
    }
}

flutter {
    source = "../.."
}
