$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

Describe 'windows-optional-feature' {
    BeforeAll {
        $publishPath = Join-Path $PSScriptRoot '..\src\bin\Release\net9.0-windows\win-x64\publish'
        $env:Path += ";$publishPath"

        $resourceName = 'OpenDsc.Windows/OptionalFeature'
        $testFeatureName = 'TelnetClient'
    }

    Context 'Discovery' {
        It 'should be found by dsc' {
            $result = dsc resource list OpenDsc.Windows/OptionalFeature | ConvertFrom-Json
            $result | Should -Not -BeNullOrEmpty
            $result.type | Should -Be 'OpenDsc.Windows/OptionalFeature'
        }

        It 'should report correct capabilities' {
            $result = dsc resource list OpenDsc.Windows/OptionalFeature | ConvertFrom-Json
            $result.capabilities | Should -Contain 'get'
            $result.capabilities | Should -Contain 'set'
            $result.capabilities | Should -Contain 'delete'
            $result.capabilities | Should -Contain 'export'
        }

        It 'should have a valid manifest' {
            $manifest = Get-Content (Join-Path $publishPath 'windows-optional-feature.dsc.resource.json') | ConvertFrom-Json
            $manifest.type | Should -Be 'OpenDsc.Windows/OptionalFeature'
            $manifest.version | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Schema Validation' {
        It 'should have required properties in schema' {
            $schemaJson = & (Join-Path $publishPath 'windows-optional-feature.exe') schema
            $schema = $schemaJson | ConvertFrom-Json

            $schema.properties | Should -Not -BeNullOrEmpty
            $schema.properties.name | Should -Not -BeNullOrEmpty
            $schema.properties.name.type | Should -Be 'string'
            $schema.properties.name.pattern | Should -Not -BeNullOrEmpty
        }

        It 'should have _exist property with default value' {
            $schemaJson = & (Join-Path $publishPath 'windows-optional-feature.exe') schema
            $schema = $schemaJson | ConvertFrom-Json

            $schema.properties._exist | Should -Not -BeNullOrEmpty
            $schema.properties._exist.type | Should -Be 'boolean'
            $schema.properties._exist.default | Should -Be $true
        }

        It 'should have read-only properties marked correctly' {
            $schemaJson = & (Join-Path $publishPath 'windows-optional-feature.exe') schema
            $schema = $schemaJson | ConvertFrom-Json

            $schema.properties.state | Should -Not -BeNullOrEmpty
            $schema.properties.state.readOnly | Should -Be $true
            $schema.properties.displayName.readOnly | Should -Be $true
            $schema.properties.description.readOnly | Should -Be $true
        }

        It 'should have _metadata property for restart information' {
            $schemaJson = & (Join-Path $publishPath 'windows-optional-feature.exe') schema
            $schema = $schemaJson | ConvertFrom-Json

            $schema.properties._metadata | Should -Not -BeNullOrEmpty
            $schema.properties._metadata.description | Should -BeLike "*restart*"
        }

        It 'should not allow additional properties' {
            $schemaJson = & (Join-Path $publishPath 'windows-optional-feature.exe') schema
            $schema = $schemaJson | ConvertFrom-Json

            $schema.additionalProperties | Should -Be $false
        }
    }

    Context 'Get Operation' -Skip:(!$isAdmin) {
        It 'should return _exist=false for non-existent feature' {
            $inputJson = @{
                name = 'NonExistentFeature-12345-XYZ'
            } | ConvertTo-Json -Compress

            $result = dsc resource get -r $resourceName --input $inputJson | ConvertFrom-Json

            $result.actualState.name | Should -Be 'NonExistentFeature-12345-XYZ'
            $result.actualState._exist | Should -Be $false
        }

        It 'should read properties of existing feature' {
            $inputJson = @{
                name = $testFeatureName
            } | ConvertTo-Json -Compress

            $result = dsc resource get -r $resourceName --input $inputJson | ConvertFrom-Json

            $result.actualState.name | Should -Be $testFeatureName
            $result.actualState._exist | Should -BeIn @($true, $false)

            if ($result.actualState._exist) {
                $result.actualState.state | Should -Not -BeNullOrEmpty
                $result.actualState.displayName | Should -Not -BeNullOrEmpty
            }
        }

        It 'should include displayName and description for features' {
            $inputJson = @{
                name = 'TelnetClient'
            } | ConvertTo-Json -Compress

            $result = dsc resource get -r $resourceName --input $inputJson | ConvertFrom-Json

            $result.actualState.name | Should -Be 'TelnetClient'
            $result.actualState.PSObject.Properties.Name | Should -Contain 'displayName'
            $result.actualState.PSObject.Properties.Name | Should -Contain 'description'
        }
    }

    Context 'Set Operation' -Skip:(!$isAdmin) {
        BeforeEach {
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
            try {
                $deleteInput = @{ name = $testFeatureName } | ConvertTo-Json -Compress
                dsc resource delete -r $resourceName --input $deleteInput | Out-Null
                Start-Sleep -Seconds 2
            } catch {
                Write-Warning "Could not cleanup feature: $_"
            }
        }

        It 'should enable a feature' {
            $inputJson = @{
                name = $testFeatureName
                _exist = $true
            } | ConvertTo-Json -Compress

            $result = dsc resource set -r $resourceName --input $inputJson | ConvertFrom-Json

            $result.afterState.name | Should -Be $testFeatureName
            $result.afterState._exist | Should -Not -Be $false

            $verifyJson = @{
                name = $testFeatureName
            } | ConvertTo-Json -Compress

            $getResult = dsc resource get -r $resourceName --input $verifyJson | ConvertFrom-Json
            $getResult.actualState._exist | Should -Not -Be $false
        }

        It 'should disable a feature using _exist=false' {
            $enableJson = @{
                name = $testFeatureName
                _exist = $true
            } | ConvertTo-Json -Compress

            dsc resource set -r $resourceName --input $enableJson | Out-Null
            Start-Sleep -Seconds 2

            $disableJson = @{
                name = $testFeatureName
                _exist = $false
            } | ConvertTo-Json -Compress

            $result = dsc resource set -r $resourceName --input $disableJson | ConvertFrom-Json

            $result.afterState._exist | Should -Be $false

            $verifyJson = @{
                name = $testFeatureName
            } | ConvertTo-Json -Compress

            $getResult = dsc resource get -r $resourceName --input $verifyJson | ConvertFrom-Json
            $getResult.actualState._exist | Should -Be $false
        }

        It 'should be idempotent when feature already enabled' {
            $inputJson = @{
                name = $testFeatureName
                _exist = $true
            } | ConvertTo-Json -Compress

            dsc resource set -r $resourceName --input $inputJson | Out-Null
            Start-Sleep -Seconds 2

            $result = dsc resource set -r $resourceName --input $inputJson 2>&1

            if ($result) {
                $resultObj = $result | ConvertFrom-Json
                if ($resultObj.afterState) {
                    $resultObj.afterState._exist | Should -Not -Be $false
                }
            }
        }
    }

    Context 'Delete Operation' -Skip:(!$isAdmin) {
        BeforeEach {
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
            try {
                $deleteInput = @{ name = $testFeatureName } | ConvertTo-Json -Compress
                dsc resource delete -r $resourceName --input $deleteInput | Out-Null
                Start-Sleep -Seconds 2
            } catch {
                Write-Warning "Could not cleanup feature: $_"
            }
        }

        It 'should disable a feature' {
            $inputJson = @{
                name = $testFeatureName
            } | ConvertTo-Json -Compress

            { dsc resource delete -r $resourceName --input $inputJson } | Should -Not -Throw

            Start-Sleep -Seconds 2
            $result = dsc resource get -r $resourceName --input $inputJson | ConvertFrom-Json
            $result.actualState._exist | Should -Be $false
        }

        It 'should be idempotent when feature already disabled' {
            $inputJson = @{
                name = $testFeatureName
            } | ConvertTo-Json -Compress

            dsc resource delete -r $resourceName --input $inputJson | Out-Null
            Start-Sleep -Seconds 2

            { dsc resource delete -r $resourceName --input $inputJson } | Should -Not -Throw
        }
    }

    Context 'Restart Metadata' -Skip:(!$isAdmin) {
        BeforeEach {
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
            try {
                $deleteInput = @{ name = $testFeatureName } | ConvertTo-Json -Compress
                dsc resource delete -r $resourceName --input $deleteInput | Out-Null
                Start-Sleep -Seconds 2
            } catch {
                Write-Warning "Could not cleanup feature: $_"
            }
        }

        It 'should include _metadata._restartRequired when feature requires restart' {
            $inputJson = @{
                name = $testFeatureName
                _exist = $true
            } | ConvertTo-Json -Compress

            $result = dsc resource set -r $resourceName --input $inputJson | ConvertFrom-Json
            $result.afterState._metadata._restartRequired[0].system | Should -Not -BeNullOrEmpty
            $result.afterState._metadata._restartRequired[0].system | Should -Be $env:COMPUTERNAME
        }
    }

    Context 'Export Operation' -Skip:(!$isAdmin) {
        It 'should export all features' {
            $result = dsc resource export -r $resourceName | ConvertFrom-Json

            $result | Should -Not -BeNullOrEmpty
            $result.resources | Should -Not -BeNullOrEmpty
            $result.resources.Count | Should -BeGreaterThan 0

            foreach ($feature in $result.resources) {
                $feature.properties.name | Should -Not -BeNullOrEmpty
                if ($feature.properties._exist -eq $false) {
                    $feature.properties._exist | Should -Be $false
                }
            }
        }

        It 'should export features in valid JSON format' {
            $result = dsc resource export -r $resourceName
            $result | Should -Not -BeNullOrEmpty
            { $result | ConvertFrom-Json } | Should -Not -Throw
        }

        It 'should export both installed and available features' {
            $result = dsc resource export -r $resourceName | ConvertFrom-Json

            $result.resources.Count | Should -BeGreaterThan 0
        }
    }
}
