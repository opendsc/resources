$csproj = Get-ChildItem $PSScriptRoot\src\*.csproj
dotnet publish $csproj -c Release
if ($LASTEXITCODE -ne 0) {
    throw "Build failed with exit code $LASTEXITCODE"
}

Invoke-Pester
