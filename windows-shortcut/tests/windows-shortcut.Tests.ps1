Describe windows-service {
    BeforeAll {
        $path = Join-Path $PSScriptRoot '..\src\bin\Release\net9.0-windows\win-x64\publish'
        $env:Path += ";$path"
    }

    Context Basic {
        It 'should be found by dsc' {
            dsc resource list OpenDsc.Windows/Shortcut |
            ConvertFrom-Json |
            Should -Not -BeNullOrEmpty
        }
    }
}
