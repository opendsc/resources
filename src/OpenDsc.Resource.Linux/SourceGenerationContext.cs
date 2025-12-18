// Copyright (c) Thomas Nieto - All Rights Reserved
// You may use, distribute and modify this code under the
// terms of the MIT license.

using System.Text.Json;
using System.Text.Json.Serialization;

namespace OpenDsc.Resource.Linux;

[JsonSourceGenerationOptions(
    WriteIndented = false,
    PropertyNamingPolicy = JsonKnownNamingPolicy.CamelCase,
    UseStringEnumConverter = true,
    DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull)]
[JsonSerializable(typeof(IDscResource<FileSystem.File.Schema>), TypeInfoPropertyName = "IDscResourceFileSchema")]
[JsonSerializable(typeof(FileSystem.File.Schema), TypeInfoPropertyName = "FileSchema")]
[JsonSerializable(typeof(TestResult<FileSystem.File.Schema>), TypeInfoPropertyName = "TestResultFileSchema")]
[JsonSerializable(typeof(SetResult<FileSystem.File.Schema>), TypeInfoPropertyName = "SetResultFileSchema")]
[JsonSerializable(typeof(IDscResource<FileSystem.Directory.Schema>), TypeInfoPropertyName = "IDscResourceDirectorySchema")]
[JsonSerializable(typeof(FileSystem.Directory.Schema), TypeInfoPropertyName = "DirectorySchema")]
[JsonSerializable(typeof(TestResult<FileSystem.Directory.Schema>), TypeInfoPropertyName = "TestResultDirectorySchema")]
[JsonSerializable(typeof(SetResult<FileSystem.Directory.Schema>), TypeInfoPropertyName = "SetResultDirectorySchema")]
[JsonSerializable(typeof(IDscResource<Xml.Element.Schema>), TypeInfoPropertyName = "IDscResourceXmlElementSchema")]
[JsonSerializable(typeof(Xml.Element.Schema), TypeInfoPropertyName = "XmlElementSchema")]
[JsonSerializable(typeof(TestResult<Xml.Element.Schema>), TypeInfoPropertyName = "TestResultXmlElementSchema")]
[JsonSerializable(typeof(SetResult<Xml.Element.Schema>), TypeInfoPropertyName = "SetResultXmlElementSchema")]
[JsonSerializable(typeof(Dictionary<string, string>))]
[JsonSerializable(typeof(DscResourceManifest))]
[JsonSerializable(typeof(JsonElement))]
[JsonSerializable(typeof(Json.Schema.JsonSchema))]
public partial class SourceGenerationContext : JsonSerializerContext
{
}
