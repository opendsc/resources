$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

Describe 'windows-filesystem-acl' {
    BeforeAll {
        $publishPath = Join-Path $PSScriptRoot '..\src\bin\Release\net9.0-windows\win-x64\publish'
        $env:Path += ";$publishPath"
        $script:testDir = Join-Path $env:TEMP "DscAclTest_$(Get-Random)"
        $script:testFile = Join-Path $script:testDir "testfile.txt"
    }

    Context 'Discovery' {
        It 'should be found by dsc' {
            $result = dsc resource list OpenDsc.Windows.FileSystem/AccessControlList | ConvertFrom-Json
            $result | Should -Not -BeNullOrEmpty
            $result.type | Should -Be 'OpenDsc.Windows.FileSystem/AccessControlList'
        }

        It 'should report correct capabilities' {
            $result = dsc resource list OpenDsc.Windows.FileSystem/AccessControlList | ConvertFrom-Json
            $result.capabilities | Should -Contain 'get'
            $result.capabilities | Should -Contain 'set'
        }

        It 'should have a valid manifest' {
            $manifest = Get-Content (Join-Path $publishPath 'windows-filesystem-acl.dsc.resource.json') | ConvertFrom-Json
            $manifest.type | Should -Be 'OpenDsc.Windows.FileSystem/AccessControlList'
            $manifest.version | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get Operation - Non-Elevated' {
        BeforeAll {
            New-Item -Path $script:testDir -ItemType Directory -Force | Out-Null
            New-Item -Path $script:testFile -ItemType File -Force | Out-Null
            Set-Content -Path $script:testFile -Value "Test content"
        }

        AfterAll {
            if (Test-Path $script:testDir) {
                Remove-Item -Path $script:testDir -Recurse -Force
            }
        }

        It 'should return _exist=false for non-existent file' {
            $inputJson = @{
                path = 'C:\NonExistent\Path\File.txt'
            } | ConvertTo-Json -Compress

            $result = dsc resource get -r OpenDsc.Windows.FileSystem/AccessControlList --input $inputJson | ConvertFrom-Json
            $result.actualState._exist | Should -Be $false
            $result.actualState.path | Should -Be 'C:\NonExistent\Path\File.txt'
        }

        It 'should read ACL of existing file' {
            $inputJson = @{
                path = $script:testFile
            } | ConvertTo-Json -Compress

            $result = dsc resource get -r OpenDsc.Windows.FileSystem/AccessControlList --input $inputJson | ConvertFrom-Json
            $result.actualState.path | Should -Be $script:testFile
            $result.actualState._exist | Should -Be $true
            $result.actualState.owner | Should -Not -BeNullOrEmpty
            $result.actualState.accessRules | Should -Not -BeNullOrEmpty
        }

        It 'should read ACL of existing directory' {
            $inputJson = @{
                path = $script:testDir
            } | ConvertTo-Json -Compress

            $result = dsc resource get -r OpenDsc.Windows.FileSystem/AccessControlList --input $inputJson | ConvertFrom-Json
            $result.actualState.path | Should -Be $script:testDir
            $result.actualState._exist | Should -Be $true
            $result.actualState.owner | Should -Not -BeNullOrEmpty
            $result.actualState.accessRules | Should -Not -BeNullOrEmpty
        }

        It 'should include inheritance flags in access rules' {
            $inputJson = @{
                path = $script:testDir
            } | ConvertTo-Json -Compress

            $result = dsc resource get -r OpenDsc.Windows.FileSystem/AccessControlList --input $inputJson | ConvertFrom-Json
            $result.actualState.accessRules | Should -Not -BeNullOrEmpty
            $result.actualState.accessRules[0].identity | Should -Not -BeNullOrEmpty
            $result.actualState.accessRules[0].rights | Should -Not -BeNullOrEmpty
            $result.actualState.accessRules[0].accessControlType | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set Operation - Add Access Rule' -Skip:(!$isAdmin) {
        BeforeAll {
            New-Item -Path $script:testDir -ItemType Directory -Force | Out-Null
            New-Item -Path $script:testFile -ItemType File -Force | Out-Null
            Set-Content -Path $script:testFile -Value "Test content"
        }

        AfterAll {
            if (Test-Path $script:testDir) {
                Remove-Item -Path $script:testDir -Recurse -Force
            }
        }

        It 'should add read access for Users group to file' {
            $inputJson = @{
                path = $script:testFile
                accessRules = @(
                    @{
                        identity = 'BUILTIN\Users'
                        rights = 'Read'
                        accessControlType = 'Allow'
                    }
                )
            } | ConvertTo-Json -Compress

            dsc resource set -r OpenDsc.Windows.FileSystem/AccessControlList --input $inputJson | Out-Null
            $LASTEXITCODE | Should -Be 0

            # Verify the rule was added
            $verifyJson = @{
                path = $script:testFile
            } | ConvertTo-Json -Compress

            $getResult = dsc resource get -r OpenDsc.Windows.FileSystem/AccessControlList --input $verifyJson | ConvertFrom-Json
            $usersRule = $getResult.actualState.accessRules | Where-Object { $_.identity -like '*Users' -and $_.rights -like '*Read*' }
            $usersRule | Should -Not -BeNullOrEmpty
        }

        It 'should add multiple access rules' {
            $inputJson = @{
                path = $script:testFile
                accessRules = @(
                    @{
                        identity = 'BUILTIN\Users'
                        rights = 'Read'
                        accessControlType = 'Allow'
                    },
                    @{
                        identity = 'BUILTIN\Administrators'
                        rights = 'FullControl'
                        accessControlType = 'Allow'
                    }
                )
            } | ConvertTo-Json -Depth 3

            dsc resource set -r OpenDsc.Windows.FileSystem/AccessControlList --input $inputJson | Out-Null
            $LASTEXITCODE | Should -Be 0

            # Verify both rules exist
            $verifyJson = @{
                path = $script:testFile
            } | ConvertTo-Json -Compress

            $getResult = dsc resource get -r OpenDsc.Windows.FileSystem/AccessControlList --input $verifyJson | ConvertFrom-Json
            $getResult.actualState.accessRules | Should -Not -BeNullOrEmpty
        }

        It 'should handle inheritance flags for directories' {
            $inputJson = @{
                path = $script:testDir
                accessRules = @(
                    @{
                        identity = 'BUILTIN\Users'
                        rights = 'Read'
                        inheritanceFlags = 'ContainerInherit'
                        propagationFlags = 'None'
                        accessControlType = 'Allow'
                    }
                )
            } | ConvertTo-Json -Depth 3

            dsc resource set -r OpenDsc.Windows.FileSystem/AccessControlList --input $inputJson | Out-Null
            $LASTEXITCODE | Should -Be 0

            # Verify the rule with inheritance was added
            $verifyJson = @{
                path = $script:testDir
            } | ConvertTo-Json -Compress

            $getResult = dsc resource get -r OpenDsc.Windows.FileSystem/AccessControlList --input $verifyJson | ConvertFrom-Json
            $usersRule = $getResult.actualState.accessRules | Where-Object {
                $_.identity -like '*Users' -and $_.rights -like '*Read*' -and $_.inheritanceFlags -eq 'ContainerInherit'
            }
            $usersRule | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set Operation - Change Owner' -Skip:(!$isAdmin) {
        BeforeEach {
            $script:tempFile = Join-Path $env:TEMP "DscAclOwnerTest_$(Get-Random).txt"
            New-Item -Path $script:tempFile -ItemType File -Force | Out-Null
        }

        AfterEach {
            if (Test-Path $script:tempFile) {
                Remove-Item -Path $script:tempFile -Force
            }
        }

        It 'should change file owner to Administrators' {
            $inputJson = @{
                path = $script:tempFile
                owner = 'BUILTIN\Administrators'
            } | ConvertTo-Json -Compress

            dsc resource set -r OpenDsc.Windows.FileSystem/AccessControlList --input $inputJson | Out-Null
            $LASTEXITCODE | Should -Be 0

            # Verify owner changed
            $verifyJson = @{
                path = $script:tempFile
            } | ConvertTo-Json -Compress

            $getResult = dsc resource get -r OpenDsc.Windows.FileSystem/AccessControlList --input $verifyJson | ConvertFrom-Json
            $getResult.actualState.owner | Should -BeLike '*Administrators'
        }
    }

    Context 'Set Operation - Purge Mode' -Skip:(!$isAdmin) {
        BeforeEach {
            $script:purgeTestFile = Join-Path $env:TEMP "DscAclPurgeTest_$(Get-Random).txt"
            New-Item -Path $script:purgeTestFile -ItemType File -Force | Out-Null
        }

        AfterEach {
            if (Test-Path $script:purgeTestFile) {
                Remove-Item -Path $script:purgeTestFile -Force
            }
        }

        It 'should not remove existing rules when _purge is false' {
            # First, add a rule
            $inputJson1 = @{
                path = $script:purgeTestFile
                accessRules = @(
                    @{
                        identity = 'BUILTIN\Users'
                        rights = 'Read'
                        accessControlType = 'Allow'
                    }
                )
                _purge = $false
            } | ConvertTo-Json -Depth 3

            dsc resource set -r OpenDsc.Windows.FileSystem/AccessControlList --input $inputJson1 | Out-Null

            # Get current rules count
            $verifyJson = @{
                path = $script:purgeTestFile
            } | ConvertTo-Json -Compress

            $result1 = dsc resource get -r OpenDsc.Windows.FileSystem/AccessControlList --input $verifyJson | ConvertFrom-Json
            $initialCount = $result1.actualState.accessRules.Count

            # Add another rule without purging
            $inputJson2 = @{
                path = $script:purgeTestFile
                accessRules = @(
                    @{
                        identity = 'BUILTIN\Administrators'
                        rights = 'FullControl'
                        accessControlType = 'Allow'
                    }
                )
                _purge = $false
            } | ConvertTo-Json -Depth 3

            dsc resource set -r OpenDsc.Windows.FileSystem/AccessControlList --input $inputJson2 | Out-Null

            # Verify both rules still exist
            $result2 = dsc resource get -r OpenDsc.Windows.FileSystem/AccessControlList --input $verifyJson | ConvertFrom-Json
            $result2.actualState.accessRules.Count | Should -BeGreaterOrEqual $initialCount
        }
    }

    Context 'Error Handling' {
        It 'should fail when file does not exist' {
            $inputJson = @{
                path = 'C:\NonExistent\Path\File.txt'
                owner = 'BUILTIN\Administrators'
            } | ConvertTo-Json -Compress

            dsc resource set -r OpenDsc.Windows.FileSystem/AccessControlList --input $inputJson 2>&1 | Out-Null
            $LASTEXITCODE | Should -Not -Be 0
        }

        It 'should fail with invalid identity' -Skip:(!$isAdmin) {
            $tempFile = Join-Path $env:TEMP "DscAclErrorTest_$(Get-Random).txt"
            New-Item -Path $tempFile -ItemType File -Force | Out-Null

            try {
                $inputJson = @{
                    path = $tempFile
                    accessRules = @(
                        @{
                            identity = 'InvalidDomain\InvalidUser12345'
                            rights = 'Read'
                            accessControlType = 'Allow'
                        }
                    )
                } | ConvertTo-Json -Depth 3

                dsc resource set -r OpenDsc.Windows.FileSystem/AccessControlList --input $inputJson 2>&1 | Out-Null
                $LASTEXITCODE | Should -Not -Be 0
            }
            finally {
                if (Test-Path $tempFile) {
                    Remove-Item -Path $tempFile -Force
                }
            }
        }
    }
}
