# Quick PowerShell script to fix compilation errors
# Run this script in PowerShell as Administrator in your project directory

Write-Host "Applying compilation fixes..." -ForegroundColor Green

# Fix 1: Remove "final var" from sensor provider
Write-Host "Fixing final var issue..." -ForegroundColor Yellow
(Get-Content "lib\providers\sensor_provider.dart") -replace 'final var bool', 'final bool' | Set-Content "lib\providers\sensor_provider.dart"

# Fix 2: Comment out barometer subscription
Write-Host "Fixing barometer subscription..." -ForegroundColor Yellow
(Get-Content "lib\providers\sensor_provider.dart") -replace '_barometerSubscription\?\.cancel\(\);', '// Barometer not available: _barometerSubscription?.cancel();' | Set-Content "lib\providers\sensor_provider.dart"

# Fix 3: Fix connectivity API (manual step required)
Write-Host " MANUAL STEP REQUIRED: Open lib\providers\sensor_provider.dart" -ForegroundColor Red
Write-Host "Find line 166: _connectivityStatus = await connectivity.checkConnectivity();" -ForegroundColor Red
Write-Host "Replace with:" -ForegroundColor Red
Write-Host "final results = await connectivity.checkConnectivity();" -ForegroundColor Red
Write-Host "_connectivityStatus = results.isNotEmpty ? [results.first] := [];" -ForegroundColor Red

# Fix 4: Audio controls volume types
Write-Host "Fixing audio controls volume types..." -ForegroundColor Yellow
(Get-Content "lib\widgets\audio_controls.dart") -replace 'value: volume,', 'value: volume.toDouble(),' | Set-Content "lib\widgets\audio_controls.dart"
(Get-Content "lib\widgets\audio_controls.dart") -replace 'volume = value;', 'volume = value.round();' | Set-Content "lib\widgets\audio_controls.dart"

Write-Host "Fixes applied! Now run: flutter build apk" -ForegroundColor Green
Write-Host "Press any key to continue..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")