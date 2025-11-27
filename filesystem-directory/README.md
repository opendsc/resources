# OpenDsc.FileSystem/Directory Resource

Manage directories using DSC v3.

## Capabilities

- **Get**: Retrieve current state of a directory
- **Set**: Create directory and parents recursively if needed
- **Delete**: Remove a directory if it exists

## Requirements

- Operating system supported by .NET 9.0 (Windows, Linux, macOS)
- DSC v3 (Desired State Configuration)

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
| `path` | string | Yes | The path to the directory. |
| `_exist` | boolean | No | Indicates whether the directory should exist. Default: `true`. Set to `false` to delete. |

## Examples

### Get Directory State

Check if a directory exists:

```powershell
dsc resource get -r OpenDsc.FileSystem/Directory --input 'path: C:\temp\dir'
```

### Create Directory

Create a new directory (parent directories are created recursively if needed):

```powershell
dsc resource set -r OpenDsc.FileSystem/Directory --input 'path: C:\temp\parent\child\dir'
```

### Delete Directory

Remove an existing directory:

```powershell
dsc resource delete -r OpenDsc.FileSystem/Directory --input 'path: C:\temp\dir'
```

### Ensure Directory Does Not Exist

Ensure a directory is absent:

```powershell
dsc resource set -r OpenDsc.FileSystem/Directory --input '
path: C:\temp\dir
_exist: false
'
```
