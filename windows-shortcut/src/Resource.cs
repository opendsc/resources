// Copyright (c) Thomas Nieto - All Rights Reserved
// You may use, distribute and modify this code under the
// terms of the MIT license.

using System.Runtime.InteropServices;
using System.Text.Json;
using System.Text.Json.Serialization;

using Json.Schema;
using Json.Schema.Generation;

namespace OpenDsc.Resource.Windows.Shortcut;

[DscResource("OpenDsc.Windows/Shortcut", Description = "Manage Windows shortcuts", Tags = ["shortcut", "windows"])]
[ExitCode(0, Description = "Success")]
[ExitCode(1, Description = "Invalid parameter")]
[ExitCode(2, Exception = typeof(Exception), Description = "Generic error")]
[ExitCode(3, Exception = typeof(JsonException), Description = "Invalid JSON")]
[ExitCode(4, Exception = typeof(InvalidOperationException), Description = "Failed to generate schema")]
[ExitCode(5, Exception = typeof(DirectoryNotFoundException), Description = "Directory not found")]
public sealed class Resource(JsonSerializerContext context) : AotDscResource<Schema>(context), IGettable<Schema>, ISettable<Schema>, IDeletable<Schema>
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
        if (!File.Exists(instance.Path))
        {
            return new Schema()
            {
                Path = instance.Path,
                Exist = false
            };
        }

        return ReadShortcut(instance.Path);
    }

    public void Delete(Schema instance)
    {
        if (File.Exists(instance.Path))
        {
            File.Delete(instance.Path);
        }
    }

    public SetResult<Schema>? Set(Schema instance)
    {
        string? directoryName = Path.GetDirectoryName(instance.Path);
        if (directoryName == null || !Directory.Exists(directoryName))
        {
            throw new DirectoryNotFoundException($"The directory for the shortcut path '{instance.Path}' does not exist.");
        }

        CreateShortcut(instance);
        return null;
    }

    private static void CreateShortcut(Schema schema)
    {
        Type? wshType = Type.GetTypeFromProgID("WScript.Shell") ?? throw new PlatformNotSupportedException("WScript.Shell COM object not available on this platform.");
        dynamic wsh = Activator.CreateInstance(wshType) ?? throw new PlatformNotSupportedException("Failed to create WScript.Shell COM object.");
        dynamic shortcut = wsh.CreateShortcut(schema.Path);

        try
        {
            if (!string.IsNullOrWhiteSpace(schema.TargetPath))
            {
                shortcut.TargetPath = schema.TargetPath;
            }

            if (!string.IsNullOrWhiteSpace(schema.Arguments))
            {
                shortcut.Arguments = schema.Arguments;
            }

            if (!string.IsNullOrWhiteSpace(schema.WorkingDirectory))
            {
                shortcut.WorkingDirectory = schema.WorkingDirectory;
            }

            if (!string.IsNullOrWhiteSpace(schema.Description))
            {
                shortcut.Description = schema.Description;
            }

            if (!string.IsNullOrWhiteSpace(schema.IconLocation))
            {
                shortcut.IconLocation = schema.IconLocation;
            }

            if (!string.IsNullOrWhiteSpace(schema.Hotkey))
            {
                shortcut.Hotkey = schema.Hotkey;
            }

            if (schema.WindowStyle.HasValue)
            {
                shortcut.WindowStyle = (int)schema.WindowStyle;
            }

            shortcut.Save();
        }
        finally
        {
            try { Marshal.FinalReleaseComObject(shortcut); } catch { }
            try { Marshal.FinalReleaseComObject(wsh); } catch { }
        }
    }

    private static Schema ReadShortcut(string path)
    {
        Type? wshType = Type.GetTypeFromProgID("WScript.Shell") ?? throw new PlatformNotSupportedException("WScript.Shell COM object not available on this platform.");
        dynamic wsh = Activator.CreateInstance(wshType) ?? throw new PlatformNotSupportedException("Failed to create WScript.Shell COM object.");
        var result = new Schema();

        dynamic shortcut = wsh.CreateShortcut(path);

        try
        {
            result.Path = path;
            result.TargetPath = string.IsNullOrWhiteSpace(shortcut.TargetPath) ? null : shortcut.TargetPath;
            result.Arguments = string.IsNullOrWhiteSpace(shortcut.Arguments) ? null : shortcut.Arguments;
            result.WorkingDirectory = string.IsNullOrWhiteSpace(shortcut.WorkingDirectory) ? null : shortcut.WorkingDirectory;
            result.Description = string.IsNullOrWhiteSpace(shortcut.Description) ? null : shortcut.Description;
            result.IconLocation = shortcut.IconLocation == Schema.DefaultIconLocation ? null : shortcut.IconLocation;
            result.Hotkey = string.IsNullOrWhiteSpace(shortcut.Hotkey) ? null : shortcut.Hotkey;
            result.WindowStyle = (WindowStyle)shortcut.WindowStyle == Enum.Parse<WindowStyle>(Schema.DefaultWindowStyle) ? null : (WindowStyle)shortcut.WindowStyle;
        }
        finally
        {
            try { Marshal.FinalReleaseComObject(shortcut); } catch { }
            try { Marshal.FinalReleaseComObject(wsh); } catch { }
        }

        return result;
    }
}
