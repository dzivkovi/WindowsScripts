# Path to the exported environment variables
$importPath = "$env:USERPROFILE\Dropbox\SOFTWARE\Scripts\EnvVarExport.json"

if (Test-Path $importPath) {
    # Prompt for the password used to encrypt the file
    $passwordSecure = Read-Host "Enter password used when exporting environment variables" -AsSecureString
    
    try {
        # Read the encrypted data
        $encryptedData = Get-Content $importPath
        
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
        
        # Import the variables
        $importedVars.PSObject.Properties | ForEach-Object {
            [Environment]::SetEnvironmentVariable($_.Name, $_.Value, $target)
            Write-Host "Imported: $($_.Name)" -ForegroundColor Green
        }
        
        Write-Host "`nEnvironment variables imported successfully!" -ForegroundColor Green
        Write-Host "Note: You may need to restart applications to use the new variables." -ForegroundColor Yellow
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
} else {
    Write-Host "Error: Could not find the import file at $importPath" -ForegroundColor Red
}