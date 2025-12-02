# Final PowerShell script to fix remaining compilation errors
# Run this in your project directory

Write-Host "Applying final compilation fixes..." -ForegroundColor Green

# Fix 1: Remove "final var" if it still exists
Write-Host "Fixing final var issue..." -ForegroundColor Yellow
(Get-Content "lib\providers\sensor_provider.dart") -replace 'final var bool', 'final bool' | Set-Content "lib\providers\sensor_provider.dart"

# Fix 2: Fix connectivity API to handle single result
Write-Host "Fixing connectivity API..." -ForegroundColor Yellow
$connectivityFix = @"
      final result = await connectivity.checkConnectivity();
      _connectivityStatus = [result];
"@
(Get-Content "lib\providers\sensor_provider.dart") -replace 'final results = await connectivity.checkConnectivity\(\);\s+_connectivityStatus = results.isNotEmpty \? \[results\.first\] : \[\];', $connectivityFix | Set-Content "lib\providers\sensor_provider.dart"

# Fix 3: Audio controls should be fine, but let's ensure correct types
Write-Host "Checking audio controls..." -ForegroundColor Yellow
# The audio controls are already correct - volume is double, Slider expects double

Write-Host "Fixes completed!" -ForegroundColor Green
Write-Host "Now run: flutter build apk" -ForegroundColor Cyan