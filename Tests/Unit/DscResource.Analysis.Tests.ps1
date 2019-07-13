Describe 'DscResource.Analysis Unit Tests' {
    BeforeAll {
        $projectRootPath = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
        $modulePath = Join-Path -Path $projectRootPath -ChildPath 'DscResource.Analysis.psm1'

        Import-Module -Name $modulePath -Force
    }

    InModuleScope 'DscResource.Analysis' {
        Describe 'Get-RepositoryFileUri' {
            Context 'When the branch is not specified' {
                It 'Should return expected path' {
                    Get-RepositoryFileUri -RepositoryUri 'https://github.com/PowerShell/NetworkingDsc' -Path 'File.json' |
                        Should -BeExactly 'https://raw.githubusercontent.com/PowerShell/NetworkingDsc/dev/File.json'
                }
            }

            Context 'When the branch is set to master' {
                It 'Should return expected path' {
                    Get-RepositoryFileUri -RepositoryUri 'https://github.com/PowerShell/NetworkingDsc' -Branch 'master' -Path 'File.json' |
                        Should -BeExactly 'https://raw.githubusercontent.com/PowerShell/NetworkingDsc/master/File.json'
                }
            }
        }

        Describe 'Test-RepositoryFileExists' {
            Context 'When the remote file exists' {
                BeforeAll {
                    Mock -CommandName Invoke-WebRequest -MockWith {
                        @{ Content = 'Exists' }
                    }
                }

                It 'Should return $true' {
                    Test-RepositoryFileExists -RepositoryUri 'https://github.com/PowerShell/NetworkingDsc' -Branch 'dev' -Path 'FileExists.json' | Should -BeTrue
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Invoke-WebRequest -ParameterFilter {
                        $Uri -eq 'https://raw.githubusercontent.com/PowerShell/NetworkingDsc/dev/FileExists.json'
                    }
                }
            }

            Context 'When the remote file does not exist' {
                BeforeAll {
                    Mock -CommandName Invoke-WebRequest -MockWith {
                        Throw '404'
                    }
                }

                It 'Should return $false' {
                    Test-RepositoryFileExists -RepositoryUri 'https://github.com/PowerShell/NetworkingDsc' -Branch 'dev' -Path 'FileDoesNotExists.json' | Should -BeFalse
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Invoke-WebRequest -ParameterFilter {
                        $Uri -eq 'https://raw.githubusercontent.com/PowerShell/NetworkingDsc/dev/FileDoesNotExists.json'
                    }
                }
            }
        }

        Describe 'Get-DscResourceModulesFromResourceKitMaintainers' {
            $script:maintainersMd = @'
# DSC Resource Kit Maintainers

Maintainers are trusted contributors with knowledge in a resource module domain
who have [write access](https://help.github.com/articles/permission-levels-for-an-organization-repository/)
to one or more DSC Resource Kit repositories.

| Repository | Maintainer(s) |
| ---------- | ------------- |
| [DscResources](https://github.com/PowerShell/DscResources) | Katie Keim ([@kwirkykat](https://github.com/kwirkykat)) <br/> Zachary Alexander ([@zjalexander](https://github.com/zjalexander)) |
| [DscResource.Tests](https://github.com/PowerShell/DscResource.Tests) | Katie Keim ([@kwirkykat](https://github.com/kwirkykat)) <br/> Mariah Breakey ([@mbreakey3](https://github.com/mbreakey3)) |
| [SharePointDsc](https://github.com/PowerShell/SharePointDsc) | Yorick Kuijs ([@ykuijs](https://github.com/YKuijs)) <br/> Nik Charlebois ([@NikCharlebois](https://github.com/NikCharlebois)) |
| xDefender | DEPRECATED - Replaced by [WindowsDefenderDsc](https://www.powershellgallery.com/packages/WindowsDefenderDsc). Note: WindowsDefenderDsc is not part of DSC Resource Kit. |
| [xHyper-V](https://github.com/PowerShell/xHyper-V) | Anthony Romano ([@aromano2](https://github.com/aromano2)) |
| [xWebDeploy](https://github.com/PowerShell/xWebDeploy) | --- |
'@

            Context 'When pulling maintainers list from DSC Resource kit' {
                BeforeAll {
                    Mock -CommandName Invoke-WebRequest -MockWith {
                        @{ Content = $script:maintainersMd }
                    }
                }

                It 'Should not throw' {
                    {
                        $script:repositories = Get-DscResourceModulesFromResourceKitMaintainers -Verbose
                    } | Should -Not -Throw
                }

                It 'Should return the expected list of repositories' {
                    $script:repositories.Count | Should -BeExactly 4
                    $script:repositories[0].Name | Should -BeExactly 'SharePointDsc'
                    $script:repositories[0].RepositoryUri | Should -BeExactly 'https://github.com/PowerShell/SharePointDsc'
                    $script:repositories[0].Maintainers[0] | Should -BeExactly 'ykuijs'
                    $script:repositories[0].Maintainers[1] | Should -BeExactly 'NikCharlebois'
                    $script:repositories[1].Name | Should -BeExactly 'xDefender'
                    $script:repositories[1].RepositoryUri | Should -BeNullOrEmpty
                    $script:repositories[1].Maintainers | Should -BeNullOrEmpty
                    $script:repositories[2].Name | Should -BeExactly 'xHyper-V'
                    $script:repositories[2].RepositoryUri | Should -BeExactly 'https://github.com/PowerShell/xHyper-V'
                    $script:repositories[2].Maintainers | Should -BeExactly 'aromano2'
                    $script:repositories[3].Name | Should -BeExactly 'xWebDeploy'
                    $script:repositories[3].RepositoryUri | Should -BeExactly 'https://github.com/PowerShell/xWebDeploy'
                    $script:repositories[3].Maintainers | Should -BeNullOrEmpty
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

                It 'Should not throw' {
                    {
                        $script:metaTestOptIn = Get-DscResourceModuleMetaTestOptIn `
                            -RepositoryUri 'https://github.com/PowerShell/NetworkingDsc' `
                            -Verbose
                    } | Should -Not -Throw
                }

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

                It 'Should not throw' {
                    {
                        $script:metaTestOptIn = Get-DscResourceModuleMetaTestOptIn `
                            -RepositoryUri 'https://github.com/PowerShell/NetworkingDsc' `
                            -Verbose
                    } | Should -Not -Throw
                }

                It 'Should return null' {
                    $script:metaTestOptIn | Should -BeNullOrEmpty
                }
            }
        }

        Describe 'Get-DscResourceModuleInformation' {
            $script:metaTestOptIn = @(
                'Common Tests - Validate Markdown Files'
                'Common Tests - Validate Example Files'
                'Common Tests - Validate Module Files'
                'Common Tests - Validate Script Files'
                'Common Tests - Required Script Analyzer Rules'
            )

            Context 'When the metaTestOptIn was found' {
                BeforeAll {
                    Mock -CommandName Get-DscResourceModuleMetaTestOptIn -MockWith {
                        $metaTestOptIn
                    }
                }

                It 'Should not throw' {
                    {
                        $script:dscResourceModuleInformation = Get-DscResourceModuleInformation `
                            -RepositoryUri 'https://github.com/PowerShell/NetworkingDsc' `
                            -Verbose
                    } | Should -Not -Throw
                }

                It 'Should return the object with metaTestOptIn properties' {
                    $script:dscResourceModuleInformation.Name | Should -BeExactly 'NetworkingDsc'
                    $script:dscResourceModuleInformation.MetaTestOptIn | Should -Contain 'Common Tests - Validate Markdown Files'
                    $script:dscResourceModuleInformation.MetaTestOptIn | Should -Contain 'Common Tests - Validate Example Files'
                    $script:dscResourceModuleInformation.MetaTestOptIn | Should -Contain 'Common Tests - Validate Module Files'
                    $script:dscResourceModuleInformation.MetaTestOptIn | Should -Contain 'Common Tests - Validate Script Files'
                    $script:dscResourceModuleInformation.MetaTestOptIn | Should -Contain 'Common Tests - Required Script Analyzer Rules'
                }
            }
        }

        Describe 'Get-DscResourceKitInformation' {
            Context 'When the resource kit maintainers has a single repository' {
                BeforeAll {
                    Mock -CommandName Get-DscResourceModulesFromResourceKitMaintainers -MockWith {
                        [System.Collections.ArrayList] @(
                            [PSCustomObject] @{
                                Name = 'NetworkingDsc'
                                RepositoryUri = 'https://github.com/PowerShell/NetworkingDsc'
                            }
                        )
                    }

                    Mock -CommandName Get-DscResourceModuleInformation -MockWith {
                        [PSCustomObject] @{
                            Information = 'Information'
                        }
                    }
                }

                It 'Should not throw' {
                    {
                        $script:dscResourceKitInformation = Get-DscResourceKitInformation -Verbose
                    } | Should -Not -Throw
                }

                It 'Should return information for the single DSC Resource module' {
                    $script:dscResourceKitInformation.Information | Should -BeExactly 'Information'
                }
            }
        }
    }
}
