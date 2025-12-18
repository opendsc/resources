$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

Describe 'OptionalFeature Resource' {
    BeforeAll {
        # Windows-only resource
        if (!$IsWindows) {
            return
        }

        $configuration = $env:BUILD_CONFIGURATION ?? 'Release'
        $publishPath = Join-Path $PSScriptRoot "..\src\OpenDsc.Resource.CommandLine.Windows\bin\$configuration\net9.0-windows\publish"
        $env:Path += ";$publishPath"
        $script:resourceType = 'OpenDsc.Windows/OptionalFeature'
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
        It 'should return _exist=false for non-existent feature' -Skip:(!$IsWindows -or !$isAdmin) {
            $inputJson = @{
                name = 'NonExistentFeature.XYZ123'
            } | ConvertTo-Json -Compress

            $result = dsc resource get -r $script:resourceType --input $inputJson | ConvertFrom-Json
            $result.actualState._exist | Should -Be $false
        }

        It 'should read properties of existing feature' -Skip:(!$IsWindows -or !$isAdmin) {
            # TelnetClient is a commonly available optional feature
            $inputJson = @{
                name = 'TelnetClient'
            } | ConvertTo-Json -Compress

            $result = dsc resource get -r $script:resourceType --input $inputJson | ConvertFrom-Json
            $result.actualState.name | Should -Be 'TelnetClient'
            $result.actualState.state | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Export Operation' -Skip:(!$IsWindows -or !$isAdmin) {
        It 'should export all optional features' {
            $result = dsc resource export -r $script:resourceType | ConvertFrom-Json
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -BeGreaterThan 0
        }
    }
}
