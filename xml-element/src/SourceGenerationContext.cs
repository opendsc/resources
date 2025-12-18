// Copyright (c) Thomas Nieto - All Rights Reserved
// You may use, distribute and modify this code under the
// terms of the MIT license.

using System.Text.Json.Serialization;

using OpenDsc.Resource.CommandLine;

namespace OpenDsc.Resource.Xml.Element;

[JsonSourceGenerationOptions(WriteIndented = false,
                             PropertyNamingPolicy = JsonKnownNamingPolicy.CamelCase,
                             UseStringEnumConverter = true,
                             DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull)]
[JsonSerializable(typeof(IDscResource<Schema>))]
[JsonSerializable(typeof(Schema))]
[JsonSerializable(typeof(TestResult<Schema>))]
[JsonSerializable(typeof(SetResult<Schema>))]
[JsonSerializable(typeof(Dictionary<string, string>))]
internal partial class SourceGenerationContext : JsonSerializerContext
{

}
