# OpenDsc.FileSystem/File Resource

Manage files using DSC v3.

## Capabilities

- **Get**: Retrieve current content and existence of a file
- **Set**: Create or update a file with specified content
- **Delete**: Remove a file

## Requirements

- Cross-platform (Windows, Linux, macOS)
- DSC v3 (Desired State Configuration)
- File system write permissions for the target directory

## Installation

Build and publish the resource:

```powershell
.\build.ps1
```

Ensure the published executable is in your PATH or DSC can discover the resource
manifest.

## Schema

### Properties

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `path` | string | Yes | The path to the file. Can be absolute or relative. |
| `content` | string | No | The content to write to the file. If not specified, an empty file is created. |
| `_exist` | boolean | No | Indicates whether the file should exist. Default: `true`. Set to `false` to delete. |

## Examples

### Get File

Retrieve the content of a file:

```yaml
path: /path/to/file.txt
```

### Create or Update File

Create a new file with content:

```yaml
path: /path/to/newfile.txt
content: Hello, World!
```

Update existing file content:

```yaml
path: /path/to/existing-file.txt
content: Updated content
```

### Create Empty File

Create an empty file:

```yaml
path: /path/to/empty-file.txt
```

### Delete File

Delete a file:

```yaml
path: /path/to/file-to-delete.txt
_exist: false
```

## Notes

- Content is written as UTF-8 text.
- Relative paths are resolved relative to the current working directory.
