import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

// Load signing credentials from key.properties
val keyPropertiesFile = rootProject.file("key.properties")
val keyProperties = Properties()
if (keyPropertiesFile.exists()) {
    keyProperties.load(FileInputStream(keyPropertiesFile))
}

android {
    namespace = "com.airz.scanairz"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }

    signingConfigs {
        create("release") {
            keyAlias      = keyProperties.getProperty("keyAlias")     ?: "scanairz"
            keyPassword   = keyProperties.getProperty("keyPassword")  ?: ""
            storeFile     = file(keyProperties.getProperty("storeFile") ?: "scanairz-release.jks")
            storePassword = keyProperties.getProperty("storePassword") ?: ""
        }
    }

    defaultConfig {
        applicationId = "com.airz.scanairz"
        minSdk = flutter.minSdkVersion          // Android 5+ covers BT & USB host APIs
        targetSdk     = flutter.targetSdkVersion
        versionCode   = flutter.versionCode
        versionName   = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = if (keyPropertiesFile.exists())
                signingConfigs.getByName("release")
            else
                signingConfigs.getByName("debug")
            isMinifyEnabled     = false
            isShrinkResources   = false
        }
        debug {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
