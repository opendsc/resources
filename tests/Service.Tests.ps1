$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

Describe 'Service Resource' {
    BeforeAll {
        # Windows-only resource
        if (!$IsWindows) {
            return
        }

        $configuration = $env:BUILD_CONFIGURATION ?? 'Release'
        $publishPath = Join-Path $PSScriptRoot "..\src\OpenDsc.Resource.Windows\bin\$configuration\net9.0-windows\publish"
        $env:Path += ";$publishPath"
        $script:resourceType = 'OpenDsc.Windows/Service'
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
        It 'should return _exist=false for non-existent service' -Skip:(!$IsWindows) {
            $inputJson = @{
                name = 'NonExistentService_XYZ123'
            } | ConvertTo-Json -Compress

            $result = dsc resource get -r $script:resourceType --input $inputJson | ConvertFrom-Json
            $result.actualState._exist | Should -Be $false
        }

        It 'should read properties of existing service' -Skip:(!$IsWindows) {
            $inputJson = @{
                name = 'Winmgmt'  # Windows Management Instrumentation service
            } | ConvertTo-Json -Compress

            $result = dsc resource get -r $script:resourceType --input $inputJson | ConvertFrom-Json
            $result.actualState.name | Should -Be 'Winmgmt'
            $result.actualState.status | Should -Not -BeNullOrEmpty
        }
    }
}
