# OpenDSC Resources

A collection of Microsoft DSC (Desired State Configuration) resources for
managing Windows and cross-platform systems.

## Overview

This repository provides production-ready DSC resources built using .NET 9.0
and the `OpenDsc.Resource.CommandLine` library. Each resource is implemented as
a standalone executable that integrates seamlessly with Microsoft DSC.

## Available Resources

### Windows Resources

- **[OpenDsc.Windows/Environment][env-readme]** -
  Manage Windows environment variables
- **[OpenDsc.Windows/Group][group-readme]** -
  Manage local Windows groups and membership
- **[OpenDsc.Windows/Service][service-readme]** -
  Manage Windows services
- **[OpenDsc.Windows/User][user-readme]** -
  Manage local Windows user accounts
- **[OpenDsc.Windows/Shortcut][shortcut-readme]** -
  Manage Windows shortcuts (.lnk files)
- **[OpenDsc.Windows/OptionalFeature][optionalfeature-readme]** -
  Manage Windows optional features via DISM
- **[OpenDsc.Windows.FileSystem/AccessControlList][acl-readme]** -
  Manage file and directory permissions (ACLs)

### Cross-Platform Resources

- **[OpenDsc.FileSystem/File][file-readme]** -
  Manage files (Windows, Linux, macOS)
- **[OpenDsc.FileSystem/Directory][directory-readme]** -
  Manage directories with hash-based synchronization
- **[OpenDsc.Xml/Element][xml-readme]** -
  Manage XML element content and attributes

## Installation

### Prerequisites

- Windows operating system (for Windows-specific resources)
- [Microsoft DSC][microsoft-dsc] installed
- Administrator privileges (required for many operations)

### Installing from MSI (Requires .NET 9 Runtime)

Download and install the latest MSI package from the
[Releases][releases] page.

**Requirements:**

- [.NET 9.0 Runtime][dotnet-runtime]

The MSI installer will:

- Install all resource executables
- Register resources with DSC
- Add resources to your system PATH

### Portable Self-Contained Version (No Runtime Required)

Download the self-contained portable package from the
[Releases][releases] page.

This version includes the .NET 9 runtime embedded within the executables and
does not require a separate .NET installation.

**Installation:**

1. Download the `OpenDsc.Resources-Portable.zip` package
2. Extract to a directory (e.g., `C:\Program Files\OpenDsc\Resources`)
3. Ensure DSC can discover the resources:
   - Add the directory to your PATH, or
   - Set the `DSC_RESOURCE_PATH` environment variable

### Manual Installation

1. Download the latest release package
2. Extract to a directory (e.g., `C:\Program Files\OpenDsc\Resources`)
3. Ensure DSC can discover the resources:
   - Add the directory to your PATH, or
   - Set the `DSC_RESOURCE_PATH` environment variable

## Building from Source

### Requirements

- [.NET 9.0 SDK][dotnet-sdk]
- PowerShell 7.4+
- [Pester][pester] (for testing)

### Build All Resources

From the repository root:

```powershell
.\build.ps1
```

This will build all resources and run integration tests.

### Build MSI Package

Build the MSI installer package:

```powershell
.\build.ps1 -Msi
```

The MSI will be created in the `artifacts\msi` directory.

## Usage

All resources follow the standard Microsoft DSC pattern. Here's a quick example:

```powershell
# Set an environment variable
$config = @'
name: MY_APP_PATH
value: C:\MyApp
_scope: User
'@

dsc resource set -r OpenDsc.Windows/Environment -i $config
```

For detailed usage examples, see the individual resource README files linked
above.

## Resource Capabilities

All resources support standard DSC operations:

- **get** - Retrieve current state
- **set** - Apply desired state
- **delete** - Remove resource
- **export** - List all instances (where applicable)
- **test** - Test if in desired state (selected resources)

## Development

### Creating a New Resource

See [.github/copilot-instructions.md][copilot-instructions] for
detailed guidance on creating new resources, including project structure,
coding patterns, and best practices.

### Testing

Run all integration tests:

```powershell
.\build.ps1
```

Run tests for a specific resource:

```powershell
Invoke-Pester -Path .\tests\Environment.Tests.ps1
```

**Note:** Many tests require administrator privileges to run successfully.

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Follow the existing code style and patterns
4. Add tests for new functionality
5. Submit a pull request

## License

This project is licensed under the MIT License. See [LICENSE][license] for
details.

## Related Projects

- [Microsoft DSC][dsc-repo] - The core DSC engine
- [OpenDsc.Resource.CommandLine][commandline-repo] -
  Library for building DSC resources

## Support

- **Documentation:** See individual resource README files
- **Issues:** [GitHub Issues][issues]
- **Discussions:** [GitHub Discussions][discussions]

[env-readme]: src/OpenDsc.Resource.Windows/Environment/README.md
[group-readme]: src/OpenDsc.Resource.Windows/Group/README.md
[service-readme]: src/OpenDsc.Resource.Windows/Service/README.md
[user-readme]: src/OpenDsc.Resource.Windows/User/README.md
[shortcut-readme]: src/OpenDsc.Resource.Windows/Shortcut/README.md
[optionalfeature-readme]: src/OpenDsc.Resource.Windows/OptionalFeature/README.md
[acl-readme]: src/OpenDsc.Resource.Windows/FileSystem/Acl/README.md
[file-readme]: src/OpenDsc.Resource.FileSystem/File/README.md
[directory-readme]: src/OpenDsc.Resource.FileSystem/Directory/README.md
[xml-readme]: src/OpenDsc.Resource.Xml/Element/README.md
[microsoft-dsc]: https://learn.microsoft.com/powershell/dsc/overview
[releases]: https://github.com/opendsc/resources/releases
[dotnet-runtime]: https://dotnet.microsoft.com/download/dotnet/9.0
[dotnet-sdk]: https://dotnet.microsoft.com/download/dotnet/9.0
[pester]: https://pester.dev/
[copilot-instructions]: .github/copilot-instructions.md
[license]: LICENSE
[dsc-repo]: https://github.com/PowerShell/DSC
[commandline-repo]: https://github.com/opendsc/OpenDsc.Resource.CommandLine
[issues]: https://github.com/opendsc/resources/issues
[discussions]: https://github.com/opendsc/resources/discussions
