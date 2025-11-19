# OpenDsc.Windows/Service Resource

Manage Windows services using DSC v3.

## Capabilities

- **Get**: Retrieve current state of a Windows service
- **Set**: Create or configure a Windows service (requires elevation)
- **Delete**: Remove a Windows service (requires elevation)
- **Export**: List all Windows services on the system

## Requirements

- Windows operating system
- DSC v3 (Desired State Configuration)
- **Administrator privileges required** for Set and Delete operations

## Installation

Build and publish the resource:

```powershell
.\build.ps1
```

Ensure the published executable is in your PATH or DSC can discover the resource
manifest.

## Schema

### Properties

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `name` | string | Yes | The name of the service. Case insensitive. Cannot contain forward slash (/) or backslash (\\) characters. Max 256 characters. |
| `displayName` | string | No | The display name of the service. Max 256 characters. |
| `description` | string | No | The description of the service. |
| `path` | string | No* | The fully qualified path to the service binary file. If the path contains a space, it must be quoted. The path can also include arguments. Required for creating new services. |
| `dependencies` | string[] | No | Array of service names that this service depends on. |
| `status` | enum | No | The desired status of the service. Valid values: `Stopped`, `Running`, `Paused`. |
| `startType` | enum | No* | The start type of the service. Valid values: `Automatic`, `Manual`, `Disabled`. Required for creating new services. |
| `_exist` | boolean | No | Indicates whether the service exists. Default: `true`. |

*Required when creating a new service.

### Status Values

- `Stopped` - Service is not running
- `Running` - Service is running
- `Paused` - Service is paused

### StartType Values

- `Automatic` - Service starts automatically at system boot
- `Manual` - Service must be started manually
- `Disabled` - Service cannot be started

## Examples

### Get Service State

Retrieve information about the Windows Update service:

```powershell
@'
name: wuauserv
'@ | dsc resource get -r OpenDsc.Windows/Service
```

Output:

```yaml
actualState:
  name: wuauserv
  displayName: Windows Update
  description: Enables the detection, download, and installation of updates for Windows and other programs.
  path: C:\Windows\system32\svchost.exe -k netsvcs -p
  status: Stopped
  startType: Manual
  _exist: true
```

### Create a New Service

Create a new service with basic configuration:

```powershell
@'
name: MyCustomService
displayName: My Custom Service
description: A custom service for my application
path: C:\MyApp\service.exe
startType: Automatic
'@ | dsc resource set -r OpenDsc.Windows/Service
```

**Note**: Requires administrator privileges

### Create Service with Arguments

Create a service with command-line arguments:

```powershell
@'
name: MyService
path: 'C:\Program Files\MyApp\service.exe --config "C:\configs\app.json"'
startType: Manual
'@ | dsc resource set -r OpenDsc.Windows/Service
```

### Configure Service Dependencies

Create a service that depends on other services:

```powershell
@'
name: MyService
path: C:\MyApp\service.exe
startType: Automatic
dependencies:
  - Tcpip
  - Dnscache
'@ | dsc resource set -r OpenDsc.Windows/Service
```

### Update Existing Service

Modify an existing service's configuration:

```powershell
@'
name: MyService
displayName: Updated Display Name
description: Updated description
startType: Manual
'@ | dsc resource set -r OpenDsc.Windows/Service
```

### Start a Service

Set a service to running state:

```powershell
@'
name: MyService
status: Running
'@ | dsc resource set -r OpenDsc.Windows/Service
```

### Stop a Service

Set a service to stopped state:

```powershell
@'
name: MyService
status: Stopped
'@ | dsc resource set -r OpenDsc.Windows/Service
```

### Configure Service Start Type

Change a service to start automatically:

```powershell
@'
name: wuauserv
startType: Automatic
'@ | dsc resource set -r OpenDsc.Windows/Service
```

Disable a service:

```powershell
@'
name: MyService
startType: Disabled
'@ | dsc resource set -r OpenDsc.Windows/Service
```

### Delete a Service

Remove a service from the system:

```powershell
@'
name: MyService
'@ | dsc resource delete -r OpenDsc.Windows/Service
```

**Note**: Requires administrator privileges. Service will be stopped if running
before deletion.

### Export All Services

Export the configuration of all services on the system:

```powershell
dsc resource export -r OpenDsc.Windows/Service
```

This returns a YAML document with the current state of every service installed
on the system.

### Using in DSC Configuration

Include in a DSC configuration document:

```yaml
# dsc.config.yaml
$schema: https://raw.githubusercontent.com/PowerShell/DSC/main/schemas/2024/04/config/document.json
resources:
  - name: CustomAppService
    type: OpenDsc.Windows/Service
    properties:
      name: MyCustomService
      displayName: My Custom Application Service
      description: Service for my custom application
      path: C:\MyApp\service.exe
      startType: Automatic
      status: Running
```

Apply the configuration:

```powershell
dsc config set --path dsc.config.yaml
```

## Common Scenarios

### Check if Service Exists

```powershell
$result = @'
name: MyService
'@ | dsc resource get -r OpenDsc.Windows/Service | ConvertFrom-Json

if ($result.actualState._exist -eq $false) {
    Write-Host "Service does not exist"
}
```

### Ensure Service is Running

```powershell
@'
name: MyService
status: Running
'@ | dsc resource set -r OpenDsc.Windows/Service
```

### Create and Start Service in One Operation

```powershell
@'
name: MyService
path: C:\MyApp\service.exe
startType: Automatic
status: Running
'@ | dsc resource set -r OpenDsc.Windows/Service
```

## Testing

Run the Pester tests:

```powershell
cd tests
Invoke-Pester
```

**Note**: Many tests require administrator privileges to create and manage test
services. Tests that require elevation are automatically skipped when run
without admin rights.

## Version

See [CHANGELOG.md](CHANGELOG.md) for version history and changes.
