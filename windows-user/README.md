# Windows User DSC Resource

Manage local Windows user accounts using Desired State Configuration (DSC).

## Description

The `OpenDsc.Windows/User` resource enables you to create, configure, update,
and delete local Windows user accounts. This resource provides comprehensive
user account management including password policies, account status, and user
properties.

## Features

- Create new local user accounts
- Update existing user properties
- Delete user accounts
- Configure password policies (never expires, user cannot change password)
- Enable or disable user accounts
- Export all local users
- Full DSC v3 compliance with get, set, delete, and export operations

## Requirements

- Windows operating system
- .NET 9.0 runtime
- Administrator privileges for user management operations

## Schema

### Properties

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `userName` | string | Yes | The username of the local user account. Must be 1-20 characters and cannot contain: `\ / [ ] : ; \| = , + * ? < > @ "` |
| `fullName` | string | No | The full name (display name) of the user |
| `description` | string | No | A description of the user account |
| `password` | string | No | The password for the user account. Write-only, not returned by Get operation. Required when creating a new user |
| `disabled` | boolean | No | Whether the user account is disabled |
| `passwordNeverExpires` | boolean | No | Whether the user's password never expires |
| `userMayNotChangePassword` | boolean | No | Whether the user may change their own password |
| `_exist` | boolean | No | Indicates whether the user account should exist. Default: `true` |

## Examples

### Create a new user

```yaml
# example.dsc.yaml
$schema: https://raw.githubusercontent.com/PowerShell/DSC/main/schemas/2024/04/config/document.json
resources:
  - name: Create local user
    type: OpenDsc.Windows/User
    properties:
      userName: jdoe
      fullName: John Doe
      description: Development team member
      password: P@ssw0rd123!
      passwordNeverExpires: false
```

### Create a disabled user

```yaml
resources:
  - name: Create disabled user
    type: OpenDsc.Windows/User
    properties:
      userName: tempuser
      password: Temp@Pass123
      disabled: true
      description: Temporary account
```

### Update user properties

```yaml
resources:
  - name: Update user
    type: OpenDsc.Windows/User
    properties:
      userName: jdoe
      fullName: John A. Doe
      description: Senior Developer
```

### Set password policy

```yaml
resources:
  - name: Configure service account
    type: OpenDsc.Windows/User
    properties:
      userName: svcaccount
      passwordNeverExpires: true
      userMayNotChangePassword: true
      description: Service account for background tasks
```

### Delete a user

```yaml
resources:
  - name: Remove user
    type: OpenDsc.Windows/User
    properties:
      userName: olduser
      _exist: false
```

## CLI Usage

### Get user information

```powershell
dsc resource get -r OpenDsc.Windows/User --input '{"userName":"jdoe"}'
```

### Create or update a user

```powershell
dsc resource set -r OpenDsc.Windows/User --input '{
  "userName":"jdoe",
  "fullName":"John Doe",
  "password":"P@ssw0rd123!",
  "description":"Developer"
}'
```

### Delete a user

```powershell
dsc resource delete -r OpenDsc.Windows/User --input '{"userName":"jdoe"}'
```

### Export all users

```powershell
dsc resource export -r OpenDsc.Windows/User
```

## Notes

- **Administrator privileges required**: All user management operations require
  administrator privileges
- **Password security**: Passwords are write-only and never returned by the Get
  operation
- **New user requirements**: When creating a new user, the `password` property
  is required
- **Password validation**: Windows enforces password complexity requirements
  based on local security policy
- **Username constraints**: Usernames must follow Windows naming conventions
  (1-20 characters, no special characters)
- **Built-in accounts**: Be careful when managing built-in accounts
  (Administrator, Guest, etc.)

## Building

From the `windows-user` directory:

```powershell
.\build.ps1
```

This will:

1. Build and publish the resource executable
2. Generate the DSC resource manifest
3. Run Pester integration tests

## Testing

Run the Pester tests:

```powershell
Invoke-Pester
```

Tests require administrator privileges as they create and delete test user
accounts.
