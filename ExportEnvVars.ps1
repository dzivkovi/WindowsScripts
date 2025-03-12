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

# Export selected variables to a secure file
# $exportPath = "$env:USERPROFILE\Documents\EnvVarExport.json"
$exportPath = "$env:USERPROFILE\Dropbox\SOFTWARE\Scripts\EnvVarExport.json"
$exportData = @{}

foreach ($var in $selected) {
    $exportData[$var.Name] = $var.Value
}

# Encrypt the data
$secureString = ConvertTo-SecureString -String (ConvertTo-Json $exportData -Depth 10) -AsPlainText -Force
$encryptedData = ConvertFrom-SecureString -SecureString $secureString

# Save to file
$encryptedData | Out-File $exportPath

Write-Host "`nExported selected environment variables to: $exportPath" -ForegroundColor Green
Write-Host "This file is encrypted and can only be imported by your Windows user account" -ForegroundColor Yellow
