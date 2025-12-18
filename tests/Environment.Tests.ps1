Describe 'Environment Resource' {
    BeforeAll {
        # Windows-only resource
        if (!$IsWindows) {
            return
        }

        $configuration = $env:BUILD_CONFIGURATION ?? 'Release'
        $publishPath = Join-Path $PSScriptRoot "..\src\OpenDsc.Resource.CommandLine.Windows\bin\$configuration\net9.0-windows\publish"
        $env:Path += ";$publishPath"
        $script:resourceType = 'OpenDsc.Windows/Environment'
        $script:testVarName = "DscTestVar_$(Get-Random -Maximum 9999)"
    }

    AfterAll {
        if ($IsWindows) {
            [System.Environment]::SetEnvironmentVariable($script:testVarName, $null, 'User')
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
        It 'should return _exist=false for non-existent variable' -Skip:(!$IsWindows) {
            $inputJson = @{
                name = 'NonExistentVariable_12345_XYZ'
            } | ConvertTo-Json -Compress

            $result = dsc resource get -r $script:resourceType --input $inputJson | ConvertFrom-Json
            $result.actualState._exist | Should -Be $false
            $result.actualState.name | Should -Be 'NonExistentVariable_12345_XYZ'
        }
    }

    Context 'Set Operation' {
        It 'should create a new environment variable' -Skip:(!$IsWindows) {
            $inputJson = @{
                name = $script:testVarName
                value = 'TestValue123'
            } | ConvertTo-Json -Compress

            dsc resource set -r $script:resourceType --input $inputJson | Out-Null

            $verifyJson = @{
                name = $script:testVarName
            } | ConvertTo-Json -Compress

            $getResult = dsc resource get -r $script:resourceType --input $verifyJson | ConvertFrom-Json
            $getResult.actualState.value | Should -Be 'TestValue123'
        }

        AfterEach {
            [System.Environment]::SetEnvironmentVariable($script:testVarName, $null, 'User')
        }
    }
}
