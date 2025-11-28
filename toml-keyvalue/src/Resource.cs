// Copyright (c) Thomas Nieto - All Rights Reserved
// You may use, distribute and modify this code under the
// terms of the MIT license.

using System.Text.Json;
using System.Text.Json.Serialization;

using Tomlyn.Model;

namespace OpenDsc.Resource.Toml.KeyValue;

[DscResource("OpenDsc.Toml/KeyValue", Description = "Manage TOML key-value pairs", Tags = ["toml", "config", "keyvalue"])]
[ExitCode(0, Description = "Success")]
[ExitCode(1, Description = "Invalid parameter")]
[ExitCode(2, Exception = typeof(Exception), Description = "Generic error")]
[ExitCode(3, Exception = typeof(JsonException), Description = "Invalid JSON")]
[ExitCode(4, Exception = typeof(FileNotFoundException), Description = "TOML file not found")]
[ExitCode(5, Exception = typeof(FormatException), Description = "Invalid TOML format")]
[ExitCode(6, Exception = typeof(ArgumentException), Description = "Invalid argument")]
[ExitCode(7, Exception = typeof(IOException), Description = "IO error")]
public sealed class Resource(JsonSerializerContext context) : AotDscResource<Schema>(context), IGettable<Schema>, ISettable<Schema>, IDeletable<Schema>
{
    public Schema Get(Schema instance)
    {
        if (!File.Exists(instance.Path))
        {
            return new Schema()
            {
                Path = instance.Path,
                Key = instance.Key,
                Exist = false
            };
        }

        var tomlContent = File.ReadAllText(instance.Path);
        var model = Tomlyn.Toml.ToModel(tomlContent);

        var value = GetValueByKeyPath(model, instance.Key);
        if (value == null)
        {
            return new Schema()
            {
                Path = instance.Path,
                Key = instance.Key,
                Exist = false
            };
        }

        var jsonValue = ConvertTomlValueToJsonElement(value);

        return new Schema()
        {
            Path = instance.Path,
            Key = instance.Key,
            Value = jsonValue
        };
    }

    public SetResult<Schema>? Set(Schema instance)
    {
        if (!File.Exists(instance.Path))
        {
            throw new FileNotFoundException($"TOML file not found: {instance.Path}");
        }

        var tomlContent = File.ReadAllText(instance.Path);
        var model = Tomlyn.Toml.ToModel(tomlContent);

        var tomlValue = ConvertJsonElementToToml(instance.Value);
        SetValueByKeyPath(model, instance.Key, tomlValue);

        var newTomlContent = Tomlyn.Toml.FromModel(model);
        File.WriteAllText(instance.Path, newTomlContent);

        return null;
    }

    public void Delete(Schema instance)
    {
        if (!File.Exists(instance.Path))
        {
            return;
        }

        var tomlContent = File.ReadAllText(instance.Path);
        var model = Tomlyn.Toml.ToModel(tomlContent);

        DeleteValueByKeyPath(model, instance.Key);

        var newTomlContent = Tomlyn.Toml.FromModel(model);
        File.WriteAllText(instance.Path, newTomlContent);
    }

    private static object? GetValueByKeyPath(TomlTable table, string keyPath)
    {
        var keys = keyPath.Split('.');
        object? current = table;

        foreach (var key in keys)
        {
            if (current is not TomlTable currentTable)
            {
                return null;
            }

            if (!currentTable.TryGetValue(key, out var value))
            {
                return null;
            }

            current = value;
        }

        return current;
    }

    private static void SetValueByKeyPath(TomlTable table, string keyPath, object value)
    {
        var keys = keyPath.Split('.');
        var currentTable = table;

        for (int i = 0; i < keys.Length - 1; i++)
        {
            var key = keys[i];
            if (!currentTable.TryGetValue(key, out var tableValue))
            {
                var newTable = new TomlTable();
                currentTable[key] = newTable;
                currentTable = newTable;
            }
            else if (tableValue is TomlTable existingTable)
            {
                currentTable = existingTable;
            }
            else
            {
                throw new ArgumentException($"Key '{key}' exists but is not a table");
            }
        }

        currentTable[keys[^1]] = value;
    }

    private static void DeleteValueByKeyPath(TomlTable table, string keyPath)
    {
        var keys = keyPath.Split('.');
        var currentTable = table;

        for (int i = 0; i < keys.Length - 1; i++)
        {
            var key = keys[i];
            if (!currentTable.TryGetValue(key, out var tableValue) || tableValue is not TomlTable nextTable)
            {
                return;
            }

            currentTable = nextTable;
        }

        currentTable.Remove(keys[^1]);
    }

    private static JsonElement ConvertTomlValueToJsonElement(object value)
    {
        using var stream = new MemoryStream();
        using var writer = new Utf8JsonWriter(stream);

        WriteTomlValueToJson(writer, value);
        writer.Flush();

        stream.Position = 0;
        using var document = JsonDocument.Parse(stream);
        return document.RootElement.Clone();
    }

    private static void WriteTomlValueToJson(Utf8JsonWriter writer, object? value)
    {
        switch (value)
        {
            case null:
                writer.WriteNullValue();
                break;
            case long l:
                writer.WriteNumberValue(l);
                break;
            case int i:
                writer.WriteNumberValue(i);
                break;
            case double d:
                writer.WriteNumberValue(d);
                break;
            case bool b:
                writer.WriteBooleanValue(b);
                break;
            case string s:
                writer.WriteStringValue(s);
                break;
            case TomlArray arr:
                writer.WriteStartArray();
                foreach (var item in arr)
                {
                    WriteTomlValueToJson(writer, item);
                }
                writer.WriteEndArray();
                break;
            case TomlTable table:
                writer.WriteStartObject();
                foreach (var (key, val) in table)
                {
                    writer.WritePropertyName(key);
                    WriteTomlValueToJson(writer, val);
                }
                writer.WriteEndObject();
                break;
            default:
                writer.WriteStringValue(value.ToString() ?? string.Empty);
                break;
        }
    }

    private static object ConvertJsonElementToToml(JsonElement? element)
    {
        if (!element.HasValue)
        {
            return string.Empty;
        }

        var el = element.Value;
        return el.ValueKind switch
        {
            JsonValueKind.String => el.GetString() ?? string.Empty,
            JsonValueKind.Number => el.TryGetInt64(out var l) ? l : el.GetDouble(),
            JsonValueKind.True => true,
            JsonValueKind.False => false,
            JsonValueKind.Array => CreateTomlArray(el),
            JsonValueKind.Object => CreateTomlTable(el),
            _ => string.Empty
        };
    }

    private static TomlArray CreateTomlArray(JsonElement element)
    {
        var array = new TomlArray();
        foreach (var item in element.EnumerateArray())
        {
            array.Add(ConvertJsonElementToToml(item));
        }
        return array;
    }

    private static TomlTable CreateTomlTable(JsonElement element)
    {
        var table = new TomlTable();
        foreach (var prop in element.EnumerateObject())
        {
            table[prop.Name] = ConvertJsonElementToToml(prop.Value);
        }
        return table;
    }
}
