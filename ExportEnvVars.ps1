# List all environment variables with API or KEY in the name (or customize the filter)
$apiVars = Get-ChildItem Env: | Where-Object { 
    $_.Name -like "*API*" -or 
    $_.Name -like "*KEY*" -or 
    $_.Name -like "*TOKEN*" -or 
    $_.Name -like "*SECRET*" 
} | Sort-Object Name

# Show all filtered variables
Write-Host "Found these API/key related environment variables:" -ForegroundColor Cyan
$apiVars | ForEach-Object { Write-Host "$($_.Name)" }

# Create selection menu
$selected = @()
Write-Host "`nSelect which variables to export (enter numbers separated by commas, 'all' for all, or 'done' to finish):" -ForegroundColor Green

$i = 1
$indexMap = @{}
$apiVars | ForEach-Object {
    Write-Host "[$i] $($_.Name)"
    $indexMap[$i] = $_
    $i++
}

$selection = Read-Host "`nSelection"

if ($selection -eq "all") {
    $selected = $apiVars
} else {
    $indices = $selection -split "," | ForEach-Object { $_.Trim() }
    foreach ($idx in $indices) {
        if ($indexMap.ContainsKey([int]$idx)) {
            $selected += $indexMap[[int]$idx]
        }
    }
}

# Export selected variables with password protection
# $exportPath = "$env:USERPROFILE\Documents\EnvVarExport.json"
$exportPath = "$env:USERPROFILE\Dropbox\SOFTWARE\Scripts\EnvVarExport.json"

# Prompt for a password
$passwordSecure = Read-Host "Enter a password to protect your environment variables" -AsSecureString
$exportData = @{}

foreach ($var in $selected) {
    $exportData[$var.Name] = $var.Value
}

# Convert to JSON
$jsonString = ConvertTo-Json $exportData -Depth 10
$secureJsonString = ConvertTo-SecureString $jsonString -AsPlainText -Force

try {
    # Generate a 256-bit key from the password
    $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($passwordSecure)
    $passwordText = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
    [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
    
    # Create a 32-byte (256-bit) key using SHA256
    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    $key = $sha256.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($passwordText))
    
    # Convert the key to a byte array of the proper length
    $encryptedData = ConvertFrom-SecureString -SecureString $secureJsonString -Key $key
    
    # Save to file
    $encryptedData | Out-File $exportPath
    
    Write-Host "`nExported selected environment variables to: $exportPath" -ForegroundColor Green
    Write-Host "You'll need to enter the same password when importing these variables" -ForegroundColor Yellow
}
catch {
    Write-Host "`nError encrypting environment variables: $($_.Exception.Message)" -ForegroundColor Red
}
finally {
    # Clean up sensitive variables
    if ($passwordText) { $passwordText = $null }
    if ($key) { $key = $null }
    [System.GC]::Collect()
}