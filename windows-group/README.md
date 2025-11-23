# Windows Group Resource

A DSC v3 resource for managing local Windows groups.

## Description

The `OpenDsc.Windows/Group` resource allows you to manage local Windows groups
including creating, updating, and deleting groups, as well as managing group
membership.

## Requirements

- Windows operating system
- .NET 9.0 runtime
- Administrative privileges (for set, delete, and some get operations)

## Properties

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `groupName` | string | Yes | The name of the local group |
| `description` | string | No | A description of the group |
| `members` | string[] | No | List of group members |
| `_purge` | boolean | No | When true, removes members not in the members list. When false, only adds members without removing others (default: false) |
| `_exist` | boolean | No | Whether the group should exist (default: true) |

## Member Management

The resource uses the `_purge` canonical property to control membership
behavior:

- **Additive membership (`_purge: false`, default)**: Adds specified members to
  the group without removing existing members.
- **Exact membership (`_purge: true`)**: Ensures only the specified members are
  present. Removes any members not in the list.

Members can be specified as:

- Username: `john`
- Domain\Username: `DOMAIN\john`
- SID: `S-1-5-21-...`

## Examples

### Example 1: Create a new group

```yaml
resources:
  - name: Create Developers Group
    type: OpenDsc.Windows/Group
    properties:
      groupName: Developers
      description: Development team members
```

### Example 2: Create a group with exact membership

```yaml
resources:
  - name: Create Admins Group
    type: OpenDsc.Windows/Group
    properties:
      groupName: ProjectAdmins
      description: Project administrators
      members:
        - john
        - jane
        - bob
      _purge: true
```

### Example 3: Add members without removing others

```yaml
resources:
  - name: Add to Users
    type: OpenDsc.Windows/Group
    properties:
      groupName: Users
      members:
        - john
        - jane
      _purge: false
```

### Example 4: Delete a group

```yaml
resources:
  - name: Remove Old Group
    type: OpenDsc.Windows/Group
    properties:
      groupName: OldProjectTeam
      _exist: false
```

## Operations

### Get

Retrieves the current state of a local Windows group.

```powershell
dsc resource get -r OpenDsc.Windows/Group --input '{
  "groupName": "Administrators"
}'
```

### Set

Creates or updates a local Windows group.

```powershell
dsc resource set -r OpenDsc.Windows/Group --input '{
  "groupName": "Developers",
  "description": "Development team",
  "members": ["john", "jane"],
  "_purge": true
}'
```

### Delete

Removes a local Windows group.

```powershell
dsc resource delete -r OpenDsc.Windows/Group --input '{
  "groupName": "OldGroup"
}'
```

### Export

Exports all local Windows groups.

```powershell
dsc resource export -r OpenDsc.Windows/Group
```
