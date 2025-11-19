Describe 'windows-service' {
    BeforeAll {
        $publishPath = Join-Path $PSScriptRoot '..\src\bin\Release\net9.0-windows\win-x64\publish'
        $env:Path += ";$publishPath"
    }

    Context 'Discovery' {
        It 'should be found by dsc' {
            $result = dsc resource list OpenDsc.Windows/Service | ConvertFrom-Json
            $result | Should -Not -BeNullOrEmpty
            $result.type | Should -Be 'OpenDsc.Windows/Service'
        }

        It 'should report correct capabilities' {
            $result = dsc resource list OpenDsc.Windows/Service | ConvertFrom-Json
            $result.capabilities | Should -Contain 'get'
            $result.capabilities | Should -Contain 'set'
            $result.capabilities | Should -Contain 'delete'
            $result.capabilities | Should -Contain 'export'
        }

        It 'should have a valid manifest' {
            $manifest = Get-Content (Join-Path $publishPath 'windows-service.dsc.resource.json') | ConvertFrom-Json
            $manifest.type | Should -Be 'OpenDsc.Windows/Service'
            $manifest.version | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get Operation' {
        It 'should return _exist=false for non-existent service' {
            $inputJson = @{
                name = 'NonExistentService_12345'
            } | ConvertTo-Json -Compress

            $result = dsc resource get -r OpenDsc.Windows/Service --input $inputJson | ConvertFrom-Json
            $result.actualState._exist | Should -Be $false
            $result.actualState.name | Should -Be 'NonExistentService_12345'
        }

        It 'should read properties of existing service' {
            $inputJson = @{
                name = 'wuauserv'
            } | ConvertTo-Json -Compress

            $result = dsc resource get -r OpenDsc.Windows/Service --input $inputJson | ConvertFrom-Json
            $result.actualState.name | Should -Be 'wuauserv'
            $result.actualState.displayName | Should -Not -BeNullOrEmpty
            $result.actualState.status | Should -Not -BeNullOrEmpty
            $result.actualState.startType | Should -Not -BeNullOrEmpty
        }

        It 'should retrieve service with dependencies' {
            $serviceWithDeps = Get-Service | Where-Object { $_.ServicesDependedOn.Count -gt 0 } | Select-Object -First 1

            if ($serviceWithDeps) {
                $inputJson = @{
                    name = $serviceWithDeps.Name
                } | ConvertTo-Json -Compress

                $result = dsc resource get -r OpenDsc.Windows/Service --input $inputJson | ConvertFrom-Json
                $result.actualState.dependencies | Should -Not -BeNullOrEmpty
            }
        }
    }

    Context 'Export Operation' {
        It 'should export all services' {
            $result = dsc resource export -r OpenDsc.Windows/Service | ConvertFrom-Json

            $result | Should -Not -BeNullOrEmpty
            $result.resources | Should -Not -BeNullOrEmpty
            $result.resources.Count | Should -BeGreaterThan 0

            $firstService = $result.resources[0].properties
            $firstService.name | Should -Not -BeNullOrEmpty
            $firstService.status | Should -Not -BeNullOrEmpty
            $firstService.startType | Should -Not -BeNullOrEmpty
        }

        It 'should export known system services' {
            $result = dsc resource export -r OpenDsc.Windows/Service | ConvertFrom-Json

            $wuauserv = $result.resources | Where-Object { $_.properties.name -eq 'wuauserv' }
            $wuauserv | Should -Not -BeNullOrEmpty
            $wuauserv.properties.displayName | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Schema Validation' {
        It 'should validate service name pattern (no slashes)' {
            $invalidInput = @{
                name = 'Invalid/Service'
                path = 'C:\Windows\System32\svchost.exe'
                startType = 'Manual'
            } | ConvertTo-Json -Compress

            dsc resource set -r OpenDsc.Windows/Service --input $invalidInput 2>&1 | Out-Null
            $LASTEXITCODE | Should -Not -Be 0
        }

        It 'should accept valid service names' {
            $validNames = @('MyService', 'My-Service', 'My_Service', 'MyService123')

            foreach ($name in $validNames) {
                $inputJson = @{
                    name = $name
                } | ConvertTo-Json -Compress

                $result = dsc resource get -r OpenDsc.Windows/Service --input $inputJson | ConvertFrom-Json
                $result.actualState.name | Should -Be $name
            }
        }
    }

    Context 'Error Handling' {
        It 'should handle invalid JSON gracefully' {
            $invalidJson = '{ invalid json }'

            $invalidJson | dsc resource get -r OpenDsc.Windows/Service 2>&1 | Out-Null
            $LASTEXITCODE | Should -Not -Be 0
        }
    }
}
