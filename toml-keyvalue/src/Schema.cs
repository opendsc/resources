// Copyright (c) Thomas Nieto - All Rights Reserved
// You may use, distribute and modify this code under the
// terms of the MIT license.

using System.Text.Json;
using System.Text.Json.Serialization;

using Json.Schema.Generation;

namespace OpenDsc.Resource.Toml.KeyValue;

[Title("TOML Key-Value Schema")]
[Description("Schema for managing TOML key-value pairs via OpenDsc.")]
[AdditionalProperties(false)]
public sealed class Schema
{
    [Required]
    [Description("The path to the TOML file.")]
    public string Path { get; set; } = string.Empty;

    [Required]
    [Description("The key path using dot notation (e.g., 'section.subsection.key'). Parent tables will be created if they don't exist.")]
    public string Key { get; set; } = string.Empty;

    [Description("The value to set for the key. Supports strings, numbers, booleans, arrays, and inline tables. When null during Set operation with _exist=true, creates the key with empty string value.")]
    [Nullable(false)]
    public JsonElement? Value { get; set; }

    [JsonPropertyName("_exist")]
    [Description("Indicates whether the key should exist.")]
    [Nullable(false)]
    [Default(true)]
    public bool? Exist { get; set; }
}
