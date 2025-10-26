// App-level Gradle file: <project>/app/build.gradle.kts

import java.util.Properties
import java.io.FileInputStream

// -----------------------------------------------------------------
// 1. PLUGINS BLOCK (السطر 5)
// -----------------------------------------------------------------
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

// -----------------------------------------------------------------
// 2. ANDROID BLOCK
// -----------------------------------------------------------------
android {
    namespace = "com.mahlna.syn"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    // تحميل خصائص keystore
    val keystoreProperties = Properties()
    val keystorePropertiesFile = rootProject.file("key.properties")
    if (keystorePropertiesFile.exists()) {
        keystoreProperties.load(FileInputStream(keystorePropertiesFile))
    }

    signingConfigs {
        create("release") {
            storeFile = file(keystoreProperties["storeFile"] ?: "my-release-key.jks")
            storePassword = keystoreProperties["storePassword"] as String?
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
        }
    }

    compileOptions {
        // Java 17/Desugaring
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.mahlna.syn"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = 12
        versionName = "1.1.9"
        
        // MultiDex
        multiDexEnabled = true 
    }

    buildTypes {
        getByName("release") {
            isMinifyEnabled = false 
            isShrinkResources = false 
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

// -----------------------------------------------------------------
// 3. FLUTTER BLOCK
// -----------------------------------------------------------------
flutter {
    source = "../.."
}

// -----------------------------------------------------------------
// 4. DEPENDENCIES BLOCK (حل جميع المشاكل السابقة هنا)
// -----------------------------------------------------------------
dependencies {
    // Desugaring
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.0")
    
    // Firebase BoM
    implementation(platform("com.google.firebase:firebase-bom:24.0.0"))
    
    // Firebase Packages
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-messaging-ktx")
    
    // Kotlin StdLib FIX
    implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk8")
}