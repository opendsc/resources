# OpenDsc.Xml/Element

Cross-platform DSC resource for managing XML element content and attributes.

## Description

This resource allows you to manage XML documents by reading, creating, updating,
and deleting XML elements and their attributes using XPath expressions. Parent
elements are created recursively as needed.

## Features

- **Get**: Read XML element text content and attributes
- **Set**: Create or update XML elements and attributes
- **Delete**: Remove XML elements
- **Cross-platform**: Works on Windows, Linux, and macOS
- **XPath support**: Locate elements using XPath expressions
- **Namespace support**: Handle namespaced XML documents
- **Attribute management**: Add, update, or remove attributes with `_purge`
  pattern
- **Encoding preservation**: Automatically detects and preserves file encoding

## Schema Properties

### Required Properties

- **path** (string): Absolute file path to the XML document
- **xPath** (string): XPath expression to locate the element

### Optional Properties

- **value** (string): The text content (inner text) of the element
- **attributes** (object): Key-value pairs of attributes to set on the element
- **namespaces** (object): Namespace prefix mappings for XPath evaluation (e.g.,
  `{"ns": "http://example.com/schema"}`)
- **_purge** (bool): When `true`, removes attributes not in the `attributes`
  dictionary. When `false` (default), only adds/updates specified attributes
- **_exist** (bool): Whether the element should exist (default: `true`)

**Note:** The `value` and `attributes` properties serve dual purposes:

- As **input** for `set` operations to specify desired state
- As **output** from `get` operations to return current state

## Examples

### Create an element with text content

```yaml
resources:
  - name: OpenDsc.Xml/Element
    properties:
      path: /etc/app/config.xml
      xPath: /configuration/logging/level
      value: Debug
```

### Create an element with attributes

```yaml
resources:
  - name: OpenDsc.Xml/Element
    properties:
      path: C:\config\app.config
      xPath: /configuration/appSettings/add
      attributes:
        key: DatabaseConnection
        value: Server=localhost;Database=db
```

### Update attributes (additive mode)

By default, only specified attributes are added or updated. Existing attributes
not mentioned are preserved.

```yaml
resources:
  - name: OpenDsc.Xml/Element
    properties:
      path: /etc/app/settings.xml
      xPath: /configuration/feature
      attributes:
        enabled: "true"
        version: "2.0"
      # Other existing attributes are preserved
```

### Update attributes (purge mode)

Use `_purge: true` to ensure the element has ONLY the specified attributes.

```yaml
resources:
  - name: OpenDsc.Xml/Element
    properties:
      path: /etc/app/settings.xml
      xPath: /configuration/feature
      attributes:
        enabled: "true"
        version: "2.0"
      _purge: true
      # Removes any attributes not listed above
```

### Create nested elements recursively

Parent elements are automatically created if they don't exist.

```yaml
resources:
  - name: OpenDsc.Xml/Element
    properties:
      path: /etc/app/config.xml
      xPath: /root/level1/level2/level3/setting
      value: DeepValue
      # Creates all parent elements: root, level1, level2, level3
```

### Remove an element

```yaml
resources:
  - name: OpenDsc.Xml/Element
    properties:
      path: C:\config\app.xml
      xPath: /configuration/obsoleteSection
      _exist: false
```

### Work with namespaced XML

```yaml
resources:
  - name: OpenDsc.Xml/Element
    properties:
      path: /etc/app/config.xml
      xPath: /ns:configuration/ns:setting
      value: Value
      namespaces:
        ns: http://example.com/namespace
```

## Notes

- The XML file must exist before using `set` operation. The resource does not
  create new files.
- Parent elements specified in the XPath are created automatically if missing.
- File encoding is automatically detected and preserved when updating documents.
- XML documents are formatted with indentation when saved.
- Use `_purge: true` to enforce exact attribute sets (removes unlisted
  attributes).
- Use `_purge: false` (default) for additive mode (preserves existing
  attributes).

## Building

```powershell
.\build.ps1
```

## Testing

```powershell
Invoke-Pester
```

## Requirements

- .NET 9.0 or later
- DSC v3

## License

MIT License - Copyright (c) Thomas Nieto
