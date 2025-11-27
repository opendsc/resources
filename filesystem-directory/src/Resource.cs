// Copyright (c) Thomas Nieto - All Rights Reserved
// You may use, distribute and modify this code under the
// terms of the MIT license.

using System.Security;
using System.Text.Json;
using System.Text.Json.Serialization;

namespace OpenDsc.Resource.FileSystem.Directory;

[DscResource("OpenDsc.FileSystem/Directory", Description = "Manage directories", Tags = new[] { "directory", "filesystem" })]
[ExitCode(0, Description = "Success")]
[ExitCode(1, Description = "Invalid parameter")]
[ExitCode(2, Exception = typeof(Exception), Description = "Generic error")]
[ExitCode(3, Exception = typeof(JsonException), Description = "Invalid JSON")]
[ExitCode(4, Exception = typeof(SecurityException), Description = "Access denied")]
[ExitCode(5, Exception = typeof(ArgumentException), Description = "Invalid argument")]
[ExitCode(6, Exception = typeof(IOException), Description = "IO error")]
public sealed class Resource(JsonSerializerContext context) : AotDscResource<Schema>(context), IGettable<Schema>, ISettable<Schema>, IDeletable<Schema>
{
    public Schema Get(Schema instance)
    {
        var fullPath = Path.GetFullPath(instance.Path);
        if (System.IO.Directory.Exists(fullPath))
        {
            return new Schema()
            {
                Path = instance.Path
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

        if (!System.IO.Directory.Exists(fullPath))
        {
            System.IO.Directory.CreateDirectory(fullPath);
        }

        return null;
    }

    public void Delete(Schema instance)
    {
        var fullPath = Path.GetFullPath(instance.Path);
        if (System.IO.Directory.Exists(fullPath))
        {
            System.IO.Directory.Delete(fullPath);
        }
    }
}
