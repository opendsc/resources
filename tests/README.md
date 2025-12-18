# DSC Resource Tests

This directory contains integration tests for all DSC resources across
platforms.

## Test Organization

Tests are organized by resource name (not by platform), with each test file
handling platform detection automatically:

- **Windows-only resources**: Group, User, Service, Environment, Shortcut,
  OptionalFeature, FileSystemAcl
- **Cross-platform resources**: File, Directory, XmlElement

## Running Tests

### All Tests

```powershell
.\build.ps1 -InstallDsc
```

### Specific Test

```powershell
Invoke-Pester .\tests\Group.Tests.ps1
```

### Platform-Specific

Tests automatically detect the platform and:

- Windows: Tests Windows and cross-platform resources using
  `OpenDsc.Resource.Windows.exe`
- Linux: Tests only cross-platform resources using `OpenDsc.Resource.Linux`

Windows-only tests are skipped on Linux automatically.

## Test Structure

Each test file follows this pattern:

```powershell
Describe 'ResourceName Resource' {
    BeforeAll {
        # Platform detection
        if ($IsWindows) {
            $configuration = $env:BUILD_CONFIGURATION ?? 'Release'
            $publishPath = Join-Path $PSScriptRoot "..\src\OpenDsc.Resource.Windows\bin\$configuration\net9.0-windows\win-x64\publish"
        } else {
            $configuration = $env:BUILD_CONFIGURATION ?? 'Release'
            $publishPath = Join-Path $PSScriptRoot "..\src\OpenDsc.Resource.Linux\bin\$configuration\net9.0\linux-x64\publish"
        }
    }

    Context 'Discovery' { }
    Context 'Get Operation' { }
    Context 'Set Operation' -Skip:(!$isAdmin) { }  # If admin required
    Context 'Delete Operation' -Skip:(!$isAdmin) { }
}
```

## Admin-Required Tests

Some tests require administrative privileges (e.g., creating users, managing
services). These contexts use `-Skip:(!$isAdmin)` to skip gracefully when not
elevated.

## Environment Variables

- `BUILD_CONFIGURATION`: Set to `Debug` or `Release` (defaults to `Release`)
