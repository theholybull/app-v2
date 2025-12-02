# Android SDK 36 and USB Serial Plugin Fix

## Problems Identified

### 1. Android SDK Version Warnings
```
The plugin camera_android requires Android SDK version 36 or higher.
The plugin flutter_plugin_android_lifecycle requires Android SDK version 36 or higher.
The plugin geolocator_android requires Android SDK version 36 or higher.
The plugin path_provider_android requires Android SDK version 36 or higher.
The plugin record_android requires Android SDK version 36 or higher.
```

### 2. USB Serial Plugin Namespace Error
```
Could not create an instance of type com.android.build.api.variant.impl.LibraryVariantBuilderImpl.
Namespace not specified. Specify a namespace in the module's build file: usb_serial-0.4.0/android/build.gradle.
```

## Root Causes
1. **Outdated Android SDK**: Using SDK 34 when plugins require SDK 36
2. **Outdated USB Serial Plugin**: Version 0.4.0 doesn't include namespace for modern AGP

## Solutions Applied

### 1. Updated Android SDK Version
**File**: `android/app/build.gradle`

**Before:**
```gradle
android {
    namespace "com.example.viam_pixel4a_sensors"
    compileSdk 34
    ndkVersion flutter.ndkVersion
    // ...
    defaultConfig {
        // ...
        targetSdkVersion 34
        // ...
    }
}
```

**After:**
```gradle
android {
    namespace "com.example.viam_pixel4a_sensors"
    compileSdk 36
    ndkVersion flutter.ndkVersion
    // ...
    defaultConfig {
        // ...
        targetSdkVersion 36
        // ...
    }
}
```

### 2. Updated USB Serial Plugin Version
**File**: `pubspec.yaml`

**Before:**
```yaml
usb_serial: ^0.4.0
```

**After:**
```yaml
usb_serial: ^0.5.2
```

## Benefits
1. **Plugin Compatibility**: All plugins now meet their SDK requirements
2. **Namespace Support**: USB Serial 0.5.2 includes proper namespace for AGP 8.7.0
3. **Modern Android Support**: Using latest Android SDK 36 features
4. **Future-Proof**: Compatible with latest Android development requirements

## Files Updated
- `android/app/build.gradle` - Updated compileSdk and targetSdk to 36
- `pubspec.yaml` - Updated usb_serial to ^0.5.2

## Next Steps
User should run:
```bash
flutter pub get
flutter build apk
```

This should resolve both the SDK warnings and the USB Serial namespace error.