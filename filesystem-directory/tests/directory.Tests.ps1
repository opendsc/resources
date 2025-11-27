Describe 'directory' {
    BeforeAll {
        $publishPath = Join-Path $PSScriptRoot '..\src\bin\Release\net9.0\win-x64\publish'
        $env:Path += ";$publishPath"
    }

    Context 'Discovery' {
        It 'should be found by dsc' {
            $result = dsc resource list OpenDsc.FileSystem/Directory | ConvertFrom-Json
            $result | Should -Not -BeNullOrEmpty
            $result.type | Should -Be 'OpenDsc.FileSystem/Directory'
        }

        It 'should report correct capabilities' {
            $result = dsc resource list OpenDsc.FileSystem/Directory | ConvertFrom-Json
            $result.capabilities | Should -Contain 'get'
            $result.capabilities | Should -Contain 'set'
            $result.capabilities | Should -Contain 'delete'
        }

        It 'should have a valid manifest' {
            $manifest = Get-Content (Join-Path $publishPath 'directory.dsc.resource.json') | ConvertFrom-Json
            $manifest.type | Should -Be 'OpenDsc.FileSystem/Directory'
            $manifest.version | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get Operation' {
        It 'should return _exist=false for non-existent directory' {
            $testDir = Join-Path $TestDrive 'NonExistentDir'
            $inputJson = @{
                path = $testDir
            } | ConvertTo-Json -Compress

            $result = dsc resource get -r OpenDsc.FileSystem/Directory --input $inputJson | ConvertFrom-Json
            $result.actualState._exist | Should -Be $false
            $result.actualState.path | Should -Be $testDir
        }

        It 'should return _exist=true for existing directory' {
            $testDir = Join-Path $TestDrive 'ExistingDir'
            New-Item -ItemType Directory -Path $testDir | Out-Null

            $inputJson = @{
                path = $testDir
            } | ConvertTo-Json -Compress

            $result = dsc resource get -r OpenDsc.FileSystem/Directory --input $inputJson | ConvertFrom-Json
            $result.actualState.path | Should -Be $testDir
            $result.actualState._exist | Should -BeNullOrEmpty

            Remove-Item $testDir -Recurse
        }
    }

    Context 'Set Operation' {
        It 'should create a new directory' {
            $testDir = Join-Path $TestDrive 'NewDir'

            $inputJson = @{
                path = $testDir
            } | ConvertTo-Json -Compress

            dsc resource set -r OpenDsc.FileSystem/Directory --input $inputJson | Out-Null

            $verifyJson = @{
                path = $testDir
            } | ConvertTo-Json -Compress

            $getResult = dsc resource get -r OpenDsc.FileSystem/Directory --input $verifyJson | ConvertFrom-Json
            $getResult.actualState._exist | Should -BeNullOrEmpty

            Remove-Item $testDir -Recurse
        }
    }

    Context 'Delete Operation' {
        It 'should delete an existing directory' {
            $testDir = Join-Path $TestDrive 'DirToDelete'
            New-Item -ItemType Directory -Path $testDir | Out-Null

            $inputJson = @{
                path = $testDir
            } | ConvertTo-Json -Compress

            dsc resource delete -r OpenDsc.FileSystem/Directory --input $inputJson | Out-Null

            $verifyJson = @{
                path = $testDir
            } | ConvertTo-Json -Compress

            $getResult = dsc resource get -r OpenDsc.FileSystem/Directory --input $verifyJson | ConvertFrom-Json
            $getResult.actualState._exist | Should -Be $false

            # Cleanup if it still exists
            if (Test-Path $testDir) {
                Remove-Item $testDir -Recurse
            }
        }
    }
}
