# PowerShell script to fix localization imports

# Get all Dart files that contain the old import
$files = Get-ChildItem -Path "lib" -Recurse -Filter "*.dart" | Where-Object {
    $content = Get-Content $_.FullName -Raw
    $content -match "package:flutter_gen/gen_l10n/app_localizations\.dart"
}

Write-Host "Found $($files.Count) files to update"

foreach ($file in $files) {
    Write-Host "Processing: $($file.FullName)"
    
    # Read the file content
    $content = Get-Content $file.FullName -Raw
    
    # Replace the import based on the file location
    $relativePath = Resolve-Path $file.FullName -Relative
    $depth = ($relativePath -split "\\").Count - 2  # Subtract 2 for "lib\" and filename
    
    # Calculate the correct relative path
    $pathToRoot = "../" * $depth
    $newImport = $pathToRoot + "l10n/app_localizations.dart"
    
    # Replace the import
    $updatedContent = $content -replace "import 'package:flutter_gen/gen_l10n/app_localizations\.dart';", "import '$newImport';"
    
    # Write back to file
    Set-Content -Path $file.FullName -Value $updatedContent -NoNewline
    
    Write-Host "Updated: $($file.Name) with path: $newImport"
}

Write-Host "All imports updated successfully!"
