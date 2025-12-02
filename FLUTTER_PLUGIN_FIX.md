# Flutter Gradle Plugin Fix

## Problem Identified
```
Plugin with id 'dev.flutter.flutter-gradle-plugin' not found.
```

## Root Cause
The `dev.flutter.flutter-gradle-plugin` was being applied but not properly declared in the buildscript dependencies. This plugin doesn't exist in the standard Maven repositories - it's part of the Flutter SDK itself.

## Solution
Replace the problematic plugin apply with the standard Flutter integration pattern:

**Before:**
```gradle
apply plugin: 'com.android.application'
apply plugin: 'kotlin-android'
apply plugin: 'dev.flutter.flutter-gradle-plugin'
```

**After:**
```gradle
apply plugin: 'com.android.application'
apply plugin: 'kotlin-android'

def flutterRoot = localProperties.getProperty('flutter.sdk')
if (flutterRoot == null) {
    throw new GradleException("Flutter SDK not found. Define location with flutter.sdk in the local.properties file.")
}

apply from: "$flutterRoot/packages/flutter_tools/gradle/flutter.gradle"
```

## Why This Works
1. **Standard Pattern**: Uses the official Flutter integration method
2. **SDK-Based**: Loads Flutter plugin directly from Flutter SDK
3. **No Repository Issues**: Doesn't rely on external plugin repositories
4. **Better Compatibility**: Works with all Flutter versions

## Files Updated
- `android/app/build.gradle` - Replaced plugin apply with standard Flutter integration

This should resolve the "Flutter plugin not found" error and allow the build to proceed normally.