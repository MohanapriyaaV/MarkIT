plugins {
    id("com.android.application")
    id("kotlin-android")
    // Flutter plugin
    id("dev.flutter.flutter-gradle-plugin")
    // Apply Google services plugin WITHOUT version here
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.myapp"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.myapp"
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    // Firebase BoM to manage Firebase dependencies versions
    implementation(platform("com.google.firebase:firebase-bom:33.14.0"))

    // Firebase Analytics (example Firebase product)
    implementation("com.google.firebase:firebase-analytics")
    // Add other Firebase dependencies as needed
}

flutter {
    source = "../.."
}

// IMPORTANT: REMOVE this line if present, because it's redundant and can cause conflicts:
// apply(plugin = "com.google.gms.google-services")
