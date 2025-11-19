# OpenDsc.Windows/Environment Resource

Manage Windows environment variables using DSC v3.

## Capabilities

- **Get**: Retrieve current value of a Windows environment variable
- **Set**: Create or update a Windows environment variable
- **Delete**: Remove a Windows environment variable
- **Export**: List all Windows environment variables (user and machine scope)

## Requirements

- Windows operating system
- DSC v3 (Desired State Configuration)
- **Administrator privileges required** for machine-scoped environment variables

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
| `name` | string | Yes | The name of the environment variable. Cannot contain equals sign (=) or null characters. Max 254 characters. |
| `value` | string | No | The value of the environment variable. |
| `_exist` | boolean | No | Indicates whether the environment variable exists. Default: `true`. Set to `false` to delete. |
| `_scope` | enum | No | The scope of the environment variable. Valid values: `User`, `Machine`. Default: `User`. |

### Scope Values

- `User` - Environment variable is set for the current user only (default)
- `Machine` - Environment variable is set system-wide for all users (requires
  administrator privileges)

## Examples

### Get Environment Variable

Retrieve the value of a user environment variable:

```powershell
@'
name: MY_VAR
'@ | dsc resource get -r OpenDsc.Windows/Environment
```

Output:

```yaml
actualState:
  name: MY_VAR
  value: SomeValue
  _exist: true
```

### Get Non-Existent Variable

Query a variable that doesn't exist:

```powershell
@'
name: NON_EXISTENT_VAR
'@ | dsc resource get -r OpenDsc.Windows/Environment
```

Output:

```yaml
actualState:
  name: NON_EXISTENT_VAR
  value: null
  _exist: false
```

### Create User Environment Variable

Create a new environment variable in user scope:

```powershell
@'
name: MY_APP_HOME
value: C:\Users\MyUser\MyApp
'@ | dsc resource set -r OpenDsc.Windows/Environment
```

### Create Machine Environment Variable

Create a system-wide environment variable (requires administrator):

```powershell
@'
name: COMPANY_LICENSE_SERVER
value: license.example.com
_scope: Machine
'@ | dsc resource set -r OpenDsc.Windows/Environment
```

**Note**: Requires administrator privileges

### Update Existing Variable

Update the value of an existing environment variable:

```powershell
@'
name: MY_APP_HOME
value: D:\Applications\MyApp
'@ | dsc resource set -r OpenDsc.Windows/Environment
```

### Set PATH Variable

Update or append to the PATH environment variable:

```powershell
@'
name: PATH
value: C:\MyTools;C:\Python311;%PATH%
'@ | dsc resource set -r OpenDsc.Windows/Environment
```

**Note**: Be careful when modifying PATH. Consider reading the current value
first and appending to it.

### Delete Environment Variable

Remove an environment variable:

```powershell
@'
name: MY_APP_HOME
_exist: false
'@ | dsc resource delete -r OpenDsc.Windows/Environment
```

### Delete Machine Variable

Remove a machine-scoped environment variable:

```powershell
@'
name: COMPANY_LICENSE_SERVER
_exist: false
_scope: Machine
'@ | dsc resource delete -r OpenDsc.Windows/Environment
```

**Note**: Requires administrator privileges

### Export All Variables

List all environment variables (both user and machine scope):

```powershell
dsc resource export -r OpenDsc.Windows/Environment
```

Output (excerpt):

```yaml
resources:
  - type: OpenDsc.Windows/Environment
    properties:
      name: PATH
      value: C:\Windows\system32;C:\Windows;...
      _scope: Machine
  - type: OpenDsc.Windows/Environment
    properties:
      name: TEMP
      value: C:\Users\MyUser\AppData\Local\Temp
  - type: OpenDsc.Windows/Environment
    properties:
      name: USERNAME
      value: MyUser
```

## Usage in Configuration

Use the resource in a DSC configuration document:

```yaml
$schema: https://raw.githubusercontent.com/PowerShell/DSC/main/schemas/2024/04/config/document.json
resources:
  - name: Set Application Home
    type: OpenDsc.Windows/Environment
    properties:
      name: MY_APP_HOME
      value: C:\Applications\MyApp

  - name: Set Log Directory
    type: OpenDsc.Windows/Environment
    properties:
      name: MY_APP_LOGS
      value: C:\Logs\MyApp

  - name: Remove Old Variable
    type: OpenDsc.Windows/Environment
    properties:
      name: DEPRECATED_VAR
      _exist: false
```
