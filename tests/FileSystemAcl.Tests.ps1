$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

Describe 'FileSystemAcl Resource' {
    BeforeAll {
        # Windows-only resource
        if (!$IsWindows) {
            return
        }

        $configuration = $env:BUILD_CONFIGURATION ?? 'Release'
        $publishPath = Join-Path $PSScriptRoot "..\src\OpenDsc.Resource.CommandLine.Windows\bin\$configuration\net9.0-windows\publish"
        $env:Path += ";$publishPath"
        $script:resourceType = 'OpenDsc.Windows.FileSystem/AccessControlList'
        $script:testFile = Join-Path $TestDrive "TestFile_$(Get-Random -Maximum 9999).txt"
    }

    BeforeEach {
        if ($IsWindows) {
            'test content' | Out-File $script:testFile
        }
    }

    AfterEach {
        if ($IsWindows -and (Test-Path $script:testFile)) {
            Remove-Item $script:testFile -Force
        }
    }

    Context 'Discovery' {
        It 'should be found by dsc' -Skip:(!$IsWindows) {
            $result = dsc resource list $script:resourceType | ConvertFrom-Json
            $result | Should -Not -BeNullOrEmpty
            if ($result -is [array]) {
                $result = $result | Where-Object { $_.type -eq $script:resourceType } | Select-Object -First 1
            }
            $result.type | Should -Be $script:resourceType
        }
    }

    Context 'Get Operation' {
        It 'should read ACL of existing file' -Skip:(!$IsWindows) {
            $inputJson = @{
                path = $script:testFile
            } | ConvertTo-Json -Compress

            $result = dsc resource get -r $script:resourceType --input $inputJson | ConvertFrom-Json
            $result.actualState.path | Should -Be $script:testFile
            $result.actualState.accessRules | Should -Not -BeNullOrEmpty
        }

        It 'should return _exist=false for non-existent path' -Skip:(!$IsWindows) {
            $inputJson = @{
                path = Join-Path $TestDrive 'NonExistent.txt'
            } | ConvertTo-Json -Compress

            $result = dsc resource get -r $script:resourceType --input $inputJson | ConvertFrom-Json
            $result.actualState._exist | Should -Be $false
        }
    }

    Context 'Set Operation' -Skip:(!$IsWindows -or !$isAdmin) {
        It 'should add access rule to file' {
            $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name

            $inputJson = @{
                path = $script:testFile
                accessRules = @(
                    @{
                        identity = $currentUser
                        rights = 'Read'
                        type = 'Allow'
                    }
                )
            } | ConvertTo-Json -Compress

            dsc resource set -r $script:resourceType --input $inputJson | Out-Null

            $verifyJson = @{
                path = $script:testFile
            } | ConvertTo-Json -Compress

            $getResult = dsc resource get -r $script:resourceType --input $verifyJson | ConvertFrom-Json
            $getResult.actualState.accessRules | Should -Not -BeNullOrEmpty
        }
    }
}
