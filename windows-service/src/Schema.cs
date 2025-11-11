// Copyright (c) Thomas Nieto - All Rights Reserved
// You may use, distribute and modify this code under the
// terms of the MIT license.

using System.ServiceProcess;
using System.Text.Json.Serialization;

using Json.Schema.Generation;

namespace OpenDsc.Resource.Windows.Service;

[Title("Windows Service Schema")]
[Description("Schema for managing Windows services via OpenDsc.")]
[AdditionalProperties(false)]
public sealed class Schema
{
    [Required]
    [Description("The name of the service.")]
    public string Name { get; set; } = string.Empty;

    [Description("The display name of the service.")]
    [Nullable(false)]
    public string? DisplayName { get; set; }

    [Description("The status of the service.")]
    [JsonConverter(typeof(JsonStringEnumConverter<ServiceControllerStatus>))]
    [Nullable(false)]
    public ServiceControllerStatus? Status { get; set; }

    [Description("The start type of the service.")]
    [JsonConverter(typeof(JsonStringEnumConverter<ServiceStartMode>))]
    [Nullable(false)]
    public ServiceStartMode? StartType { get; set; }

    [JsonPropertyName("_exist")]
    [Description("Indicates whether the service exists.")]
    [Nullable(false)]
    [Default(true)]
    public bool? Exist { get; set; }
}
