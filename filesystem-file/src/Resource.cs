// Copyright (c) Thomas Nieto - All Rights Reserved
// You may use, distribute and modify this code under the
// terms of the MIT license.

using System.Security;
using System.Text.Json;
using System.Text.Json.Serialization;

namespace OpenDsc.Resource.FileSystem.File;

[DscResource("OpenDsc.FileSystem/File", Description = "Manage files", Tags = new[] { "file", "filesystem" })]
[ExitCode(0, Description = "Success")]
[ExitCode(1, Description = "Invalid parameter")]
[ExitCode(2, Exception = typeof(Exception), Description = "Generic error")]
[ExitCode(3, Exception = typeof(JsonException), Description = "Invalid JSON")]
[ExitCode(4, Exception = typeof(SecurityException), Description = "Access denied")]
[ExitCode(5, Exception = typeof(ArgumentException), Description = "Invalid argument")]
[ExitCode(6, Exception = typeof(IOException), Description = "IO error")]
public sealed class Resource(JsonSerializerContext context) : DscResource<Schema>(context), IGettable<Schema>, ISettable<Schema>, IDeletable<Schema>
{
    public Schema Get(Schema instance)
    {
        var fullPath = Path.GetFullPath(instance.Path);
        if (System.IO.File.Exists(fullPath))
        {
            var content = System.IO.File.ReadAllText(fullPath);
            return new Schema()
            {
                Path = instance.Path,
                Content = content
            };
        }
        else
        {
            return new Schema()
            {
                Path = instance.Path,
                Exist = false
            };
        }
    }

    public SetResult<Schema>? Set(Schema instance)
    {
        var fullPath = Path.GetFullPath(instance.Path);

        if (instance.Content is not null)
        {
            System.IO.File.WriteAllText(fullPath, instance.Content);
        }
        else if (!System.IO.File.Exists(fullPath))
        {
            System.IO.File.WriteAllText(fullPath, string.Empty);
        }

        return null;
    }

    public void Delete(Schema instance)
    {
        var fullPath = Path.GetFullPath(instance.Path);
        if (System.IO.File.Exists(fullPath))
        {
            System.IO.File.Delete(fullPath);
        }
    }
}
