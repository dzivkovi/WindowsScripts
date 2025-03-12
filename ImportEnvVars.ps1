param(
    [switch]$DryRun = $true,
    [string]$ImportPath = "$env:USERPROFILE\Dropbox\SOFTWARE\Scripts\EnvVarExport.json"
)

# Check if import file exists
if (-not (Test-Path $ImportPath)) {
    Write-Host "Error: Could not find the import file at $ImportPath" -ForegroundColor Red
    Write-Host "Please run ExportEnvVars.ps1 first to create the export file." -ForegroundColor Yellow
    exit 1
}

# Prompt for the password used to encrypt the file
$passwordSecure = Read-Host "Enter password used when exporting environment variables" -AsSecureString

try {
    # Read the encrypted data
    $encryptedData = Get-Content $ImportPath
    
    # Generate the same key from the password that was used for encryption
    $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($passwordSecure)
    $passwordText = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
    [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
    
    # Create the same 32-byte (256-bit) key using SHA256
    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    $key = $sha256.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($passwordText))
    
    # Decrypt the data using the generated key
    $secureString = ConvertTo-SecureString -String $encryptedData -Key $key
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureString)
    $jsonString = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
    [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
    
    $importedVars = ConvertFrom-Json $jsonString

    Write-Host "Found these variables to import:" -ForegroundColor Cyan
    $importedVars.PSObject.Properties | ForEach-Object { Write-Host $_.Name }
    
    $choice = Read-Host "`nImport as (U)ser or (S)ystem variables? [U/S]"
    $target = if ($choice -eq "S") { "Machine" } else { "User" }
    
    Write-Host "`nImporting environment variables as $target variables..." -ForegroundColor Yellow
    
    # Check if using dry-run mode (from parameter or default value)
    $showOnly = $DryRun
    
    if (-not $showOnly) {
        # Import the variables
        $importedVars.PSObject.Properties | ForEach-Object {
            [Environment]::SetEnvironmentVariable($_.Name, $_.Value, $target)
            Write-Host "Imported: $($_.Name)" -ForegroundColor Green
        }
        
        Write-Host "`nEnvironment variables imported successfully!" -ForegroundColor Green
        Write-Host "Note: You may need to restart applications to use the new variables." -ForegroundColor Yellow
    } else {
        Write-Host "`nDRY RUN - would import these variables:" -ForegroundColor Yellow
        $importedVars.PSObject.Properties | ForEach-Object {
            # Show first few characters of value for verification
            $maskedValue = if ($_.Value.Length -gt 8) { $_.Value.Substring(0, 4) + "..." } else { "..." }
            Write-Host "$($_.Name) = $maskedValue" -ForegroundColor Gray
        }
        
        Write-Host "`nDRY RUN COMPLETE - No changes were made" -ForegroundColor Green
        Write-Host "To actually import variables, run without -DryRun switch:" -ForegroundColor Yellow
        Write-Host ".\ImportEnvVars.ps1" -ForegroundColor Yellow
    }
}
catch {
    Write-Host "`nError importing environment variables: $($_.Exception.Message)" -ForegroundColor Red
}
finally {
    # Clean up sensitive variables
    if ($passwordText) { $passwordText = $null }
    if ($key) { $key = $null }
    if ($jsonString) { $jsonString = $null }
    [System.GC]::Collect()
}