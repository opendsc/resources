$csproj = Get-ChildItem $PSScriptRoot\src\*.csproj
dotnet publish $csproj
Invoke-Pester
