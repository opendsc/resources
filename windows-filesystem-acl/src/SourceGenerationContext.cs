// Copyright (c) Thomas Nieto - All Rights Reserved
// You may use, distribute and modify this code under the
// terms of the MIT license.

using System.Security.AccessControl;
using System.Text.Json.Serialization;

using OpenDsc.Resource.CommandLine;

namespace OpenDsc.Resource.Windows.FileSystemAcl;

[JsonSourceGenerationOptions(
    WriteIndented = false,
    PropertyNamingPolicy = JsonKnownNamingPolicy.CamelCase,
    UseStringEnumConverter = true,
    DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull,
    Converters = [typeof(ResourceConverter<Schema>)])]
[JsonSerializable(typeof(IDscResource<Schema>))]
[JsonSerializable(typeof(Schema))]
[JsonSerializable(typeof(FileSystemRights[]))]
[JsonSerializable(typeof(InheritanceFlags[]))]
[JsonSerializable(typeof(PropagationFlags[]))]
internal partial class SourceGenerationContext : JsonSerializerContext { }
