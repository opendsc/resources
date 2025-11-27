# OpenDsc.FileSystem/Directory Resource

Manage directories using DSC v3, with support for seeding from a source.
When `sourcePath` is specified, directory contents are compared using SHA256
hashes to ensure all source files are present and match in the target.
Extra files in the target are ignored.

## Capabilities

- **Get**: Retrieve current state of a directory
- **Set**: Create directory; optionally copy contents from source
- **Test**: Check if directory matches desired state
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
| `sourcePath` | string | No | Path to source directory to copy contents from. Contents are compared using SHA256 hashes. |
| `_exist` | boolean | No | Indicates whether the directory should exist. Default: `true`. |
| `_inDesiredState` | boolean | No | Read-only: Whether the directory is in desired state. |

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

### Create Directory with Source Contents

Create a directory and copy all files/subdirectories from a source:

```powershell
dsc resource set -r OpenDsc.FileSystem/Directory --input '
path: C:\temp\target
sourcePath: C:\temp\source
'
```

### Test Directory Compliance

Check if directory matches desired state (all source files present and matching
via SHA256 hashes; extra files ignored):

```powershell
dsc resource test -r OpenDsc.FileSystem/Directory --input '
path: C:\temp\target
sourcePath: C:\temp\source
'
```
