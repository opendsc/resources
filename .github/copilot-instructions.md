# OpenDSC Resources - AI Coding Agent Instructions

## Project Overview

This repository contains DSC v3 (Desired State Configuration) resources for Windows management. Each resource is a standalone C# executable that implements a standard DSC interface through the `OpenDsc.Resource.CommandLine` library.

**Key Resources:**
- `windows-environment/` - Environment variable management
- `windows-service/` - Windows service control
- `windows-shortcut/` - Shortcut (.lnk) file management

## Architecture Pattern

### Resource Structure (All resources follow this pattern)

Each resource is a self-contained .NET 9.0 console application with these core files:

```
<resource-name>/
├── src/
│   ├── Program.cs              # Entry point: builds command via CommandBuilder
│   ├── Resource.cs             # Core logic with [DscResource] attribute
│   ├── Schema.cs               # JSON schema model with validation attributes
│   ├── SourceGenerationContext.cs  # AOT-friendly JSON serialization
│   └── *.csproj                # Project configuration
├── tests/
│   └── *.Tests.ps1             # Pester tests
└── build.ps1                   # Build script: dotnet publish + Invoke-Pester
```

### Critical Inheritance Pattern

All resources inherit from `AotDscResource<Schema>` and implement capability interfaces:

```csharp
public sealed class Resource(JsonSerializerContext context)
    : AotDscResource<Schema>(context),
      IGettable<Schema>,      // Read current state (optional, but recommended)
      ISettable<Schema>,      // Apply desired state (optional, but recommended)
      IDeletable<Schema>,     // Remove resource (optional, but recommended)
      IExportable<Schema>     // Export all instances (optional)
```

**Interface Contract (all interfaces are optional, implement those that make sense):**
- `IGettable.Get(Schema)` → return current state (set `Exist = false` if not found)
- `ISettable.Set(Schema)` → apply changes, return `null` or `SetResult<Schema>`
- `IDeletable.Delete(Schema)` → remove resource
- `IExportable.Export()` → yield all instances

**Best Practice:** Strive to implement all interfaces that make sense for your resource type.

### Schema Conventions

Schemas use JSON Schema Generation attributes from `Json.Schema.Generation`:

```csharp
[Title("...")]
[Description("...")]
[AdditionalProperties(false)]
public sealed class Schema
{
    [Required]
    [Pattern(@"regex")]
    public string Name { get; set; }

    [JsonPropertyName("_exist")]  // DSC canonical properties prefixed with _
    [Default(true)]
    public bool? Exist { get; set; }
}
```

**Naming Rules:**
- User-facing properties: camelCase (enforced by `PropertyNameResolver.CamelCase`)
- DSC canonical properties: `_exist`, `_purge`, `_inDesiredState` (underscore prefix)
- Enums: PascalCase values (e.g., `User`, `Machine`)

**DSC Canonical Properties:**

DSC defines several canonical properties that provide shared semantics across resources. These properties always start with an underscore (`_`) and should not be overridden or extended:

- **`_exist` (bool?)** - Indicates whether the resource instance should exist. Used to enforce create/update/delete operations during `set`. This is the most commonly used canonical property.
  - Default: `true`
  - Use in: Resources that manage instance lifecycle

- **`_purge` (bool?)** - Write-only property for list-based resources to indicate whether unmanaged entries should be removed. Useful for resources managing collections where you want to either allow or remove items not explicitly defined.
  - Use in: Resources managing lists/collections (e.g., group members, installed features)

- **`_inDesiredState` (bool?)** - Read-only property indicating whether the instance is in desired state. Mandatory for resources that implement the `test` operation.
  - Use in: Resources implementing `ITestable<Schema>`

**Nullability Guidelines:**
- Use `[Nullable(false)]` only on C# nullable properties (those with `?`) where you want to prevent users from submitting `null` values in JSON (e.g., optional strings, booleans)
- Non-nullable C# types (e.g., `string Name` with `[Required]`) don't need `[Nullable(false)]` - they already cannot be null
- DSC canonical properties like `_exist` should use nullable types (e.g., `bool?`) for their C# type, and should have `[Nullable(false)]` to prevent explicit null submission
- The `[Nullable]` attribute controls JSON deserialization behavior, while the `?` on the type controls C# nullability

**Resource Metadata (`_metadata`):**

Resources can return metadata in their results by including a `_metadata` property in the schema returned by `Get()`. The most important metadata property is `_restartRequired`, which indicates what needs to be restarted after a set operation.

When `Set()` needs to communicate metadata (like restart requirements), it should return a `SetResult<Schema>` containing the actual state with metadata attached. DSC automatically calls `Get()` before and after `Set()`, so you don't need to call `Get()` yourself to populate before/after states.

