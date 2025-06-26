plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin") // Flutter plugin
    id("com.google.gms.google-services")    // Firebase services
}

android {
    namespace = "com.example.myapp"
    compileSdk = 34  // Make sure compileSdk is 30+ (for MANAGE_EXTERNAL_STORAGE support)
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    defaultConfig {
        applicationId = "com.example.myapp"
        minSdk = 23                    // Minimum required for MANAGE_EXTERNAL_STORAGE
        targetSdk = 30                 // ✅ Use targetSdk = 30 for full file access
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // ✅ Required for file access from scoped storage in Android 11+
        manifestPlaceholders += mapOf(
            "requestLegacyExternalStorage" to "true"
        )
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    // Firebase BoM
    implementation(platform("com.google.firebase:firebase-bom:33.14.0"))

    // Example Firebase service
    implementation("com.google.firebase:firebase-analytics")
}

flutter {
    source = "../.."
}

// ✅ Do NOT include: apply(plugin = "com.google.gms.google-services")
