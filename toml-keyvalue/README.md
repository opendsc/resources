# OpenDsc.Toml/KeyValue

A DSC resource for managing TOML key-value pairs.

## Description

Manages key-value pairs in TOML files. Supports:

- Reading and writing values at any depth using dot notation
- Creating parent tables automatically when setting nested keys
- Different value types: strings, numbers, booleans, arrays, inline tables
- Deleting individual keys

## Schema

### Required Properties

- **path** (string): The path to the TOML file.
- **key** (string): Key using dot notation (e.g., `section.subsection.key`).
  Parent tables are created if they don't exist.

### Optional Properties

- **value** (object): Value. Supports strings, numbers, booleans, arrays.
  Null in Set with `_exist=true` creates key with empty string.
- **_exist** (boolean): Indicates whether the key should exist. Default: `true`

## Examples

### Get a value

```yaml
- name: Get database port
  type: OpenDsc.Toml/KeyValue
  properties:
    path: /etc/app/config.toml
    key: database.port
```

### Set a top-level value

```yaml
- name: Set application title
  type: OpenDsc.Toml/KeyValue
  properties:
    path: /etc/app/config.toml
    key: title
    value: "My Application"
```

### Set a nested value

```yaml
- name: Set database connection string
  type: OpenDsc.Toml/KeyValue
  properties:
    path: /etc/app/config.toml
    key: database.connection.host
    value: "localhost"
```

### Set different value types

```yaml
# String
- name: Set server name
  type: OpenDsc.Toml/KeyValue
  properties:
    path: /etc/app/config.toml
    key: server.name
    value: "production"

# Integer
- name: Set port
  type: OpenDsc.Toml/KeyValue
  properties:
    path: /etc/app/config.toml
    key: server.port
    value: 8080

# Boolean
- name: Enable debug mode
  type: OpenDsc.Toml/KeyValue
  properties:
    path: /etc/app/config.toml
    key: debug.enabled
    value: true
```

### Delete a key

```yaml
- name: Remove deprecated setting
  type: OpenDsc.Toml/KeyValue
  properties:
    path: /etc/app/config.toml
    key: legacy.feature
    _exist: false
```

## Notes

- TOML file must exist (use file resource to create it first)
- When setting nested keys, parent tables are created automatically
- Dot notation for key paths (e.g., `owner.name` is `name` in `owner` table)
- Setting value where parent key is not a table throws error
