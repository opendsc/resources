# OpenDsc.Windows/Shortcut Resource

A DSC v3 resource for managing Windows shortcuts (.lnk files) using native COM
interop through P/Invoke.

## Features

- Create, read, update, and delete Windows shortcuts
- Set target path, arguments, working directory, description
- Configure icon location, hotkeys, and window styles
- Uses COM interop via P/Invoke for AOT-friendly code structure
- Fully supports DSC v3 with JSON schema validation

## Implementation Details

This resource uses the Windows Shell Link COM interface (`IShellLinkW`) through
properly-defined P/Invoke declarations instead of dynamic COM interop. While the
code structure is AOT-compatible (using source generators for JSON
serialization, proper COM interface definitions), **full Native AOT compilation
is not supported** due to limitations with COM class instantiation in NativeAOT.
The resource works perfectly in standard .NET runtime with JIT compilation.

## Schema

### Properties

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `path` | string | Yes | Full path to the shortcut file (.lnk). |
| `targetPath` | string | No | Full path to the target executable or file. |
| `arguments` | string | No | Command-line arguments to pass to the target. |
| `workingDirectory` | string | No | Working directory for the target. |
| `description` | string | No | Description/comment for the shortcut. |
| `iconLocation` | string | No | Icon path and index (format: "path,index"). |
| `hotkey` | string | No | Hotkey combination (format: "MODIFIER+KEY", e.g., "CTRL+ALT+F"). |
| `windowStyle` | enum | No | Window state when launched. Valid values: `Normal`, `Minimized`, `Maximized`. |
| `_exist` | boolean | No | Whether the shortcut should exist. Default: `true`. |

## Examples

### Create a basic shortcut

```powershell
dsc resource set -r OpenDsc.Windows/Shortcut -i @'
path: C:\Users\Public\Desktop\Notepad.lnk
targetPath: C:\Windows\System32\notepad.exe
description: Text Editor
'@
```

### Create a shortcut with arguments and custom settings

```powershell
dsc resource set -r OpenDsc.Windows/Shortcut -i @'
path: C:\Users\Public\Desktop\Command Prompt.lnk
targetPath: C:\Windows\System32\cmd.exe
arguments: /k echo Hello
workingDirectory: C:\Users\Public
windowStyle: Normal
iconLocation: C:\Windows\System32\cmd.exe,0
'@
```

### Get shortcut properties

```powershell
dsc resource get -r OpenDsc.Windows/Shortcut -i @'
path: C:\Users\Public\Desktop\Notepad.lnk
'@
```

### Delete a shortcut

```powershell
dsc resource delete -r OpenDsc.Windows/Shortcut -i @'
path: C:\Users\Public\Desktop\Notepad.lnk
'@
```

## Building

```powershell
.\build.ps1
```

Or manually:

```powershell
dotnet publish src\OpenDsc.Resource.Windows.Shortcut.csproj -c Release
```
