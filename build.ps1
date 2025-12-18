#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Builds and tests the OpenDsc resources solution.
.DESCRIPTION
    This script builds all OpenDsc resource projects and runs integration tests.
.PARAMETER Configuration
    The build configuration to use (Debug or Release). Default is Release.
.PARAMETER SkipBuild
    Skip running build.
.PARAMETER SkipTest
    Skip running tests after building.
.PARAMETER InstallDsc
    Install DSC CLI before running tests.
.PARAMETER GitHubToken
    GitHub token for API authentication to avoid rate limiting.
.EXAMPLE
    .\build.ps1
    Builds and tests the solution in Release configuration.
.EXAMPLE
    .\build.ps1 -Configuration Debug
    Builds and tests the solution in Debug configuration.
.EXAMPLE
    .\build.ps1 -SkipTest
    Builds the solution without running tests.
.EXAMPLE
    .\build.ps1 -InstallDsc
    Installs DSC CLI and runs all tests.
#>
[CmdletBinding()]
param(
    [ValidateSet('Debug', 'Release')]
    [string]$Configuration = 'Release',

    [switch]$SkipBuild,

    [switch]$SkipTest,

    [switch]$InstallDsc,

    [string]$GitHubToken
)

$ErrorActionPreference = 'Stop'

if (-not $SkipBuild) {
    Write-Host "Building OpenDsc resources..." -ForegroundColor Cyan

    $sln = Get-ChildItem $PSScriptRoot\*.slnx
    dotnet publish $sln -c $Configuration
    if ($LASTEXITCODE -ne 0) {
        throw "Build failed with exit code $LASTEXITCODE"
    }

    Write-Host "Build completed successfully!" -ForegroundColor Green
}

if ($InstallDsc) {
    if (Get-Command dsc -ErrorAction SilentlyContinue) {
        Write-Host "DSC is already installed."
    } else {
        $headers = if ($GitHubToken) { @{Authorization = "Bearer $GitHubToken"} } else { $null }
        $releases = Invoke-RestMethod -Uri 'https://api.github.com/repos/PowerShell/DSC/releases' -Headers $headers
        $release = $releases | Where-Object { $_.prerelease } | Select-Object -First 1
        if (-not $release) {
            $release = $releases | Select-Object -First 1
        }
        $tag = $release.tag_name
        $version = $tag -replace '^v', ''
        Write-Host "Latest DSC prerelease version: $version"

        if ($IsWindows) {
            $platform = "x86_64-pc-windows-msvc"
            $extension = "zip"
        } elseif ($IsLinux) {
            $platform = "x86_64-unknown-linux-gnu"
            $extension = "tar.gz"
        } elseif ($IsMacOS) {
            $platform = "aarch64-apple-darwin"
            $extension = "tar.gz"
        }

        $url = "https://github.com/PowerShell/DSC/releases/download/$tag/DSC-$version-$platform.$extension"
        $archive = "dsc.$extension"
        Invoke-WebRequest -Uri $url -OutFile $archive
        New-Item -ItemType Directory -Path ./dsc -Force | Out-Null
        if ($extension -eq "zip") {
            Expand-Archive -Path $archive -DestinationPath ./dsc
        } else {
            tar -xzf $archive -C ./dsc
            if (-not $IsWindows) {
                chmod +x ./dsc/dsc
            }
        }
        Remove-Item $archive
        $pathSeparator = if ($IsWindows) { ";" } else { ":" }
        $env:PATH += "$pathSeparator$($PSScriptRoot)/dsc"
    }
    $dscVersion = dsc --version
    Write-Host "Installed DSC version: $dscVersion"
}

if (-not $IsWindows) {
    $testExecutables = @(
        "src/OpenDsc.Resource.Windows/bin/$Configuration/net9.0-windows/win-x64/publish/OpenDsc.Resource.Windows.exe",
        "src/OpenDsc.Resource.Linux/bin/$Configuration/net9.0/linux-x64/publish/OpenDsc.Resource.Linux"
    )
    foreach ($exe in $testExecutables) {
        if (Test-Path $exe) {
            chmod +x $exe
        }
    }
}

if ($SkipTest) {
    exit 0
}

$env:BUILD_CONFIGURATION = $Configuration
Write-Host "Running tests..." -ForegroundColor Cyan
$testsPath = Join-Path $PSScriptRoot 'tests'
Invoke-Pester -Path $testsPath

