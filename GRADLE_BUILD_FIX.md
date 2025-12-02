# Gradle Build Fix for Viam Pixel 4a Flutter App

## Problem Identified
The build was failing with:
```
Plugin [id: 'com.android.application'] was not found in any of the following sources:
- Gradle Core Plugins (plugin is not in 'org.gradle' namespace)
- Plugin Repositories (plugin dependency must include a version number for this source)
```

## Root Cause
The `android/build.gradle` file was missing the `buildscript` block that declares the Android Gradle Plugin dependencies. Modern Gradle requires explicit plugin declaration when using declarative syntax.

## Solution Applied

### 1. Updated android/build.gradle
Added the missing buildscript block with proper plugin versions:

```gradle
buildscript {
    ext.kotlin_version = '1.7.10'
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath 'com.android.tools.build:gradle:8.1.0'
        classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version"
    }
}

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

### 2. Updated android/app/build.gradle
Changed from declarative to imperative plugin syntax:

**Before:**
```gradle
plugins {
    id "com.android.application"
    id "kotlin-android"
    id "dev.flutter.flutter-gradle-plugin"
}
```

**After:**
```gradle
apply plugin: 'com.android.application'
apply plugin: 'kotlin-android'
apply plugin: 'dev.flutter.flutter-gradle-plugin'
```

## Why This Works
1. **buildscript block**: Explicitly declares the Android Gradle Plugin and its version
2. **Proper repositories**: Ensures plugins can be found in Google Maven and Maven Central
3. **Compatible versions**: Uses AGP 8.1.0 with Gradle 8.3 (compatible combination)
4. **Imperative syntax**: More stable for Flutter projects using this configuration

## Next Steps
1. The user should now run `flutter build apk` again
2. The build should succeed without the plugin resolution error
3. If there are any remaining issues, we'll address them step by step

## Files Modified
- `android/build.gradle` - Added buildscript block
- `android/app/build.gradle` - Changed to imperative plugin syntax

These changes are compatible with Flutter 3.35.7 and should resolve the build issue.