**Important:** When your resource returns actual state from `Set()`, you must add `SetReturn = SetReturn.State` to the `[DscResource]` attribute. When this attribute is set, `Set()` must ALWAYS return a `SetResult<Schema>` with the actual state (never return `null`).

```csharp
[DscResource("OpenDsc.Windows/MyResource", SetReturn = SetReturn.State)]
public sealed class Resource(JsonSerializerContext context)
    : AotDscResource<Schema>(context), IGettable<Schema>, ISettable<Schema>
{
    public Schema Get(Schema instance)
    {
        // ... get current state
    }

    public SetResult<Schema>? Set(Schema instance)
    {
        // ... perform the operation

        // When SetReturn.State is used, always return actual state
        var actualState = Get(instance);

        // Example: Add metadata when restart is needed
        if (restartRequired)
        {
            actualState.Metadata = new Dictionary<string, object>
            {
                ["_restartRequired"] = new[]
                {
                    new { system = Environment.MachineName },      // System restart
                    new { service = "serviceName" },               // Service restart
                    new { process = new { name = "app", id = 1234 } }  // Process restart
                }
            };
        }

        return new SetResult<Schema>(actualState);  // Always return actual state when SetReturn.State is set
    }
}
```

**Restart Types:**
- **System restart**: `{ "system": "computerName" }` - indicates the computer needs to restart
- **Service restart**: `{ "service": "serviceName" }` - indicates a specific service needs to restart
- **Process restart**: `{ "process": { "name": "processName", "id": 1234 } }` - indicates a specific process needs to restart

**Example JSON payload** that a resource would return with restart metadata:

```json
{
  "name": "MyFeature",
  "state": "Present",
  "_metadata": {
    "_restartRequired": [
      { "system": "SERVER01" }
    ]
  }
}
```

DSC automatically aggregates `_restartRequired` entries from all resources into the top-level `Microsoft.DSC` metadata in the configuration result.

## Build & Test Workflow

### Building a Resource

```powershell
# From resource directory (e.g., windows-environment/)
.\build.ps1

# Or manually:
dotnet publish src/*.csproj -c Release
```

**Build Process:**
1. `dotnet publish` creates single-file executable
2. MSBuild `RunAfterPublish` target generates `.dsc.resource.json` manifest via `<exe> manifest`
3. Output: `src/bin/Release/net9.0/win-x64/publish/<resource-name>.exe`

### Testing with Pester

Tests are **integration tests only** - they verify end-to-end behavior through the DSC CLI:

```powershell
# Discovery
dsc resource list OpenDsc.Windows/Environment

# Operations
dsc resource get -r OpenDsc.Windows/Environment --input '{"name":"PATH"}'
dsc resource set -r OpenDsc.Windows/Environment --input '{"name":"TEST","value":"123"}'
dsc resource delete -r OpenDsc.Windows/Environment --input '{"name":"TEST"}'
```

**Test Pattern:** Create → Verify → Cleanup (always cleanup in `AfterEach`/`AfterAll`)
**No unit tests** - resources are tested through published executables via DSC CLI

## Project-Specific Conventions

### Source Generation (Required for AOT)

Every resource needs `SourceGenerationContext.cs`:

```csharp
[JsonSourceGenerationOptions(
    WriteIndented = false,
    PropertyNamingPolicy = JsonKnownNamingPolicy.CamelCase,
    UseStringEnumConverter = true,
    DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull,
    Converters = [typeof(ResourceConverter<Schema>)])]
[JsonSerializable(typeof(IDscResource<Schema>))]
[JsonSerializable(typeof(Schema))]
internal partial class SourceGenerationContext : JsonSerializerContext { }
```

Pass this context to both `Resource` constructor and `CommandBuilder`.

### Error Handling with Exit Codes

Use `[ExitCode]` attributes on `Resource` class:

```csharp
[ExitCode(0, Description = "Success")]
[ExitCode(1, Description = "Invalid parameter")]
[ExitCode(3, Exception = typeof(JsonException), Description = "Invalid JSON")]
[ExitCode(4, Exception = typeof(SecurityException), Description = "Access denied")]
```

Throw mapped exceptions; framework handles exit codes.

### File Headers (Enforced)

All `.cs` files require MIT license header (IDE0073 warning):

```csharp
// Copyright (c) Thomas Nieto - All Rights Reserved
// You may use, distribute and modify this code under the
// terms of the MIT license.
```

### COM Interop Pattern (windows-shortcut)

For COM interfaces, use P/Invoke declarations with manual RCW management:

```csharp
[ComImport, Guid("..."), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
interface IShellLinkW { /* methods */ }

// Usage: Always release COM objects in finally blocks
try {
    link = (IShellLinkW)new ShellLink();
    // ... use link
} finally {
    if (link != null) Marshal.ReleaseComObject(link);
}
```

## Common Implementation Patterns

