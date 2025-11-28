// Copyright (c) Thomas Nieto - All Rights Reserved
// You may use, distribute and modify this code under the
// terms of the MIT license.

using System.Text.Json;
using System.Text.Json.Serialization;

using OpenDsc.Resource.CommandLine;

namespace OpenDsc.Resource.Toml.KeyValue;

[JsonSourceGenerationOptions(WriteIndented = false,
                             PropertyNamingPolicy = JsonKnownNamingPolicy.CamelCase,
                             UseStringEnumConverter = true,
                             DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull,
                             Converters = [typeof(ResourceConverter<Schema>)])]
[JsonSerializable(typeof(IDscResource<Schema>))]
[JsonSerializable(typeof(Schema))]
[JsonSerializable(typeof(JsonElement))]
[JsonSerializable(typeof(object))]
[JsonSerializable(typeof(string))]
[JsonSerializable(typeof(long))]
[JsonSerializable(typeof(int))]
[JsonSerializable(typeof(double))]
[JsonSerializable(typeof(bool))]
[JsonSerializable(typeof(List<object>))]
[JsonSerializable(typeof(Dictionary<string, object>))]
internal partial class SourceGenerationContext : JsonSerializerContext
{

}
