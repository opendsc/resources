$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

Describe 'User Resource' {
    BeforeAll {
        # Windows-only resource
        if (!$IsWindows) {
            return
        }

        $configuration = $env:BUILD_CONFIGURATION ?? 'Release'
        $publishPath = Join-Path $PSScriptRoot "..\src\OpenDsc.Resource.CommandLine.Windows\bin\$configuration\net9.0-windows\publish"
        $env:Path += ";$publishPath"
        $script:resourceType = 'OpenDsc.Windows/User'
        $script:testUser1 = "DscTestUser_$(Get-Random -Maximum 9999)"
        $script:testPassword = "P@ssw0rd_$(Get-Random -Maximum 9999)!"
    }

    AfterAll {
        if ($IsWindows -and $isAdmin) {
            Get-LocalUser -Name DscTestUser* -ErrorAction SilentlyContinue | Remove-LocalUser
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

    Context 'Get Operation - Non-Elevated' {
        It 'should return _exist=false for non-existent user' -Skip:(!$IsWindows) {
            $inputJson = @{
                userName = 'NonExistUser99'
            } | ConvertTo-Json -Compress

            $result = dsc resource get -r $script:resourceType --input $inputJson | ConvertFrom-Json
            $result.actualState._exist | Should -Be $false
            $result.actualState.userName | Should -Be 'NonExistUser99'
        }
    }

    Context 'Set Operation' -Skip:(!$IsWindows -or !$isAdmin) {
        It 'should create a new user' {
            $inputJson = @{
                userName = $script:testUser1
                password = $script:testPassword
                description = 'Test user created by Pester'
            } | ConvertTo-Json -Compress

            dsc resource set -r $script:resourceType --input $inputJson | Out-Null

            $verifyJson = @{
                userName = $script:testUser1
            } | ConvertTo-Json -Compress

            $getResult = dsc resource get -r $script:resourceType --input $verifyJson | ConvertFrom-Json
            $getResult.actualState.userName | Should -Be $script:testUser1
            $getResult.actualState.description | Should -Be 'Test user created by Pester'
        }

        AfterEach {
            Get-LocalUser -Name $script:testUser1 -ErrorAction SilentlyContinue | Remove-LocalUser
        }
    }
}
