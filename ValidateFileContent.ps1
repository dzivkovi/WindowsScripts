# Command to view the encrypted JSON file content
$encryptedContent = Get-Content -Path "$env:USERPROFILE\Dropbox\SOFTWARE\Scripts\EnvVarExport.json"
Write-Host "Encrypted file content (first 50 characters): $($encryptedContent.Substring(0, [Math]::Min(50, $encryptedContent.Length)))..."

# To decrypt and validate the content:
$password = Read-Host "Enter the same password used for encryption" -AsSecureString
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
$jsonObject = ConvertFrom-Json $decryptedJson
$jsonObject | ConvertTo-Json -Depth 10

# Clean up sensitive data
$passwordText = $null
$key = $null
[System.GC]::Collect()