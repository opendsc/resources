Describe 'XmlElement Resource' {
    BeforeAll {
        # Determine executable path based on platform
        if ($IsWindows) {
            $configuration = $env:BUILD_CONFIGURATION ?? 'Release'
            $publishPath = Join-Path $PSScriptRoot "..\src\OpenDsc.Resource.Windows\bin\$configuration\net9.0-windows\win-x64\publish"
        } else {
            $configuration = $env:BUILD_CONFIGURATION ?? 'Release'
            $publishPath = Join-Path $PSScriptRoot "..\src\OpenDsc.Resource.Linux\bin\$configuration\net9.0\publish"
        }

        $env:Path += if ($IsWindows) { ";$publishPath" } else { ":$publishPath" }
        $script:resourceType = 'OpenDsc.Xml/Element'
        $script:testXmlPath = Join-Path $TestDrive 'test.xml'
    }

    Context 'Discovery' {
        It 'should be found by dsc' {
            $result = dsc resource list $script:resourceType | ConvertFrom-Json
            $result | Should -Not -BeNullOrEmpty
            if ($result -is [array]) {
                $result = $result | Where-Object { $_.type -eq $script:resourceType }
            }
            $result.type | Should -Be $script:resourceType
        }
    }

    Context 'Set Operation' {
        BeforeEach {
            '<?xml version="1.0"?><root></root>' | Out-File -FilePath $script:testXmlPath -Encoding utf8
        }

        AfterEach {
            if (Test-Path $script:testXmlPath) {
                Remove-Item $script:testXmlPath -Force
            }
        }

        It 'should create element with text content' {
            $inputJson = @{
                path = $script:testXmlPath
                xPath = '/root/child'
                value = 'Test Value'
            } | ConvertTo-Json -Compress

            dsc resource set -r $script:resourceType --input $inputJson | Out-Null

            [xml]$xml = Get-Content $script:testXmlPath
            $xml.root.child | Should -Be 'Test Value'
        }

        It 'should create element with attributes' {
            $inputJson = @{
                path = $script:testXmlPath
                xPath = '/root/child'
                value = 'Test'
                attributes = @{
                    id = 'test123'
                    name = 'testname'
                }
            } | ConvertTo-Json -Compress

            dsc resource set -r $script:resourceType --input $inputJson | Out-Null

            [xml]$xml = Get-Content $script:testXmlPath
            $xml.root.child.id | Should -Be 'test123'
            $xml.root.child.name | Should -Be 'testname'
        }
    }
}
