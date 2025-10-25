// App-level Gradle file: <project>/app/build.gradle.kts

import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin") // Flutter plugin
    
    // تطبيق المكون الإضافي لخدمات Google هنا (بدون تحديد الإصدار)
    id("com.google.gms.google-services")
}

android {
    namespace = "com.mahlna.syn"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    // تحميل خصائص keystore من key.properties
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
        // ***** التعديل الحاسم: الرفع إلى Java 17 *****
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
        
        // ***** التعديل الضروري: تفعيل MultiDex *****
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

flutter {
    source = "../.."
}

dependencies {
    // يجب أن تكون Desugaring متوافقة مع JDK 17
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.0") // 2.1.0 كافية لـ 17
    
    // ***** اعتماديات Firebase *****
    // 1. استيراد قائمة مكونات Firebase (BoM)
    implementation(platform("com.google.firebase:firebase-bom:34.4.0"))
    
    // 2. إضافة منتجات Firebase المطلوبة
    implementation("com.google.firebase:firebase-analytics")
    
    // ***** إضافة اعتمادية Firebase Messaging *****
    implementation("com.google.firebase:firebase-messaging-ktx")
}