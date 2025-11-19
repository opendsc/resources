$ErrorActionPreference = 'Stop'

Write-Host "Building TestService..." -ForegroundColor Cyan

$csproj = Join-Path $PSScriptRoot "TestService.csproj"
dotnet publish $csproj

if ($LASTEXITCODE -eq 0) {
    $exePath = Join-Path $PSScriptRoot "bin\Release\net9.0-windows\win-x64\publish\TestService.exe"
    Write-Host "Build successful!" -ForegroundColor Green
    Write-Host "Executable: $exePath" -ForegroundColor Yellow
} else {
    Write-Host "Build failed!" -ForegroundColor Red
    exit 1
}
