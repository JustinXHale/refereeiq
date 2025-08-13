plugins {
    id("com.android.application")
    id("com.google.gms.google-services") // Firebase
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

import java.util.Properties
        import java.io.FileInputStream

// Load signing props from android/key.properties
val keystoreProps = Properties()
val keystorePropsFile = rootProject.file("key.properties")
if (keystorePropsFile.exists()) {
    FileInputStream(keystorePropsFile).use { keystoreProps.load(it) }
}

android {
    namespace = "com.refereeiq.refereeiq"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.refereeiq.refereeiq"
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // --- Release signing using key.properties ---
    signingConfigs {
        create("release") {
            keyAlias = (keystoreProps["keyAlias"] ?: "") as String
            keyPassword = (keystoreProps["keyPassword"] ?: "") as String
            val storePath = (keystoreProps["storeFile"] ?: "") as String
            if (storePath.isNotEmpty()) {
                storeFile = file(storePath)
            }
            storePassword = (keystoreProps["storePassword"] ?: "") as String
        }
    }

    buildTypes {
        getByName("release") {
            // Use the real release keystore (NOT debug)
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
        }
        // debug stays default
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}