### Handling Non-Existent Resources in Get()

```csharp
public Schema Get(Schema instance)
{
    try {
        // Attempt to read resource
        return new Schema { Name = instance.Name, Value = value, Exist = true };
    }
    catch (ResourceNotFoundException) {
        return new Schema { Name = instance.Name, Exist = false };
    }
}
```

### Creating Resources in Set()

```csharp
public SetResult<Schema>? Set(Schema instance)
{
    if (Get(instance).Exist == false)
    {
        CreateResource(instance);  // Helper method
    }

    // Apply configuration changes
    UpdateResource(instance);

    return null;  // Or return SetResult with before/after states
}
```

### Scope/Privilege Patterns

Check scope in Get/Set/Delete for user vs. machine operations (see `windows-environment`):

```csharp
var target = instance.Scope is Scope.Machine
    ? EnvironmentVariableTarget.Machine
    : EnvironmentVariableTarget.User;
```

Machine scope requires admin elevation.

## Creating a New Resource

### Checklist

Use `windows-environment` as the template - it's the simplest, most complete example.

1. **Create directory structure using dotnet template:**
   ```powershell
   # Install the dsc-aot template (if not already installed)
   dotnet new install dsc-aot

   # Create new resource from template
   dotnet new dsc-aot -n windows-<name> -o windows-<name>
   ```

   This creates:
   ```
   windows-<name>/
   ├── src/
   │   ├── Program.cs
   │   ├── Resource.cs
   │   ├── Schema.cs
   │   ├── SourceGenerationContext.cs
   │   └── *.csproj
   ├── tests/
   │   └── *.Tests.ps1
   └── build.ps1
   ```

2. **Customize generated files:**
   - `Program.cs` - Update resource name and namespace (minimal changes needed)
   - `Resource.cs` - Core implementation with `[DscResource]` attribute
   - `Schema.cs` - Property definitions with JSON Schema attributes and `[Nullable(false)]` on non-nullable properties
   - `SourceGenerationContext.cs` - Update type references for your schema
   - `*.csproj` - Update `AssemblyName`, add platform-specific packages if needed

3. **Implement Resource class:**
   - Inherit from `AotDscResource<Schema>` with context parameter
   - Add `[DscResource("OpenDsc.Windows/<Name>")]` attribute
   - Define `[ExitCode]` mappings for exceptions
   - Implement capability interfaces (all optional, but implement those that make sense):
     - `IGettable<Schema>` - return current state or `Exist = false`
     - `ISettable<Schema>` - apply changes
     - `IDeletable<Schema>` - remove resource
     - `IExportable<Schema>` - enumerate all instances

4. **Define Schema:**
   - Add `[Title]`, `[Description]`, `[AdditionalProperties(false)]`
   - Required key property with `[Required]` and `[Pattern]` validation
   - Use `[Nullable(false)]` on properties where users should not submit `null` values
   - Use `[JsonPropertyName("_propertyName")]` for DSC canonical properties
   - Add `[Default]` values where appropriate
   - All enums use PascalCase values

5. **Create build.ps1:**
   ```powershell
   $csproj = Get-ChildItem $PSScriptRoot\src\*.csproj
   dotnet publish $csproj
   Invoke-Pester
   ```

6. **Write integration tests** (`tests/*.Tests.ps1`):
   - Discovery: `dsc resource list OpenDsc.Windows/<Name>`
   - Get operation: test existing and non-existent resources
   - Set operation: create and update
   - Delete operation: remove and verify
   - Export operation (if implemented)
   - Always cleanup test resources in `AfterEach`/`AfterAll`

7. **Add MSBuild manifest generation** to `.csproj`:
   ```xml
   <Target Name="RunAfterPublish" AfterTargets="Publish">
     <PropertyGroup>
       <OutputFileName>$(TargetName).dsc.resource.json</OutputFileName>
     </PropertyGroup>
     <Exec Command="$(PublishDir)$(TargetName).exe manifest &gt; $(PublishDir)$(OutputFileName)" />
   </Target>
   ```

8. **Verify:**
   - File headers present in all `.cs` files (MIT license)
   - Build succeeds: `.\build.ps1`
   - Tests pass: manifest generated, all Pester tests green
   - Manual test: `dsc resource get -r OpenDsc.Windows/<Name> --input '{...}'`

## Key Files to Reference

- **Template Resource:** `windows-environment/` (simplest implementation)
- **COM Interop:** `windows-shortcut/src/ShortcutHelper.cs` (P/Invoke patterns)
- **Service Control:** `windows-service/src/ServiceHelper.cs` (Win32 API wrappers)
- **Test Examples:** `windows-environment/tests/*.Tests.ps1` (comprehensive test suite)
- **Editor Config:** `.editorconfig` (C# style rules, file headers)
