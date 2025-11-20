# OpenDsc.Windows/Feature Resource

Manages Windows optional features using the native DISM (Deployment Image
Servicing and Management) API.

## Key Features

- **Native C# implementation** - Uses DISM API via P/Invoke, no PowerShell
  dependencies
- **Fast and lightweight** - Direct Windows API calls without COM overhead
- **Full DSC v3 support** - Get, Set, Delete, and Export operations
- **AOT-compatible** - Structured for ahead-of-time compilation

## Capabilities

- **Get**: Query the state of a Windows feature
- **Set**: Enable or disable a Windows feature
- **Delete**: Disable a Windows feature
- **Export**: List all installed Windows features

## Requirements

- Windows operating system (Desktop or Server)
- DSC v3 (Desired State Configuration)
- **Administrator privileges required** for all DISM operations

## Schema

### Properties

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `name` | string | Yes | The name of the Windows feature (e.g., `TelnetClient`, `IIS-WebServer`) |
| `_exist` | boolean | No | Indicates whether the feature should be installed. Default: `true` |
| `includeAllSubFeatures` | boolean | No | Include all sub-features when enabling or disabling the feature |
| `source` | string[] | No | Source paths for feature files. If not specified, uses Windows default sources |
| `state` | string | No | *Read-only*. Current state of the feature: `NotPresent`, `UninstallPending`, `Staged`, `Removed`, `Installed`, `InstallPending`, `Superseded`, `PartiallyInstalled` |
| `displayName` | string | No | *Read-only*. Display name of the feature |
| `description` | string | No | *Read-only*. Description of the feature |
| `_metadata` | object | No | *Read-only*. Operation metadata including restart requirements |

## Examples

### Get Feature State

Query if Telnet Client is installed:

```powershell
@'
name: TelnetClient
'@ | dsc resource get -r OpenDsc.Windows/Feature
```

Output:

```yaml
actualState:
  name: TelnetClient
  _exist: false
  state: NotPresent
  displayName: Telnet Client
  description: Enables a TCP/IP Telnet client
```

### Enable a Feature

Enable the Telnet Client feature:

```powershell
@'
name: TelnetClient
'@ | dsc resource set -r OpenDsc.Windows/Feature
```

**Note**: Requires administrator privileges

### Enable Feature with All Sub-features

Enable IIS with all sub-features:

```powershell
@'
name: IIS-WebServer
includeAllSubFeatures: true
'@ | dsc resource set -r OpenDsc.Windows/Feature
```

### Disable a Feature

Disable Telnet Client:

```powershell
@'
name: TelnetClient
_exist: false
'@ | dsc resource set -r OpenDsc.Windows/Feature
```

Or using delete:

```powershell
@'
name: TelnetClient
'@ | dsc resource delete -r OpenDsc.Windows/Feature
```

### Export All Installed Features

List all currently installed features:

```powershell
dsc resource export -r OpenDsc.Windows/Feature
```

Output (excerpt):

```yaml
resources:
  - type: OpenDsc.Windows/Feature
    properties:
      name: NetFx4-AdvSrvs
      _exist: true
      state: Installed
      displayName: Microsoft .NET Framework 4.8 Advanced Services
  - type: OpenDsc.Windows/Feature
    properties:
      name: Printing-Foundation-Features
      _exist: true
      state: Installed
      displayName: Windows Print Foundation Features
```

## Common Feature Names

### Windows Client Features

- `TelnetClient` - Telnet Client
- `TFTP` - TFTP Client
- `SMB1Protocol` - SMB 1.0/CIFS File Sharing Support
- `Microsoft-Windows-Subsystem-Linux` - Windows Subsystem for Linux
- `VirtualMachinePlatform` - Virtual Machine Platform
- `Microsoft-Hyper-V-All` - Hyper-V

### Windows Server Features (Examples)

- `IIS-WebServer` - Web Server (IIS)
- `DNS-Server-Full-Role` - DNS Server
- `DHCP` - DHCP Server
- `AD-Domain-Services` - Active Directory Domain Services
- `FS-FileServer` - File Server

Use `dism /online /get-features` to list all available features.

## Usage in Configuration

Use the resource in a DSC configuration:

```yaml
$schema: https://raw.githubusercontent.com/PowerShell/DSC/main/schemas/2024/04/config/document.json
resources:
  - name: Enable Telnet
    type: OpenDsc.Windows/Feature
    properties:
      name: TelnetClient
      _exist: true

  - name: Enable IIS Web Server
    type: OpenDsc.Windows/Feature
    properties:
      name: IIS-WebServer
      _exist: true
      includeAllSubFeatures: true

  - name: Remove SMB1
    type: OpenDsc.Windows/Feature
    properties:
      name: SMB1Protocol
      _exist: false
```

## Testing

Run the Pester tests:

```powershell
.\build.ps1
```

**Important**: All tests require administrator privileges because DISM
operations require elevation.

## Troubleshooting

### "Failed to initialize DISM API: 0x800702E4"

This error means administrator privileges are required. Run your terminal as
administrator.

### "Feature not found"

Verify the feature name is correct. Use `dism /online /get-features` to list all
available features. Feature names are case-sensitive.

### Restart Required

Some features require a system restart after installation or removal. When a
feature operation requires or might require a restart, the resource will return
`_metadata._restartRequired` in the result. This metadata includes the system
name that needs to be restarted.

Example:

```json
{
  "name": "TelnetClient",
  "state": "Installed",
  "displayName": "Telnet Client",
  "_metadata": {
    "_restartRequired": [
      { "system": "COMPUTER-NAME" }
    ]
  }
}
```
