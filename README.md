# Environment Variable Export/Import Tools

Simple PowerShell scripts for securely exporting and importing environment variables between systems.

## Quick Start

### Export environment variables

```powershell
.\ExportEnvVars.ps1
```

This will:

1. Find all environment variables containing "SECRET", "API", "KEY", or "TOKEN"
2. Let you select which ones to export
3. Password-protect the exported variables
4. Save to `EnvVarExport.json` in your scripts directory

### Import environment variables

```powershell
# Preview what will be imported (dry run)
.\ImportEnvVars.ps1 -DryRun

# Actually import the variables
.\ImportEnvVars.ps1
```

### Validate exported file contents

```powershell
# Validate the default export file
.\ValidateFileContent.ps1

# Validate a specific file
.\ValidateFileContent.ps1 -FilePath "C:\path\to\your\file.json"
```

## Security Features

- All sensitive data is encrypted with SHA-256 password protection
- No plain text secrets are stored in the JSON file
- Memory is cleaned up after use with sensitive data

## Use Cases

- Transfer API keys and tokens between your machines
- Backup important environment variables
- Quickly set up a new development environment

## Requirements

- PowerShell 5.1 or newer
- Windows environment

## Customization

You can modify the search filters in ExportEnvVars.ps1 if you need to match different variable naming patterns.
