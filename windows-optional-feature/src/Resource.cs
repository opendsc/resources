// Copyright (c) Thomas Nieto - All Rights Reserved
// You may use, distribute and modify this code under the
// terms of the MIT license.

using System.Security;
using System.Text.Json;
using System.Text.Json.Serialization;

using Json.Schema;
using Json.Schema.Generation;

namespace OpenDsc.Resource.Windows.Feature;

[DscResource("OpenDsc.Windows/Feature", Description = "Manage Windows optional features using the DISM API", Tags = ["windows", "feature", "dism"])]
[ExitCode(0, Description = "Success")]
[ExitCode(1, Description = "Invalid parameter")]
[ExitCode(2, Description = "Feature not found")]
[ExitCode(3, Exception = typeof(JsonException), Description = "Invalid JSON")]
[ExitCode(4, Exception = typeof(SecurityException), Description = "Access denied - administrator privileges required")]
[ExitCode(5, Exception = typeof(InvalidOperationException), Description = "DISM operation failed")]
public sealed class Resource(JsonSerializerContext context)
    : AotDscResource<Schema>(context),
      IGettable<Schema>,
      ISettable<Schema>,
      IDeletable<Schema>,
      IExportable<Schema>
{
    public override string GetSchema()
    {
        var config = new SchemaGeneratorConfiguration()
        {
            PropertyNameResolver = PropertyNameResolvers.CamelCase
        };

        var builder = new JsonSchemaBuilder().FromType<Schema>(config);
        builder.Schema("https://json-schema.org/draft/2020-12/schema");
        var schema = builder.Build();

        return JsonSerializer.Serialize(schema);
    }

    public Schema Get(Schema instance)
    {
        var (schema, _) = DismHelper.GetFeature(instance.Name, instance.IncludeAllSubFeatures, instance.Source);
        return schema;
    }

    public SetResult<Schema>? Set(Schema instance)
    {
        var beforeState = Get(instance);
        var desiredExist = instance.Exist ?? true;

        if (beforeState.Exist == desiredExist)
        {
            return null;
        }

        DismRestartType restartType;
        if (desiredExist)
        {
            var enableAll = instance.IncludeAllSubFeatures ?? false;
            restartType = DismHelper.EnableFeature(instance.Name, enableAll, instance.Source);
        }
        else
        {
            restartType = DismHelper.DisableFeature(instance.Name);
        }

        var afterState = Get(instance);

        if (restartType == DismRestartType.Required || restartType == DismRestartType.Possible)
        {
            afterState.Metadata = new Dictionary<string, object>
            {
                ["_restartRequired"] = new[] { new { system = Environment.MachineName } }
            };
        }

        return new SetResult<Schema>(afterState);
    }

    public void Delete(Schema instance)
    {
        _ = DismHelper.DisableFeature(instance.Name);
    }

    public IEnumerable<Schema> Export()
    {
        return DismHelper.EnumerateFeatures();
    }
}
