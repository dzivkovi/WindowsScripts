# Path to the exported environment variables
# $importPath = "$env:USERPROFILE\Documents\EnvVarExport.json"
$importPath = "$env:USERPROFILE\Dropbox\SOFTWARE\Scripts\EnvVarExport.json"

if (Test-Path $importPath) {
    # Read the encrypted data
    $encryptedData = Get-Content $importPath
    $secureString = ConvertTo-SecureString -String $encryptedData
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureString)
    $jsonString = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
    $importedVars = ConvertFrom-Json $jsonString

    Write-Host "Found these variables to import:" -ForegroundColor Cyan
    $importedVars.PSObject.Properties | ForEach-Object { Write-Host $_.Name }
    
    $choice = Read-Host "`nImport as (U)ser or (S)ystem variables? [U/S]"
    $target = if ($choice -eq "S") { "Machine" } else { "User" }
    
    Write-Host "`nImporting environment variables as $target variables..." -ForegroundColor Yellow
    
    # Import the variables
    $importedVars.PSObject.Properties | ForEach-Object {
        [Environment]::SetEnvironmentVariable($_.Name, $_.Value, $target)
        Write-Host "Imported: $($_.Name)" -ForegroundColor Green
    }
    
    Write-Host "`nEnvironment variables imported successfully!" -ForegroundColor Green
    Write-Host "Note: You may need to restart applications to use the new variables." -ForegroundColor Yellow
} else {
    Write-Host "Error: Could not find the import file at $importPath" -ForegroundColor Red
}
