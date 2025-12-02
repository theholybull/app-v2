# Declarative Flutter Gradle Plugin Migration

## Problem Identified
```
You are applying Flutter's main Gradle plugin imperatively using the apply script method, which is not possible anymore. Migrate to applying Gradle plugins with the declarative plugins block
```

## Root Cause
Flutter 3.35.7 requires using the **declarative plugins block** instead of the imperative `apply from` method. This is a breaking change in Flutter's Gradle integration.

## Solution Applied

### 1. Updated android/app/build.gradle
**Before (Imperative):**
```gradle
apply plugin: 'com.android.application'
apply plugin: 'kotlin-android'

def localProperties = new Properties()
def localPropertiesFile = rootProject.file('local.properties')
if (localPropertiesFile.exists()) {
    localPropertiesFile.withReader('UTF-8') { reader ->
        localProperties.load(reader)
    }
}

def flutterRoot = localProperties.getProperty('flutter.sdk')
if (flutterRoot == null) {
    throw new GradleException("Flutter SDK not found. Define location with flutter.sdk in the local.properties file.")
}

apply from: "$flutterRoot/packages/flutter_tools/gradle/flutter.gradle"
```

**After (Declarative):**
```gradle
plugins {
    id "com.android.application"
    id "kotlin-android"
    id "dev.flutter.flutter-gradle-plugin"
}

def localProperties = new Properties()
def localPropertiesFile = rootProject.file('local.properties')
if (localPropertiesFile.exists()) {
    localPropertiesFile.withReader('UTF-8') { reader ->
        localProperties.load(reader)
    }
}

def flutterRoot = localProperties.getProperty('flutter.sdk')
if (flutterRoot == null) {
    throw new GradleException("Flutter SDK not found. Define location with flutter.sdk in the local.properties file.")
}
```

### 2. Updated android/settings.gradle
Added the plugins block with proper version management:

```gradle
pluginManagement {
    def flutterSdkPath = {
        def properties = new Properties()
        file("local.properties").withInputStream { properties.load(it) }
        def flutterSdkPath = properties.getProperty("flutter.sdk")
        assert flutterSdkPath != null, "flutter.sdk not set in local.properties"
        return flutterSdkPath
    }()

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id "dev.flutter.flutter-plugin-loader" version "1.0.0"
    id "com.android.application" version "8.2.2" apply false
    id "org.jetbrains.kotlin.android" version "1.9.22" apply false
}

include ":app"
```

### 3. Updated android/build.gradle
Removed the buildscript block since plugins are now managed declaratively:

```gradle
// Declarative plugins are now managed in settings.gradle

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.buildDir = '../build'
subprojects {
    project.buildDir = "${rootProject.buildDir}/${project.name}"
}
subprojects {
    project.evaluationDependsOn(':app')
}

tasks.register("clean", Delete) {
    delete rootProject.buildDir
}
```

## Why This Works
1. **Modern Syntax**: Uses Flutter 3.35.7's required declarative plugin approach
2. **Version Management**: Centralized plugin version management in settings.gradle
3. **Better Performance**: Declarative plugins resolve faster and more reliably
4. **Future-Proof**: Follows Flutter's modern Gradle integration best practices

## Migration Benefits
- **Faster Builds**: Declarative plugins have better caching and parallel processing
- **Better IDE Support**: Improved Gradle synchronization in Android Studio
- **Consistency**: Aligns with modern Android development practices
- **Maintenance**: Easier to manage plugin versions centrally

## Files Updated
- `android/app/build.gradle` - Migrated to declarative plugins block
- `android/settings.gradle` - Added centralized plugin management
- `android/build.gradle` - Removed buildscript dependencies

This migration resolves the Flutter 3.35.7 compatibility issue and enables successful builds.