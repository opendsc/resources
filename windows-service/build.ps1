$csproj = Get-ChildItem $PSScriptRoot\src\*.csproj
dotnet publish $csproj

$testServicePath = Join-Path $PSScriptRoot 'tests\TestService\build.ps1'
if (Test-Path $testServicePath) {
    & $testServicePath
}

$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if ($isAdmin) {
    Invoke-Pester
} else {
    Write-Host "Running non-elevated tests only (not running as Administrator)" -ForegroundColor Yellow
    Invoke-Pester -ExcludeTag 'Elevated'
}
