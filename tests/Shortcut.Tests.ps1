Describe 'Shortcut Resource' {
    BeforeAll {
        # Windows-only resource
        if (!$IsWindows) {
            return
        }

        $configuration = $env:BUILD_CONFIGURATION ?? 'Release'
        $publishPath = Join-Path $PSScriptRoot "..\src\OpenDsc.Resource.Windows\bin\$configuration\net9.0-windows\publish"
        $env:Path += ";$publishPath"
        $script:resourceType = 'OpenDsc.Windows/Shortcut'
        $script:testShortcut = Join-Path $TestDrive "TestShortcut_$(Get-Random -Maximum 9999).lnk"
    }

    AfterAll {
        if ($IsWindows -and (Test-Path $script:testShortcut)) {
            Remove-Item $script:testShortcut -Force
        }
    }

    Context 'Discovery' {
        It 'should be found by dsc' -Skip:(!$IsWindows) {
            $result = dsc resource list $script:resourceType | ConvertFrom-Json
            $result | Should -Not -BeNullOrEmpty
            if ($result -is [array]) {
                $result = $result | Where-Object { $_.type -eq $script:resourceType }
            }
            $result.type | Should -Be $script:resourceType
        }
    }

    Context 'Get Operation' {
        It 'should return _exist=false for non-existent shortcut' -Skip:(!$IsWindows) {
            $inputJson = @{
                path = Join-Path $TestDrive 'NonExistent.lnk'
            } | ConvertTo-Json -Compress

            $result = dsc resource get -r $script:resourceType --input $inputJson | ConvertFrom-Json
            $result.actualState._exist | Should -Be $false
        }
    }

    Context 'Set Operation' {
        It 'should create a new shortcut' -Skip:(!$IsWindows) {
            $inputJson = @{
                path = $script:testShortcut
                targetPath = 'C:\\Windows\\notepad.exe'
                description = 'Test shortcut'
            } | ConvertTo-Json -Compress

            dsc resource set -r $script:resourceType --input $inputJson | Out-Null

            Test-Path $script:testShortcut | Should -Be $true

            $verifyJson = @{
                path = $script:testShortcut
            } | ConvertTo-Json -Compress

            $getResult = dsc resource get -r $script:resourceType --input $verifyJson | ConvertFrom-Json
            $getResult.actualState.targetPath | Should -Be 'C:\Windows\notepad.exe'
        }

        AfterEach {
            if (Test-Path $script:testShortcut) {
                Remove-Item $script:testShortcut -Force
            }
        }
    }
}
