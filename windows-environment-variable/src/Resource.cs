// Copyright (c) Thomas Nieto - All Rights Reserved
// You may use, distribute and modify this code under the
// terms of the MIT license.

using System.Security;
using System.Text.Json;
using System.Text.Json.Serialization;

using Json.Schema;
using Json.Schema.Generation;

namespace OpenDsc.Resource.Windows.EnvironmentVariable;

[DscResource("OpenDsc.Windows/EnvironmentVariable", Description = "Manage Windows environment variables", Tags = ["windows", "environment", "variable"])]
[ExitCode(0, Description = "Success")]
[ExitCode(1, Description = "Invalid parameter")]
[ExitCode(2, Exception = typeof(Exception), Description = "Generic error")]
[ExitCode(3, Exception = typeof(JsonException), Description = "Invalid JSON")]
[ExitCode(4, Exception = typeof(SecurityException), Description = "Access denied")]
[ExitCode(5, Exception = typeof(ArgumentException), Description = "The environment variable name contains invalid characters.")]
public sealed class Resource(JsonSerializerContext context) : AotDscResource<Schema>(context), IGettable<Schema>, ISettable<Schema>, IDeletable<Schema>, IExportable<Schema>
{
    public override string GetSchema()
    {
        var config = new SchemaGeneratorConfiguration()
        {
            PropertyNameResolver = PropertyNameResolvers.CamelCase
        };

        var builder = new JsonSchemaBuilder().FromType<Schema>(config).Build();

        return JsonSerializer.Serialize(builder);
    }

    public Schema Get(Schema instance)
    {
        var target = instance.Scope is Scope.Machine ? EnvironmentVariableTarget.Machine : EnvironmentVariableTarget.User;
        var value = Environment.GetEnvironmentVariable(instance.Name, target);

        return new Schema()
        {
            Name = instance.Name,
            Value = value,
            Exist = value is not null,
            Scope = instance.Scope is Scope.Machine ? Scope.Machine : null
        };
    }

    public SetResult<Schema>? Set(Schema instance)
    {
        var target = instance.Scope is Scope.Machine ? EnvironmentVariableTarget.Machine : EnvironmentVariableTarget.User;
        Environment.SetEnvironmentVariable(instance.Name, instance.Value, target);

        return null;
    }

    public void Delete(Schema instance)
    {
        var target = instance.Scope is Scope.Machine ? EnvironmentVariableTarget.Machine : EnvironmentVariableTarget.User;
        Environment.SetEnvironmentVariable(instance.Name, null, target);
    }

    public IEnumerable<Schema> Export()
    {
        var machineVars = Environment.GetEnvironmentVariables(EnvironmentVariableTarget.Machine);
        foreach (string key in machineVars.Keys)
        {
            yield return new Schema
            {
                Name = key,
                Value = machineVars[key]?.ToString(),
                Scope = Scope.Machine
            };
        }

        var userVars = Environment.GetEnvironmentVariables(EnvironmentVariableTarget.User);
        foreach (string key in userVars.Keys)
        {
            yield return new Schema
            {
                Name = key,
                Value = userVars[key]?.ToString()
            };
        }
    }
}
