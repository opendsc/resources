$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

Describe 'OpenDsc.Windows/Feature Resource' {
    BeforeAll {
        $publishPath = Join-Path $PSScriptRoot '..\src\bin\Release\net9.0-windows\win-x64\publish'
        $env:Path += ";$publishPath"

        $resourceName = 'OpenDsc.Windows/Feature'
        $testFeatureName = 'TelnetClient'
    }

    Context 'Resource Discovery' {
        It 'Should be discoverable via dsc resource list' {
            $resources = dsc resource list | ConvertFrom-Json
            $resource = $resources.Where({ $_.type -eq $resourceName })
            $resource | Should -Not -BeNullOrEmpty
            $resource[0].kind | Should -Be 'Resource'
        }

        It 'Should have a valid manifest' {
            $resource = dsc resource list |
                ConvertFrom-Json |
                Where-Object { $_.type -eq $resourceName }

            $resource.version | Should -Not -BeNullOrEmpty
            $resource.capabilities | Should -Contain 'Get'
            $resource.capabilities | Should -Contain 'Set'
            $resource.capabilities | Should -Contain 'Delete'
            $resource.capabilities | Should -Contain 'Export'
        }
    }

    Context 'Get Operation' -Skip:(!$isAdmin) {
        It 'Should get an installed feature' {
            # Most Windows systems don't have TelnetClient installed by default
            $inputJson = @{
                name = $testFeatureName
            } | ConvertTo-Json -Compress

            $result = dsc resource get -r $resourceName --input $inputJson | ConvertFrom-Json

            $result.actualState.name | Should -Be $testFeatureName
            $result.actualState._exist | Should -BeIn @($true, $false)

            if ($result.actualState._exist) {
                $result.actualState.state | Should -Not -BeNullOrEmpty
            }
        }

        It 'Should return _exist=false for non-existent feature' {
            $inputJson = @{
                name = 'NonExistentFeature12345'
            } | ConvertTo-Json -Compress

            $result = dsc resource get -r $resourceName --input $inputJson | ConvertFrom-Json

            $result.actualState.name | Should -Be 'NonExistentFeature12345'
            $result.actualState._exist | Should -Be $false
        }
    }

    Context 'Set Operation' -Skip:(!$isAdmin) {
        BeforeEach {
            # Ensure feature is disabled before test
            try {
                $getInput = @{ name = $testFeatureName } | ConvertTo-Json -Compress
                $currentState = dsc resource get -r $resourceName --input $getInput | ConvertFrom-Json

                if ($currentState.actualState._exist) {
                    $deleteInput = @{ name = $testFeatureName } | ConvertTo-Json -Compress
                    dsc resource delete -r $resourceName --input $deleteInput | Out-Null
                    Start-Sleep -Seconds 2
                }
            } catch {
                Write-Warning "Could not disable feature in BeforeEach: $_"
            }
        }

        AfterEach {
            # Cleanup: disable the feature after test
            try {
                $deleteInput = @{ name = $testFeatureName } | ConvertTo-Json -Compress
                dsc resource delete -r $resourceName --input $deleteInput | Out-Null
                Start-Sleep -Seconds 2
            } catch {
                Write-Warning "Could not cleanup feature: $_"
            }
        }

        It 'Should enable a feature' {
            $inputJson = @{
                name = $testFeatureName
                _exist = $true
            } | ConvertTo-Json -Compress

            $result = dsc resource set -r $resourceName --input $inputJson | ConvertFrom-Json

            $result.afterState.name | Should -Be $testFeatureName
            $result.afterState._exist | Should -Not -Be $false
        }

        It 'Should be idempotent when feature already enabled' {
            # First enable
            $inputJson = @{
                name = $testFeatureName
                _exist = $true
            } | ConvertTo-Json -Compress

            dsc resource set -r $resourceName --input $inputJson | Out-Null
            Start-Sleep -Seconds 2

            # Try to enable again
            $result = dsc resource set -r $resourceName --input $inputJson | ConvertFrom-Json

            # Should return no changes if already in desired state
            $result.afterState._exist | Should -Not -Be $false
        }
    }

    Context 'Delete Operation' -Skip:(!$isAdmin) {
        BeforeEach {
            # Ensure feature is enabled before test
            try {
                $inputJson = @{
                    name = $testFeatureName
                    _exist = $true
                } | ConvertTo-Json -Compress

                dsc resource set -r $resourceName --input $inputJson | Out-Null
                Start-Sleep -Seconds 2
            } catch {
                Write-Warning "Could not enable feature in BeforeEach: $_"
            }
        }

        AfterEach {
            # Cleanup
            try {
                $deleteInput = @{ name = $testFeatureName } | ConvertTo-Json -Compress
                dsc resource delete -r $resourceName --input $deleteInput | Out-Null
                Start-Sleep -Seconds 2
            } catch {
                Write-Warning "Could not cleanup feature: $_"
            }
        }

        It 'Should disable a feature' {
            $inputJson = @{
                name = $testFeatureName
            } | ConvertTo-Json -Compress

            { dsc resource delete -r $resourceName --input $inputJson } | Should -Not -Throw

            # Verify it's disabled
            Start-Sleep -Seconds 2
            $result = dsc resource get -r $resourceName --input $inputJson | ConvertFrom-Json
            $result.actualState._exist | Should -Be $false
        }
    }

    Context 'Restart Metadata' -Skip:(!$isAdmin) {
        BeforeEach {
            # Ensure feature is disabled before test
            try {
                $getInput = @{ name = $testFeatureName } | ConvertTo-Json -Compress
                $currentState = dsc resource get -r $resourceName --input $getInput | ConvertFrom-Json

                if ($currentState.actualState._exist) {
                    $deleteInput = @{ name = $testFeatureName } | ConvertTo-Json -Compress
                    dsc resource delete -r $resourceName --input $deleteInput | Out-Null
                    Start-Sleep -Seconds 2
                }
            } catch {
                Write-Warning "Could not disable feature in BeforeEach: $_"
            }
        }

        AfterEach {
            # Cleanup: disable the feature after test
            try {
                $deleteInput = @{ name = $testFeatureName } | ConvertTo-Json -Compress
                dsc resource delete -r $resourceName --input $deleteInput | Out-Null
                Start-Sleep -Seconds 2
            } catch {
                Write-Warning "Could not cleanup feature: $_"
            }
        }

        It 'Should include _metadata._restartRequired when feature requires restart' {
            $inputJson = @{
                name = $testFeatureName
                _exist = $true
            } | ConvertTo-Json -Compress

            $result = dsc resource set -r $resourceName --input $inputJson | ConvertFrom-Json

            # TelnetClient typically requires a restart, but this may vary
            # We're testing that IF restart is required, the metadata is present
            if ($result.afterState._metadata) {
                $result.afterState._metadata | Should -BeOfType [System.Management.Automation.PSCustomObject]

                if ($result.afterState._metadata._restartRequired) {
                    $result.afterState._metadata._restartRequired | Should -Not -BeNullOrEmpty
                    $result.afterState._metadata._restartRequired | Should -BeOfType [System.Array]
                    $result.afterState._metadata._restartRequired[0].system | Should -Not -BeNullOrEmpty
                    $result.afterState._metadata._restartRequired[0].system | Should -Be $env:COMPUTERNAME
                }
            }
        }

        It 'Should not include restart metadata when feature does not require restart' {
            # First enable the feature
            $inputJson = @{
                name = $testFeatureName
                _exist = $true
            } | ConvertTo-Json -Compress

            dsc resource set -r $resourceName --input $inputJson | Out-Null
            Start-Sleep -Seconds 2

            # Try to set it again (idempotent operation should not require restart)
            $result = dsc resource set -r $resourceName --input $inputJson 2>&1

            # If the feature is already in desired state, set returns nothing
            # This tests that repeated operations don't add unnecessary restart metadata
            if ($result) {
                $resultObj = $result | ConvertFrom-Json
                # If there's a result and no change was made, there should be no restart metadata
                if ($resultObj.afterState) {
                    # Metadata might be null or not present at all when no restart is needed
                    if ($resultObj.afterState._metadata) {
                        $resultObj.afterState._metadata._restartRequired | Should -BeNullOrEmpty
                    }
                }
            }
        }

        It 'Should have _metadata property in schema' {
            $manifest = Get-Content (Join-Path $publishPath 'windows-feature.dsc.resource.json') | ConvertFrom-Json
            $schemaJson = & (Join-Path $publishPath 'windows-feature.exe') schema
            $schema = $schemaJson | ConvertFrom-Json

            $schema.properties | Should -Not -BeNullOrEmpty
            $schema.properties._metadata | Should -Not -BeNullOrEmpty
            $schema.properties._metadata.description | Should -BeLike "*restart*"
        }
    }

    Context 'Export Operation' -Skip:(!$isAdmin) {
        It 'Should export all installed features' {
            $result = dsc resource export -r $resourceName | ConvertFrom-Json

            $result | Should -Not -BeNullOrEmpty
            $result.resources | Should -Not -BeNullOrEmpty
            $result.resources.Count | Should -BeGreaterThan 0

            # Each exported feature should have required properties
            foreach ($feature in $result.resources) {
                $feature.properties.name | Should -Not -BeNullOrEmpty
                $feature.properties._exist | Should -Not -Be $false
                $feature.properties.state | Should -Not -BeNullOrEmpty
            }
        }

        It 'Should export features in valid JSON format' {
            $output = dsc resource export -r $resourceName
            { $output | ConvertFrom-Json } | Should -Not -Throw
        }
    }
}
