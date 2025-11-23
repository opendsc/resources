# Windows FileSystem AccessControlList Resource

A DSC v3 resource for managing Windows file and directory permissions (Access
Control Lists).

## Description

The `OpenDsc.Windows.FileSystem/AccessControlList` resource provides the ability
to manage file and directory permissions on Windows systems using DSC v3. It
supports:

- Reading and setting file/directory owners
- Reading and setting file/directory groups
- Managing access control entries (ACEs) with full control over rights,
  inheritance, and propagation
- Both additive and exact (purge) modes for access rules

## Requirements

- Windows operating system
- .NET 9.0 or later
- Administrator privileges required for most operations (changing ownership,
  modifying permissions)

## Schema Properties

### Required Properties

- **path** (string): The full path to the file or directory. Must be a valid
  Windows path.

### Optional Properties

- **owner** (string): The owner of the file or directory. Can be specified as:
  - Username: `username`
  - Domain\username: `DOMAIN\username`
  - SID: `S-1-5-21-...`

- **group** (string): The primary group of the file or directory. Same format as
  owner.

- **accessRules** (array): List of access control entries (ACEs) to apply. Each
  entry contains:
  - **identity** (required, string): The user or group the rule applies to
  - **rights** (required, enum): File system rights (e.g., `Read`, `Write`,
    `FullControl`, `Modify`)
  - **inheritanceFlags** (enum): How the rule is inherited (`None`,
    `ContainerInherit`, `ObjectInherit`)
  - **propagationFlags** (enum): How inheritance is propagated (`None`,
    `NoPropagateInherit`, `InheritOnly`)
  - **accessControlType** (required, enum): `Allow` or `Deny`

### DSC Canonical Properties

- **_exist** (bool): Indicates whether the file or directory exists. Default:
  `true`
- **_purge** (bool): When `true`, removes access rules not in the `accessRules`
  list. When `false`, only adds rules without removing others. Default: `false`

## File System Rights

The resource supports the following rights:

- `ReadData` / `Read` / `ReadAndExecute`
- `WriteData` / `Write`
- `AppendData`
- `ReadExtendedAttributes` / `WriteExtendedAttributes`
- `ReadAttributes` / `WriteAttributes`
- `ExecuteFile`
- `DeleteSubdirectoriesAndFiles`
- `Delete`
- `ReadPermissions` / `ChangePermissions`
- `TakeOwnership`
- `Synchronize`
- `FullControl`
- `Modify`

## Examples

### Example 1: Read current ACL

```yaml
resources:
  - name: ReadACL
    type: OpenDsc.Windows.FileSystem/AccessControlList
    properties:
      path: C:\MyFolder
```

### Example 2: Set owner and group

```yaml
resources:
  - name: ChangeOwner
    type: OpenDsc.Windows.FileSystem/AccessControlList
    properties:
      path: C:\MyFolder
      owner: BUILTIN\Administrators
      group: BUILTIN\Users
```

### Example 3: Add access rule (additive mode)

```yaml
resources:
  - name: GrantReadAccess
    type: OpenDsc.Windows.FileSystem/AccessControlList
    properties:
      path: C:\MyFolder
      accessRules:
        - identity: BUILTIN\Users
          rights: Read
          inheritanceFlags: ContainerInherit
          propagationFlags: None
          accessControlType: Allow
      _purge: false
```

### Example 4: Set exact permissions (purge mode)

```yaml
resources:
  - name: SetExactPermissions
    type: OpenDsc.Windows.FileSystem/AccessControlList
    properties:
      path: C:\MyFolder
      accessRules:
        - identity: BUILTIN\Administrators
          rights: FullControl
          inheritanceFlags: ContainerInherit
          propagationFlags: None
          accessControlType: Allow
        - identity: BUILTIN\Users
          rights: Read
          inheritanceFlags: ContainerInherit
          propagationFlags: None
          accessControlType: Allow
      _purge: true
```

### Example 5: Deny access

```yaml
resources:
  - name: DenyAccess
    type: OpenDsc.Windows.FileSystem/AccessControlList
    properties:
      path: C:\MyFolder
      accessRules:
        - identity: DOMAIN\RestrictedUser
          rights: Write
          accessControlType: Deny
```

## Operations

### Get

Reads the current access control list for a file or directory.

```powershell
$config = @{
    path = 'C:\MyFolder'
} | ConvertTo-Json

dsc resource get -r OpenDsc.Windows.FileSystem/AccessControlList --input $config
```

### Set

Applies the specified ACL configuration to a file or directory.

```powershell
$config = @{
    path = 'C:\MyFolder'
    owner = 'BUILTIN\Administrators'
    accessRules = @(
        @{
            identity = 'BUILTIN\Users'
            rights = 'Read'
            accessControlType = 'Allow'
        }
    )
} | ConvertTo-Json -Depth 3

dsc resource set -r OpenDsc.Windows.FileSystem/AccessControlList --input $config
```

## Building

```powershell
.\build.ps1
```

This will:

1. Compile the resource using `dotnet publish`
2. Generate the resource manifest
3. Run Pester integration tests

## Testing

```powershell
Invoke-Pester
```

**Note:** Most tests require administrator privileges to run successfully, as
they involve changing file permissions and ownership.

## Notes

- Changing ownership and modifying permissions typically requires administrator
  privileges
- The resource supports both files and directories
- Inheritance flags only apply to directories
- When using `_purge: true`, be careful not to lock yourself out of the resource
- Identity resolution supports multiple formats: username, DOMAIN\username, and
  SID
