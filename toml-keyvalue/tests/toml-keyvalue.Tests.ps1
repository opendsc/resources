# Copyright (c) Thomas Nieto - All Rights Reserved
# You may use, distribute and modify this code under the
# terms of the MIT license.

Describe 'toml-keyvalue' {
    BeforeAll {
        $csproj = Get-ChildItem $PSScriptRoot\..\src\*.csproj
        dotnet publish $csproj --nologo --verbosity quiet 2>&1 | Out-Null

        $publishPath = Join-Path $PSScriptRoot '..\src\bin\Release\net9.0\win-x64\publish'
        $env:DSC_RESOURCE_PATH = (Resolve-Path $publishPath).Path

        $testFile = Join-Path $TestDrive 'test.toml'
    }

    Context 'Discovery' {
        It 'should be found by dsc' {
            $resource = dsc resource list OpenDsc.Toml/KeyValue | ConvertFrom-Json
            $resource | Should -Not -BeNullOrEmpty
            $resource.type | Should -Be 'OpenDsc.Toml/KeyValue'
        }
    }

    Context 'Get Operation' {
        BeforeEach {
            $tomlContent = @'
title = "TOML Example"
version = "1.0.0"

[owner]
name = "John Doe"
email = "john@example.com"

[database]
server = "192.168.1.1"
port = 5432
enabled = true
'@
            Set-Content -Path $testFile -Value $tomlContent
        }

        It 'should return _exist=false for non-existent file' {
            $nonExistentFile = Join-Path $TestDrive 'nonexistent.toml'
            $jsonInput = @{
                path = $nonExistentFile
                key = 'title'
            } | ConvertTo-Json -Compress

            $result = dsc resource get -r OpenDsc.Toml/KeyValue --input $jsonInput | ConvertFrom-Json
            $result.actualState._exist | Should -BeFalse
        }

        It 'should return _exist=false for non-existent key' {
            $jsonInput = @{
                path = $testFile
                key = 'nonexistent.key'
            } | ConvertTo-Json -Compress

            $result = dsc resource get -r OpenDsc.Toml/KeyValue --input $jsonInput | ConvertFrom-Json
            $result.actualState._exist | Should -BeFalse
        }

        It 'should get top-level string value' {
            $jsonInput = @{
                path = $testFile
                key = 'title'
            } | ConvertTo-Json -Compress

            $result = dsc resource get -r OpenDsc.Toml/KeyValue --input $jsonInput | ConvertFrom-Json
            $result.actualState.value | Should -Be 'TOML Example'
        }

        It 'should get nested string value' {
            $jsonInput = @{
                path = $testFile
                key = 'owner.name'
            } | ConvertTo-Json -Compress

            $result = dsc resource get -r OpenDsc.Toml/KeyValue --input $jsonInput | ConvertFrom-Json
            $result.actualState.value | Should -Be 'John Doe'
        }

        It 'should get boolean value' {
            $jsonInput = @{
                path = $testFile
                key = 'database.enabled'
            } | ConvertTo-Json -Compress

            $result = dsc resource get -r OpenDsc.Toml/KeyValue --input $jsonInput | ConvertFrom-Json
            $result.actualState.value | Should -BeTrue
        }

        It 'should get integer value' {
            $jsonInput = @{
                path = $testFile
                key = 'database.port'
            } | ConvertTo-Json -Compress

            $result = dsc resource get -r OpenDsc.Toml/KeyValue --input $jsonInput | ConvertFrom-Json
            $result.actualState.value | Should -Be 5432
        }

        AfterEach {
            if (Test-Path $testFile) {
                Remove-Item $testFile -Force
            }
        }
    }

    Context 'Set Operation' {
        BeforeEach {
            $tomlContent = @'
title = "TOML Example"

[owner]
name = "John Doe"
'@
            Set-Content -Path $testFile -Value $tomlContent
        }

        It 'should create new top-level key' {
            $jsonInput = @{
                path = $testFile
                key = 'version'
                value = '2.0.0'
            } | ConvertTo-Json -Compress

            dsc resource set -r OpenDsc.Toml/KeyValue --input $jsonInput | Out-Null

            $verifyInput = @{
                path = $testFile
                key = 'version'
            } | ConvertTo-Json -Compress

            $result = dsc resource get -r OpenDsc.Toml/KeyValue --input $verifyInput | ConvertFrom-Json
            $result.actualState.value | Should -Be '2.0.0'
        }

        It 'should create nested key with new table' {
            $jsonInput = @{
                path = $testFile
                key = 'database.server'
                value = '192.168.1.1'
            } | ConvertTo-Json -Compress

            dsc resource set -r OpenDsc.Toml/KeyValue --input $jsonInput | Out-Null

            $verifyInput = @{
                path = $testFile
                key = 'database.server'
            } | ConvertTo-Json -Compress

            $result = dsc resource get -r OpenDsc.Toml/KeyValue --input $verifyInput | ConvertFrom-Json
            $result.actualState.value | Should -Be '192.168.1.1'
        }

        It 'should update existing value' {
            $jsonInput = @{
                path = $testFile
                key = 'owner.name'
                value = 'Jane Doe'
            } | ConvertTo-Json -Compress

            dsc resource set -r OpenDsc.Toml/KeyValue --input $jsonInput | Out-Null

            $verifyInput = @{
                path = $testFile
                key = 'owner.name'
            } | ConvertTo-Json -Compress

            $result = dsc resource get -r OpenDsc.Toml/KeyValue --input $verifyInput | ConvertFrom-Json
            $result.actualState.value | Should -Be 'Jane Doe'
        }

        It 'should set boolean value' {
            $jsonInput = @{
                path = $testFile
                key = 'debug'
                value = $true
            } | ConvertTo-Json -Compress

            dsc resource set -r OpenDsc.Toml/KeyValue --input $jsonInput | Out-Null

            $verifyInput = @{
                path = $testFile
                key = 'debug'
            } | ConvertTo-Json -Compress

            $result = dsc resource get -r OpenDsc.Toml/KeyValue --input $verifyInput | ConvertFrom-Json
            $result.actualState.value | Should -BeTrue
        }

        It 'should set integer value' {
            $jsonInput = @{
                path = $testFile
                key = 'timeout'
                value = 30
            } | ConvertTo-Json -Compress

            dsc resource set -r OpenDsc.Toml/KeyValue --input $jsonInput | Out-Null

            $verifyInput = @{
                path = $testFile
                key = 'timeout'
            } | ConvertTo-Json -Compress

            $result = dsc resource get -r OpenDsc.Toml/KeyValue --input $verifyInput | ConvertFrom-Json
            $result.actualState.value | Should -Be 30
        }

        AfterEach {
            if (Test-Path $testFile) {
                Remove-Item $testFile -Force
            }
        }
    }

    Context 'Delete Operation' {
        BeforeEach {
            $tomlContent = @'
title = "TOML Example"
version = "1.0.0"

[owner]
name = "John Doe"
email = "john@example.com"

[database]
server = "192.168.1.1"
'@
            Set-Content -Path $testFile -Value $tomlContent
        }

        It 'should delete top-level key' {
            $jsonInput = @{
                path = $testFile
                key = 'version'
                _exist = $false
            } | ConvertTo-Json -Compress

            dsc resource set -r OpenDsc.Toml/KeyValue --input $jsonInput | Out-Null

            $verifyInput = @{
                path = $testFile
                key = 'version'
            } | ConvertTo-Json -Compress

            $result = dsc resource get -r OpenDsc.Toml/KeyValue --input $verifyInput | ConvertFrom-Json
            $result.actualState._exist | Should -BeFalse
        }

        It 'should delete nested key' {
            $jsonInput = @{
                path = $testFile
                key = 'owner.email'
                _exist = $false
            } | ConvertTo-Json -Compress

            dsc resource set -r OpenDsc.Toml/KeyValue --input $jsonInput | Out-Null

            $verifyInput = @{
                path = $testFile
                key = 'owner.email'
            } | ConvertTo-Json -Compress

            $result = dsc resource get -r OpenDsc.Toml/KeyValue --input $verifyInput | ConvertFrom-Json
            $result.actualState._exist | Should -BeFalse
        }

        It 'should handle deleting non-existent key gracefully' {
            $jsonInput = @{
                path = $testFile
                key = 'nonexistent.key'
                _exist = $false
            } | ConvertTo-Json -Compress

            { dsc resource set -r OpenDsc.Toml/KeyValue --input $jsonInput } | Should -Not -Throw
        }

        AfterEach {
            if (Test-Path $testFile) {
                Remove-Item $testFile -Force
            }
        }
    }
}
