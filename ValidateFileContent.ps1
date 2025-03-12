param(
    [string]$FilePath = "$env:USERPROFILE\Dropbox\SOFTWARE\Scripts\EnvVarExport.json"
)

# Check if file exists
if (-not (Test-Path $FilePath)) {
    Write-Host "Error: Could not find the encrypted file at $FilePath" -ForegroundColor Red
    Write-Host "Please run ExportEnvVars.ps1 first to create the export file." -ForegroundColor Yellow
    exit 1
}

# Command to view the encrypted JSON file content
$encryptedContent = Get-Content -Path $FilePath
Write-Host "Encrypted file content (first 50 characters): $($encryptedContent.Substring(0, [Math]::Min(50, $encryptedContent.Length)))..." -ForegroundColor Cyan

# Prompt for the password used to encrypt the file
$password = Read-Host "Enter the same password used for encryption" -AsSecureString

try {
    $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password)
    $passwordText = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
    [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)

    # Generate the same key from the password
    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    $key = $sha256.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($passwordText))

    # Decrypt the content
    $secureString = ConvertTo-SecureString -String $encryptedContent -Key $key
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureString)
    $decryptedJson = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
    [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)

    # Display the decrypted JSON in a readable format
    Write-Host "`nDecrypted Content: " -ForegroundColor Green
    $jsonObject = ConvertFrom-Json $decryptedJson
    
    Write-Host "`nFound these environment variables:" -ForegroundColor Cyan
    $jsonObject.PSObject.Properties | ForEach-Object { 
        # Show first few characters of value for verification
        $maskedValue = if ($_.Value.Length -gt 8) { $_.Value.Substring(0, 4) + "..." } else { "..." }
        Write-Host "$($_.Name) = $maskedValue"
    }
    
    Write-Host "`nValidation successful. The file can be safely imported." -ForegroundColor Green
}
catch {
    Write-Host "`nError decrypting file: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Please check if you used the correct password." -ForegroundColor Yellow
}
finally {
    # Clean up sensitive data
    if ($passwordText) { $passwordText = $null }
    if ($key) { $key = $null }
    if ($decryptedJson) { $decryptedJson = $null }
    [System.GC]::Collect()
}