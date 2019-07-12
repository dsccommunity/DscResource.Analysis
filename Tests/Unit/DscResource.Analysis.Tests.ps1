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
| [ActiveDirectoryCSDsc](https://github.com/PowerShell/ActiveDirectoryCSDsc) | Daniel Scott-Raynsford ([@PlagueHO](https://github.com/PlagueHO)) <br/> Jason Ryberg ([@devopsjesus](https://github.com/devopsjesus)) |
| [SharePointDsc](https://github.com/PowerShell/SharePointDsc) | Yorick Kuijs ([@ykuijs](https://github.com/YKuijs)) <br/> Nik Charlebois ([@NikCharlebois](https://github.com/NikCharlebois)) |
| [SqlServerDsc](https://github.com/PowerShell/SqlServerDsc) | Johan Ljunggren ([@johlju](https://github.com/johlju)) |
| [xActiveDirectory](https://github.com/PowerShell/xActiveDirectory) | Johan Ljunggren ([@johlju](https://github.com/johlju)) <br/> Jan-Hendrik Peters ([@nyanhp](https://github.com/nyanhp)) <br/> Jason Ryberg ([@devopsjesus](https://github.com/devopsjesus)) <br/> Ryan Christman ([rchristman89](https://github.com/rchristman89)) |
| xDefender | DEPRECATED - Replaced by [WindowsDefenderDsc](https://www.powershellgallery.com/packages/WindowsDefenderDsc). Note: WindowsDefenderDsc is not part of DSC Resource Kit. |
| xDisk | DEPRECATED - Replaced by [StorageDsc](https://github.com/PowerShell/StorageDsc) |
| [xPendingReboot](https://github.com/PowerShell/xPendingReboot) | Brian Wilhite ([@bcwilhite](https://github.com/bcwilhite)) <br/> Nehru Ali ([@nehrua](https://github.com/nehrua)) |
| [xWebDeploy](https://github.com/PowerShell/xWebDeploy) | --- |
| [xWinEventLog](https://github.com/PowerShell/xWinEventLog) | DEPRECATED - Migrated to [ComputerManagementDsc](https://github.com/PowerShell/ComputerManagementDsc) |
'@
            Context 'When string contains CRLF as new line' {
                BeforeAll {

                }

                It 'Should return the correct array of strings' {
                    $getStatementBlockAsRowsParameters = @{
                        StatementBlock = "First line`r`nSecond line"
                    }

                    $getStatementBlockAsRowsResult = `
                        Get-StatementBlockAsRows @getStatementBlockAsRowsParameters

                    $getStatementBlockAsRowsResult[0] | Should -Be $expectedReturnValue1
                    $getStatementBlockAsRowsResult[1] | Should -Be $expectedReturnValue2
                }
            }
        }
    }
}
