// ملف Gradle على مستوى الجذر: <project>/build.gradle.kts

// هذا الجزء مهم لتعريف المكونات الإضافية التي تستخدمها جميع الوحدات النمطية
plugins {
    // 1. المكون الإضافي لـ Android Gradle Plugin (AGP) - يجب تحديثه
    id("com.android.application") version "8.4.1" apply false
    id("com.android.library") version "8.4.1" apply false
    
    // 2. المكون الإضافي لـ Kotlin - يجب تحديثه
    id("org.jetbrains.kotlin.android") version "1.9.22" apply false
    
    // 3. المكون الإضافي لخدمات Google (Firebase)
    id("com.google.gms.google-services") version "4.4.2" apply false // يفضل استخدام 4.4.2 أو الأحدث (4.4.4 جيد)
}

// -----------------------------------------------------------

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// كتل إدارة دليل البناء (Build Directory Management)
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

// التبعية بين الوحدات النمطية (Subproject Dependency)
subprojects {
    project.evaluationDependsOn(":app")
}

// دالة التنظيف
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}