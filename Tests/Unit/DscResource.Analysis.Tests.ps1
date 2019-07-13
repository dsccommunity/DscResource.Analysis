Describe 'DscResource.Analysis Unit Tests' {
    BeforeAll {
        $projectRootPath = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
        $modulePath = Join-Path -Path $projectRootPath -ChildPath 'DscResource.Analysis.psm1'

        Import-Module -Name $modulePath -Force
    }

    InModuleScope 'DscResource.Analysis' {
        Describe 'Get-DscRepositoriesFromResourceKitMaintainers' {
            $script:maintainersMd = @'
# DSC Resource Kit Maintainers

Maintainers are trusted contributors with knowledge in a resource module domain
who have [write access](https://help.github.com/articles/permission-levels-for-an-organization-repository/)
to one or more DSC Resource Kit repositories.

| Repository | Maintainer(s) |
| ---------- | ------------- |
| [SharePointDsc](https://github.com/PowerShell/SharePointDsc) | Yorick Kuijs ([@ykuijs](https://github.com/YKuijs)) <br/> Nik Charlebois ([@NikCharlebois](https://github.com/NikCharlebois)) |
| xDefender | DEPRECATED - Replaced by [WindowsDefenderDsc](https://www.powershellgallery.com/packages/WindowsDefenderDsc). Note: WindowsDefenderDsc is not part of DSC Resource Kit. |
| [xWebDeploy](https://github.com/PowerShell/xWebDeploy) | --- |
'@

            Context 'When pulling maintainers list from DSC Resource kit' {
                BeforeAll {
                    Mock -CommandName Invoke-WebRequest -MockWith {
                        @{ Content = $script:maintainersMd }
                    }
                }

                $script:repositories = Get-DscRepositoriesFromResourceKitMaintainers

                It 'Should return the expected list of repositories' {
                    $script:repositories.Count | Should -BeExactly 3
                    $script:repositories[0].Name | Should -BeExactly 'SharePointDsc'
                    $script:repositories[0].Uri | Should -BeExactly 'https://github.com/PowerShell/SharePointDsc'
                    $script:repositories[0].Maintainers[0] | Should -BeExactly 'ykuijs'
                    $script:repositories[0].Maintainers[1] | Should -BeExactly 'NikCharlebois'
                    $script:repositories[1].Name | Should -BeExactly 'xDefender'
                    $script:repositories[1].Uri | Should -BeNullOrEmpty
                    $script:repositories[1].Maintainers | Should -BeNullOrEmpty
                    $script:repositories[2].Name | Should -BeExactly 'xWebDeploy'
                    $script:repositories[2].Uri | Should -BeExactly 'https://github.com/PowerShell/xWebDeploy'
                    $script:repositories[2].Maintainers | Should -BeNullOrEmpty
                }
            }
        }

        Describe 'Get-DscResourceModuleMetaTestOptIn' {
            $script:metaTestOptInContent = @'
[
    "Common Tests - Validate Markdown Files",
    "Common Tests - Validate Example Files",
    "Common Tests - Validate Module Files",
    "Common Tests - Validate Script Files",
    "Common Tests - Required Script Analyzer Rules"
]
'@

            Context 'When the .MetaTestOptIn.json file is found in the repository' {
                BeforeAll {
                    Mock -CommandName Invoke-WebRequest -MockWith {
                        @{ Content = $script:metaTestOptInContent }
                    }
                }

                $script:metaTestOptIn = Get-DscResourceModuleMetaTestOptIn

                It 'Should return the object with metaTestOptIn properties' {
                    $script:metaTestOptIn | Should -Contain 'Common Tests - Validate Markdown Files'
                    $script:metaTestOptIn | Should -Contain 'Common Tests - Validate Example Files'
                    $script:metaTestOptIn | Should -Contain 'Common Tests - Validate Module Files'
                    $script:metaTestOptIn | Should -Contain 'Common Tests - Validate Script Files'
                    $script:metaTestOptIn | Should -Contain 'Common Tests - Required Script Analyzer Rules'
                }
            }

            Context 'When the .MetaTestOptIn.json file is not found in the repository' {
                BeforeAll {
                    Mock -CommandName Invoke-WebRequest -MockWith { Throw '404' }
                }

                $script:metaTestOptIn = Get-DscResourceModuleMetaTestOptIn

                It 'Should return null' {
                    $script:metaTestOptIn | Should -BeNullOrEmpty
                }
            }
        }
    }
}
