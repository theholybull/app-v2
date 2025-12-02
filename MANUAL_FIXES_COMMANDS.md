# Manual Fixes to Apply (If git pull doesn't work)

Since the fixes aren't syncing, apply these manual edits to your local files:

## Fix 1: Sensor Provider - Remove "final var"

**File:** `lib/providers/sensor_provider.dart`  
**Line 130:** Find and replace this line:

```dart
// CHANGE THIS:
final var bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

// TO THIS:
final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
```

## Fix 2: Sensor Provider - Fix Connectivity API

**File:** `lib/providers/sensor_provider.dart`  
**Line 164-166:** Find and replace these lines:

```dart
// CHANGE THIS:
_connectivityStatus = await connectivity.checkConnectivity();

// TO THIS:
final results = await connectivity.checkConnectivity();
_connectivityStatus = results.isNotEmpty ? [results.first] : [];
```

## Fix 3: Sensor Provider - Comment Barometer

**File:** `lib/providers/sensor_provider.dart`  
**Around line 245:** Find and replace this line:

```dart
// CHANGE THIS:
_barometerSubscription?.cancel();

// TO THIS:
// Barometer not available: _barometerSubscription?.cancel();
```

## Fix 4: Audio Controls - Volume Types

**File:** `lib/widgets/audio_controls.dart`  
**Line 200:** Find and replace:

```dart
// CHANGE THIS:
value: volume,

// TO THIS:
value: volume.toDouble(),
```

**Line 203:** Find and replace:

```dart
// CHANGE THIS:
volume = value;

// TO THIS:
volume = value.round();
```

## PowerShell Commands to Apply Fixes

Copy and paste these commands in PowerShell:

```powershell
# Fix 1: Remove final var
(Get-Content "lib\providers\sensor_provider.dart") -replace 'final var bool', 'final bool' | Set-Content "lib\providers\sensor_provider.dart"

# Fix 2: Connectivity API (this one is more complex, may need manual edit)
# Open lib\providers\sensor_provider.dart and manually replace line 166 as shown above

# Fix 3: Comment barometer
(Get-Content "lib\providers\sensor_provider.dart") -replace '_barometerSubscription\?\.cancel\(\);', '// Barometer not available: _barometerSubscription?.cancel();' | Set-Content "lib\providers\sensor_provider.dart"

# Fix 4: Audio volume types
(Get-Content "lib\widgets\audio_controls.dart") -replace 'value: volume,', 'value: volume.toDouble(),' | Set-Content "lib\widgets\audio_controls.dart"
(Get-Content "lib\widgets\audio_controls.dart") -replace 'volume = value;', 'volume = value.round();' | Set-Content "lib\widgets\audio_controls.dart"
```

## Quick Test

After applying fixes, run:
```bash
flutter build apk
```

All compilation errors should be resolved.