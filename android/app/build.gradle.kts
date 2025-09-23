import java.io.FileInputStream
import java.util.Properties

// Load the key.properties file from the project's root directory.
// 'val' is used for variable declaration in Kotlin, replacing 'def'.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()

// Check if the properties file exists before trying to read it.
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use {
        keystoreProperties.load(it)
    }
} else {
    println("Keystore properties file not found.")
}
plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "dev.adatech.ecoacai" // AQUI foi alterado
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
        // AQUI foi alterado para o novo Application ID
        applicationId = "dev.adatech.ecoacai"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }
    signingConfigs {
        create("release") {
            // Check for the existence of the properties before assigning them
            storeFile = keystoreProperties["storeFile"]?.let { file(it as String) } ?: throw Exception("storeFile not found in key.properties")
            storePassword = keystoreProperties["storePassword"] as String
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
        }
    }

    buildTypes {
       getByName("release") {
            // ... other release configurations
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}
