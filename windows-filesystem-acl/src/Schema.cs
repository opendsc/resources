// Copyright (c) Thomas Nieto - All Rights Reserved
// You may use, distribute and modify this code under the
// terms of the MIT license.

using System.Security.AccessControl;
using System.Text.Json.Serialization;

using Json.Schema.Generation;

namespace OpenDsc.Resource.Windows.FileSystemAcl;

[Title("Windows File System Access Control List Schema")]
[Description("Schema for managing Windows file and directory permissions via OpenDsc.")]
[AdditionalProperties(false)]
public sealed class Schema
{
    [Required]
    [Description("The full path to the file or directory.")]
    [Pattern(@"^[a-zA-Z]:\\(?:[^<>:""/\\|?*\x00-\x1F]+\\)*[^<>:""/\\|?*\x00-\x1F]*$")]
    public string Path { get; set; } = string.Empty;

    [Description("The owner of the file or directory. Can be specified as: username, domain\\username, or SID (S-1-5-...).")]
    [Nullable(false)]
    [Pattern(@"^(?:S-1-[0-59]-\d+(?:-\d+)*|[^\\]+\\[^\\]+|[^\\@]+)$")]
    public string? Owner { get; set; }

    [Description("The primary group of the file or directory. Can be specified as: groupName, domain\\groupName, or SID (S-1-5-...).")]
    [Nullable(false)]
    [Pattern(@"^(?:S-1-[0-59]-\d+(?:-\d+)*|[^\\]+\\[^\\]+|[^\\@]+)$")]
    public string? Group { get; set; }

    [Description("Access control entries (ACEs) to apply to the file or directory.")]
    [Nullable(false)]
    public AccessRule[]? AccessRules { get; set; }

    [JsonPropertyName("_purge")]
    [Description("When true, removes access rules not in the AccessRules list. When false, only adds rules from the AccessRules list without removing others. Only applicable when AccessRules is specified.")]
    [Nullable(false)]
    [WriteOnly]
    [Default(false)]
    public bool? Purge { get; set; }

    [JsonPropertyName("_exist")]
    [Description("Indicates whether the file or directory exists.")]
    [Nullable(false)]
    [Default(true)]
    public bool? Exist { get; set; }
}

[Title("Access Rule")]
[Description("Represents a file system access control entry.")]
[AdditionalProperties(false)]
public sealed class AccessRule
{
    [Required]
    [Description("The identity to which the rule applies. Can be specified as: username, domain\\username, or SID (S-1-5-...).")]
    [Pattern(@"^(?:S-1-[0-59]-\d+(?:-\d+)*|[^\\]+\\[^\\]+|[^\\@]+)$")]
    public string Identity { get; set; } = string.Empty;

    [Required]
    [Description("The file system rights granted or denied.")]
    public FileSystemRights Rights { get; set; }

    [Description("The inheritance flags that determine how the rule is inherited by child objects.")]
    [Default("None")]
    public InheritanceFlags InheritanceFlags { get; set; } = InheritanceFlags.None;

    [Description("The propagation flags that determine how inheritance is propagated.")]
    [Default("None")]
    public PropagationFlags PropagationFlags { get; set; } = PropagationFlags.None;

    [Required]
    [Description("Whether the rule allows or denies access.")]
    public AccessControlType AccessControlType { get; set; }
}
