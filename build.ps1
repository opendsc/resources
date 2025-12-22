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
.EXAMPLE
    .\build.ps1 -Portable
    Builds a self-contained portable version with embedded .NET runtime.
.EXAMPLE
    .\build.ps1 -Msi
    Builds the MSI installer package.
#>
[CmdletBinding()]
param(
    [ValidateSet('Debug', 'Release')]
    [string]$Configuration = 'Release',

    [switch]$SkipBuild,

    [switch]$SkipTest,

    [switch]$InstallDsc,

    [switch]$Portable,

    [switch]$Msi,

    [string]$GitHubToken
)

$ErrorActionPreference = 'Stop'

if (-not $SkipBuild) {
    Write-Host "Building OpenDsc resources..." -ForegroundColor Cyan

    $publishDir = Join-Path $PSScriptRoot "artifacts\publish"
    New-Item -ItemType Directory -Path $publishDir -Force | Out-Null

    if ($Portable) {
        $version = ([xml](Get-Content (Join-Path $PSScriptRoot "Directory.Build.props"))).Project.PropertyGroup.Version
    }

    if ($IsWindows) {
        $windowsProj = Join-Path $PSScriptRoot "src\OpenDsc.Resource.CommandLine.Windows\OpenDsc.Resource.CommandLine.Windows.csproj"
        if (Test-Path $windowsProj) {
            dotnet publish $windowsProj -c $Configuration -o $publishDir
            if ($LASTEXITCODE -ne 0) {
                throw "Build failed for OpenDsc.Resource.CommandLine.Windows with exit code $LASTEXITCODE"
            }

            if ($Portable) {
                Write-Host "Building self-contained portable version..." -ForegroundColor Cyan
                $portableDir = Join-Path $PSScriptRoot "artifacts\portable"
                New-Item -ItemType Directory -Path $portableDir -Force | Out-Null
                dotnet publish $windowsProj `
                    --configuration $Configuration `
                    --runtime win-x64 `
                    --self-contained true `
                    -p:PublishSingleFile=true `
                    -p:IncludeNativeLibrariesForSelfExtract=true `
                    -p:EnableCompressionInSingleFile=false `
                    -p:DebugType=None `
                    -p:DebugSymbols=false `
                    --output $portableDir
                if ($LASTEXITCODE -ne 0) {
                    throw "Portable build failed for OpenDsc.Resource.CommandLine.Windows with exit code $LASTEXITCODE"
                }

                Write-Host "Creating portable ZIP archive..." -ForegroundColor Cyan
                $zipDir = Join-Path $PSScriptRoot "artifacts\zip"
                New-Item -ItemType Directory -Path $zipDir -Force | Out-Null
                $zipPath = Join-Path $zipDir "OpenDSC.Resources.Windows.Portable-$version.zip"
                Compress-Archive -Path "$portableDir\*" -DestinationPath $zipPath -Force
                Write-Host "Self-contained portable version built successfully!" -ForegroundColor Green
                Write-Host "Output location: $portableDir" -ForegroundColor Green
                Write-Host "ZIP archive: $zipPath" -ForegroundColor Green
            }
        }

        if ($Msi) {
            Write-Host "Building MSI installer..." -ForegroundColor Cyan
            $wixProj = Join-Path $PSScriptRoot "packaging\msi\OpenDsc.Resources\OpenDsc.Resources.wixproj"
            if (Test-Path $wixProj) {
                dotnet build $wixProj -c $Configuration
                if ($LASTEXITCODE -ne 0) {
                    throw "Build failed for MSI installer with exit code $LASTEXITCODE"
                }
                $msiDir = Join-Path $PSScriptRoot "artifacts\msi"
                Write-Host "MSI installer built successfully!" -ForegroundColor Green
                Write-Host "Output location: $msiDir" -ForegroundColor Green
            }
        }

        Write-Host "Building TestService..." -ForegroundColor Cyan
        $testServiceProj = Join-Path $PSScriptRoot "tests\TestService\TestService.csproj"
        if (Test-Path $testServiceProj) {
            dotnet publish $testServiceProj -c $Configuration
            if ($LASTEXITCODE -ne 0) {
                throw "Build failed for TestService with exit code $LASTEXITCODE"
            }
        }
    } elseif ($IsLinux) {
        $linuxProj = Join-Path $PSScriptRoot "src\OpenDsc.Resource.CommandLine.Linux\OpenDsc.Resource.CommandLine.Linux.csproj"
        if (Test-Path $linuxProj) {
            dotnet publish $linuxProj -c $Configuration -o $publishDir
            if ($LASTEXITCODE -ne 0) {
                throw "Build failed for OpenDsc.Resource.CommandLine.Linux with exit code $LASTEXITCODE"
            }
        }

        if ($Portable) {
            Write-Host "Building self-contained portable version for Linux..." -ForegroundColor Cyan
            $portableLinuxDir = Join-Path $PSScriptRoot "artifacts\portable"
            New-Item -ItemType Directory -Path $portableLinuxDir -Force | Out-Null
            dotnet publish $linuxProj `
                --configuration $Configuration `
                --runtime linux-x64 `
                --self-contained true `
                -p:PublishSingleFile=true `
                -p:IncludeNativeLibrariesForSelfExtract=true `
                -p:EnableCompressionInSingleFile=false `
                -p:DebugType=None `
                -p:DebugSymbols=false `
                --output $portableLinuxDir
            if ($LASTEXITCODE -ne 0) {
                throw "Portable build failed for OpenDsc.Resource.CommandLine.Linux with exit code $LASTEXITCODE"
            }

            Write-Host "Creating portable ZIP archive for Linux..." -ForegroundColor Cyan
            $zipDir = Join-Path $PSScriptRoot "artifacts\zip"
            New-Item -ItemType Directory -Path $zipDir -Force | Out-Null
            $zipPath = Join-Path $zipDir "OpenDSC.Resources.Linux.Portable-$version.zip"
            Compress-Archive -Path "$portableLinuxDir\*" -DestinationPath $zipPath -Force
            Write-Host "Self-contained portable version for Linux built successfully!" -ForegroundColor Green
            Write-Host "Output location: $portableLinuxDir" -ForegroundColor Green
            Write-Host "ZIP archive: $zipPath" -ForegroundColor Green
        }
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
            $platform = "x86_64-linux"
            $extension = "tar.gz"
        } elseif ($IsMacOS) {
            $platform = "osx-arm64"
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

if ($SkipTest) {
    exit 0
}

$env:BUILD_CONFIGURATION = $Configuration

$publishDir = Join-Path $PSScriptRoot "publish"
if (Test-Path $publishDir) {
    $env:DSC_RESOURCE_PATH = $publishDir
}

Write-Host "Running tests..." -ForegroundColor Cyan

$testsPath = Join-Path $PSScriptRoot 'tests'
Invoke-Pester -Path $testsPath
