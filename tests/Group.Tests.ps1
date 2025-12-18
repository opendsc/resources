$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

Describe 'Group Resource' {
    BeforeAll {
        # Determine executable path based on platform
        if ($IsWindows) {
            $configuration = $env:BUILD_CONFIGURATION ?? 'Release'
            $publishPath = Join-Path $PSScriptRoot "..\src\OpenDsc.Resource.CommandLine.Windows\bin\$configuration\net9.0-windows\publish"
        } else {
            # Linux tests would skip Group resource as it's Windows-only
            return
        }

        $env:Path += ";$publishPath"
        $script:resourceType = 'OpenDsc.Windows/Group'
        $script:testGroup1 = "DscTestGroup_$(Get-Random -Maximum 9999)"
        $script:testGroup2 = "DscTestGroup_$(Get-Random -Maximum 9999)"
        $script:testUser1 = "DscTestUser_$(Get-Random -Maximum 9999)"
    }

    AfterAll {
        if ($IsWindows) {
            Get-LocalUser -Name DscTestUser* -ErrorAction SilentlyContinue | Remove-LocalUser
            Get-LocalGroup -Name DscTestGroup* -ErrorAction SilentlyContinue | Remove-LocalGroup
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
            $result.capabilities | Should -Contain 'export'
        }

        It 'should have a valid manifest' {
            $manifestPath = Join-Path $publishPath "OpenDsc.Resource.CommandLine.Windows.dsc.manifests.json"
            $manifestPath | Should -Exist
            $manifest = Get-Content $manifestPath | ConvertFrom-Json
            $groupManifest = $manifest.resources | Where-Object { $_.type -eq $script:resourceType }
            $groupManifest | Should -Not -BeNullOrEmpty
            $groupManifest.version | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get Operation - Non-Elevated' {
        It 'should return _exist=false for non-existent group' {
            $inputJson = @{
                groupName = 'NonExistentGroup_XYZ123'
            } | ConvertTo-Json -Compress

            $result = dsc resource get -r $script:resourceType --input $inputJson | ConvertFrom-Json
            $result.actualState._exist | Should -Be $false
            $result.actualState.groupName | Should -Be 'NonExistentGroup_XYZ123'
        }

        It 'should read properties of existing group' {
            $inputJson = @{
                groupName = 'Administrators'
            } | ConvertTo-Json -Compress

            $result = dsc resource get -r $script:resourceType --input $inputJson | ConvertFrom-Json
            $result.actualState.groupName | Should -Be 'Administrators'
            $result.actualState._exist | Should -Not -Be $false
        }
    }

    Context 'Set Operation' -Skip:(!$isAdmin) {
        It 'should create a group' {
            $inputJson = @{
                groupName = $script:testGroup1
                description = 'Test group created by DSC'
            } | ConvertTo-Json -Compress

            dsc resource set -r $script:resourceType --input $inputJson | Out-Null

            $verifyJson = @{
                groupName = $script:testGroup1
            } | ConvertTo-Json -Compress

            $result = dsc resource get -r $script:resourceType --input $verifyJson | ConvertFrom-Json
            $result.actualState.groupName | Should -Be $script:testGroup1
            $result.actualState.description | Should -Be 'Test group created by DSC'
        }

        AfterEach {
            Get-LocalGroup -Name $script:testGroup* -ErrorAction SilentlyContinue | Remove-LocalGroup
        }
    }

    Context 'Delete Operation' -Skip:(!$isAdmin) {
        BeforeEach {
            $null = New-LocalGroup -Name $script:testGroup1 -Description 'Test group'
        }

        It 'should delete a group' {
            $inputJson = @{
                groupName = $script:testGroup1
            } | ConvertTo-Json -Compress

            dsc resource delete -r $script:resourceType --input $inputJson | Out-Null

            Get-LocalGroup -Name $script:testGroup1 -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
        }

        AfterEach {
            Get-LocalGroup -Name $script:testGroup* -ErrorAction SilentlyContinue | Remove-LocalGroup
        }
    }
}
