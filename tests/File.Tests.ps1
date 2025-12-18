Describe 'File Resource' {
    BeforeAll {
        # Determine executable path based on platform
        if ($IsWindows) {
            $configuration = $env:BUILD_CONFIGURATION ?? 'Release'
            $publishPath = Join-Path $PSScriptRoot "..\src\OpenDsc.Resource.CommandLine.Windows\bin\$configuration\net9.0-windows\publish"
            $exe = 'OpenDsc.Resource.CommandLine.Windows.exe'
        } else {
            $configuration = $env:BUILD_CONFIGURATION ?? 'Release'
            $publishPath = Join-Path $PSScriptRoot "..\src\OpenDsc.Resource.Linux\bin\$configuration\net9.0\publish"
            $exe = 'OpenDsc.Resource.Linux'
        }

        $env:Path += if ($IsWindows) { ";$publishPath" } else { ":$publishPath" }
        $script:resourceType = 'OpenDsc.FileSystem/File'
        $script:testDir = Join-Path ([System.IO.Path]::GetTempPath()) "DscFileTest_$(Get-Random)"
        New-Item -ItemType Directory -Path $script:testDir | Out-Null
        $script:testFile = Join-Path $script:testDir 'test.txt'
    }

    AfterAll {
        if (Test-Path $script:testDir) {
            Remove-Item -Path $script:testDir -Recurse -Force
        }
    }

    Context 'Discovery' {
        It 'should be found by dsc' {
            $result = dsc resource list $script:resourceType | ConvertFrom-Json
            $result | Should -Not -BeNullOrEmpty
            if ($result -is [array]) {
                $result = $result | Where-Object { $_.type -eq $script:resourceType } | Select-Object -First 1
            }
            $result.type | Should -Be $script:resourceType
        }

        It 'should report correct capabilities' {
            $result = dsc resource list $script:resourceType | ConvertFrom-Json
            if ($result -is [array]) {
                $result = $result | Where-Object { $_.type -eq $script:resourceType }
            }
            $result.capabilities | Should -Contain 'get'
            $result.capabilities | Should -Contain 'set'
            $result.capabilities | Should -Contain 'delete'
        }

        It 'should have a valid manifest' {
            $manifestPath = Join-Path $publishPath "OpenDsc.Resource.CommandLine.Windows.dsc.manifests.json"
            $manifestPath | Should -Exist
            $manifest = Get-Content $manifestPath | ConvertFrom-Json
            $fileManifest = $manifest.resources | Where-Object { $_.type -eq $script:resourceType }
            $fileManifest | Should -Not -BeNullOrEmpty
            $fileManifest.version | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get Operation' {
        It 'should return _exist=false for non-existent file' {
            $inputJson = @{
                path = Join-Path $script:testDir 'nonexistent.txt'
            } | ConvertTo-Json -Compress

            $result = dsc resource get -r $script:resourceType --input $inputJson | ConvertFrom-Json
            $result.actualState._exist | Should -Be $false
        }

        It 'should read properties of existing file' {
            'test content' | Out-File -FilePath $script:testFile

            $inputJson = @{
                path = $script:testFile
            } | ConvertTo-Json -Compress

            $result = dsc resource get -r $script:resourceType --input $inputJson | ConvertFrom-Json
            $result.actualState.path | Should -Be $script:testFile
            $result.actualState._exist | Should -Not -Be $false
        }

        AfterEach {
            if (Test-Path $script:testFile) {
                Remove-Item $script:testFile
            }
        }
    }

    Context 'Set Operation' {
        It 'should create a file with content' {
            $inputJson = @{
                path = $script:testFile
                content = 'Hello from DSC'
            } | ConvertTo-Json -Compress

            dsc resource set -r $script:resourceType --input $inputJson | Out-Null

            $script:testFile | Should -Exist
            Get-Content $script:testFile | Should -Be 'Hello from DSC'
        }

        It 'should update file content' {
            'initial content' | Out-File -FilePath $script:testFile

            $inputJson = @{
                path = $script:testFile
                content = 'updated content'
            } | ConvertTo-Json -Compress

            dsc resource set -r $script:resourceType --input $inputJson | Out-Null

            Get-Content $script:testFile | Should -Be 'updated content'
        }

        AfterEach {
            if (Test-Path $script:testFile) {
                Remove-Item $script:testFile
            }
        }
    }

    Context 'Delete Operation' {
        BeforeEach {
            'test content' | Out-File -FilePath $script:testFile
        }

        It 'should delete a file' {
            $inputJson = @{
                path = $script:testFile
            } | ConvertTo-Json -Compress

            dsc resource delete -r $script:resourceType --input $inputJson | Out-Null

            $script:testFile | Should -Not -Exist
        }

        AfterEach {
            if (Test-Path $script:testFile) {
                Remove-Item $script:testFile
            }
        }
    }
}
