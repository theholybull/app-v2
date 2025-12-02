# Simple 3-Step Fix (Copy-Paste Solution)

You have 3 compilation errors to fix. Here are the exact changes:

## Error 1: "final var bool" 
**File:** `lib/providers/sensor_provider.dart`  
**Line 130:** Find this line and remove `var`:

```dart
// FIND THIS LINE:
final var bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

// REPLACE WITH:
final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
```

## Error 2 & 3: Audio Volume Types
**File:** `lib/widgets/audio_controls.dart`

### Line 200 - Slider value:
```dart
// FIND THIS LINE:
value: volume,

// REPLACE WITH:
value: volume.toDouble(),
```

### Line 203 - Volume assignment:
```dart
// FIND THIS LINE:
volume = value;

// REPLACE WITH:
volume = value.round();
```

---

## Quick PowerShell Commands (Copy-Paste)

Open PowerShell in your project directory and run:

```powershell
# Fix 1: Remove "final var"
(Get-Content "lib\providers\sensor_provider.dart") -replace 'final var bool', 'final bool' | Set-Content "lib\providers\sensor_provider.dart"

# Fix 2: Audio volume slider value
(Get-Content "lib\widgets\audio_controls.dart") -replace 'value: volume,', 'value: volume.toDouble(),' | Set-Content "lib\widgets\audio_controls.dart"

# Fix 3: Audio volume assignment
(Get-Content "lib\widgets\audio_controls.dart") -replace 'volume = value;', 'volume = value.round();' | Set-Content "lib\widgets\audio_controls.dart"
```

## Then Build:

```bash
flutter build apk
```

That's it! These 3 small changes will fix all compilation errors.