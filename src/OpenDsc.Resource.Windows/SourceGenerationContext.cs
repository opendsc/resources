// Copyright (c) Thomas Nieto - All Rights Reserved
// You may use, distribute and modify this code under the
// terms of the MIT license.

using System.Text.Json;
using System.Text.Json.Serialization;

using OpenDsc.Resource;

namespace OpenDsc.Resource.Windows;

[JsonSourceGenerationOptions(
    WriteIndented = false,
    PropertyNamingPolicy = JsonKnownNamingPolicy.CamelCase,
    UseStringEnumConverter = true,
    DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull)]
[JsonSerializable(typeof(IDscResource<Group.Schema>), TypeInfoPropertyName = "IDscResourceGroupSchema")]
[JsonSerializable(typeof(Group.Schema), TypeInfoPropertyName = "GroupSchema")]
[JsonSerializable(typeof(TestResult<Group.Schema>), TypeInfoPropertyName = "TestResultGroupSchema")]
[JsonSerializable(typeof(SetResult<Group.Schema>), TypeInfoPropertyName = "SetResultGroupSchema")]
[JsonSerializable(typeof(IDscResource<User.Schema>), TypeInfoPropertyName = "IDscResourceUserSchema")]
[JsonSerializable(typeof(User.Schema), TypeInfoPropertyName = "UserSchema")]
[JsonSerializable(typeof(TestResult<User.Schema>), TypeInfoPropertyName = "TestResultUserSchema")]
[JsonSerializable(typeof(SetResult<User.Schema>), TypeInfoPropertyName = "SetResultUserSchema")]
[JsonSerializable(typeof(IDscResource<Service.Schema>), TypeInfoPropertyName = "IDscResourceServiceSchema")]
[JsonSerializable(typeof(Service.Schema), TypeInfoPropertyName = "ServiceSchema")]
[JsonSerializable(typeof(TestResult<Service.Schema>), TypeInfoPropertyName = "TestResultServiceSchema")]
[JsonSerializable(typeof(SetResult<Service.Schema>), TypeInfoPropertyName = "SetResultServiceSchema")]
[JsonSerializable(typeof(IDscResource<Environment.Schema>), TypeInfoPropertyName = "IDscResourceEnvironmentSchema")]
[JsonSerializable(typeof(Environment.Schema), TypeInfoPropertyName = "EnvironmentSchema")]
[JsonSerializable(typeof(TestResult<Environment.Schema>), TypeInfoPropertyName = "TestResultEnvironmentSchema")]
[JsonSerializable(typeof(SetResult<Environment.Schema>), TypeInfoPropertyName = "SetResultEnvironmentSchema")]
[JsonSerializable(typeof(IDscResource<Shortcut.Schema>), TypeInfoPropertyName = "IDscResourceShortcutSchema")]
[JsonSerializable(typeof(Shortcut.Schema), TypeInfoPropertyName = "ShortcutSchema")]
[JsonSerializable(typeof(TestResult<Shortcut.Schema>), TypeInfoPropertyName = "TestResultShortcutSchema")]
[JsonSerializable(typeof(SetResult<Shortcut.Schema>), TypeInfoPropertyName = "SetResultShortcutSchema")]
[JsonSerializable(typeof(IDscResource<OptionalFeature.Schema>), TypeInfoPropertyName = "IDscResourceOptionalFeatureSchema")]
[JsonSerializable(typeof(OptionalFeature.Schema), TypeInfoPropertyName = "OptionalFeatureSchema")]
[JsonSerializable(typeof(TestResult<OptionalFeature.Schema>), TypeInfoPropertyName = "TestResultOptionalFeatureSchema")]
[JsonSerializable(typeof(SetResult<OptionalFeature.Schema>), TypeInfoPropertyName = "SetResultOptionalFeatureSchema")]
[JsonSerializable(typeof(IDscResource<FileSystem.Acl.Schema>), TypeInfoPropertyName = "IDscResourceFileSystemAclSchema")]
[JsonSerializable(typeof(FileSystem.Acl.Schema), TypeInfoPropertyName = "FileSystemAclSchema")]
[JsonSerializable(typeof(TestResult<FileSystem.Acl.Schema>), TypeInfoPropertyName = "TestResultFileSystemAclSchema")]
[JsonSerializable(typeof(SetResult<FileSystem.Acl.Schema>), TypeInfoPropertyName = "SetResultFileSystemAclSchema")]
[JsonSerializable(typeof(IDscResource<OpenDsc.Resource.FileSystem.File.Schema>), TypeInfoPropertyName = "IDscResourceFileSchema")]
[JsonSerializable(typeof(OpenDsc.Resource.FileSystem.File.Schema), TypeInfoPropertyName = "FileSchema")]
[JsonSerializable(typeof(TestResult<OpenDsc.Resource.FileSystem.File.Schema>), TypeInfoPropertyName = "TestResultFileSchema")]
[JsonSerializable(typeof(SetResult<OpenDsc.Resource.FileSystem.File.Schema>), TypeInfoPropertyName = "SetResultFileSchema")]
[JsonSerializable(typeof(IDscResource<OpenDsc.Resource.FileSystem.Directory.Schema>), TypeInfoPropertyName = "IDscResourceDirectorySchema")]
[JsonSerializable(typeof(OpenDsc.Resource.FileSystem.Directory.Schema), TypeInfoPropertyName = "DirectorySchema")]
[JsonSerializable(typeof(TestResult<OpenDsc.Resource.FileSystem.Directory.Schema>), TypeInfoPropertyName = "TestResultDirectorySchema")]
[JsonSerializable(typeof(SetResult<OpenDsc.Resource.FileSystem.Directory.Schema>), TypeInfoPropertyName = "SetResultDirectorySchema")]
[JsonSerializable(typeof(IDscResource<OpenDsc.Resource.Xml.Element.Schema>), TypeInfoPropertyName = "IDscResourceXmlElementSchema")]
[JsonSerializable(typeof(OpenDsc.Resource.Xml.Element.Schema), TypeInfoPropertyName = "XmlElementSchema")]
[JsonSerializable(typeof(TestResult<OpenDsc.Resource.Xml.Element.Schema>), TypeInfoPropertyName = "TestResultXmlElementSchema")]
[JsonSerializable(typeof(SetResult<OpenDsc.Resource.Xml.Element.Schema>), TypeInfoPropertyName = "SetResultXmlElementSchema")]
[JsonSerializable(typeof(Environment.Scope))]
[JsonSerializable(typeof(OptionalFeature.ResourceMetadata))]
[JsonSerializable(typeof(OptionalFeature.RestartRequired))]
[JsonSerializable(typeof(OptionalFeature.RestartRequired[]))]
[JsonSerializable(typeof(FileSystem.Acl.AccessRule))]
[JsonSerializable(typeof(FileSystem.Acl.AccessRule[]))]
[JsonSerializable(typeof(Dictionary<string, object>))]
[JsonSerializable(typeof(Dictionary<string, string>))]
[JsonSerializable(typeof(DscResourceManifest))]
[JsonSerializable(typeof(JsonElement))]
[JsonSerializable(typeof(Json.Schema.JsonSchema))]
public partial class SourceGenerationContext : JsonSerializerContext
{
}
