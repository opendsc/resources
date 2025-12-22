# DSC Resource Tests

Integration tests for all OpenDsc resources using Pester and the DSC CLI.

## Quick Start

Run all tests:

```powershell
.\build.ps1
```

Run tests for a specific area:

```powershell
Invoke-Pester .\tests\Windows\
Invoke-Pester .\tests\FileSystem\
```

Run specific tests using tags:

```powershell
# Run all Windows package tests
Invoke-Pester -Tag Windows

# Run only non-admin tests
Invoke-Pester -ExcludeTag Admin

# Run only discovery tests (fast, no system changes)
Invoke-Pester -Tag Discovery

# Run only read operations
Invoke-Pester -Tag Get

# Run cross-platform tests only
Invoke-Pester -Tag Linux
```

## Prerequisites

- **DSC CLI** - Install automatically with `.\build.ps1 -InstallDsc`
- **Admin privileges** - Required for some tests (User, Group, Service,
  OptionalFeature)
- **Windows** - Platform-specific tests automatically skip on non-Windows

## Test Organization

Tests are organized by area/platform:

- `Windows/` - Windows-specific resources (Group, User, Service, etc.)
- `FileSystem/` - Cross-platform file/directory resources
- `Xml/` - Cross-platform XML manipulation resources

## Test Tags

All tests are tagged to enable flexible filtering:

**OS Tags** (on Describe):

- `Windows` - Windows-specific or cross-platform resources in Windows package
- `Linux`, `macOS` - Cross-platform resources (File, Directory, Xml)

**Permission Tags** (on Context):

- `Admin` - Requires administrative privileges

**Operation Tags** (on Context):

- `Discovery` - Resource discovery tests
- `Get` - Read current state
- `Set` - Apply desired state
- `Delete` - Remove resources
- `Export` - Export all instances
- `Schema` - Schema validation

## Contributing Tests

Tests are integration tests that verify resources work correctly through the
DSC CLI. See `.github/copilot-instructions.md` for test patterns and
conventions.
