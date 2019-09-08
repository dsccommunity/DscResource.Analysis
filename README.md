# DscResource.Analysis

This PowerShell module is used to perform analysis on PowerShell DSC Resource module repositories to
report on health and other properties.

## Instructions

To assemble the module analysis information object for all repositories listed in the DSC Resource
Kit, run the following command:

```powershell
Get-DscResourceKitInformation
```

## Exmples

The following section contains examples of how to use this module.

### Example 1

To list all Repositories opted in to the 'Common Tests - Custom Script Analyzer Rules'
meta test

```powershell
(Get-DscResourceKitInformation | Where-Object -FilterScript { $_.MetaTestOptIn -contains 'Common Tests - Custom Script Analyzer Rules' }).Name
```

### Example 2

To execute the 'Common Tests - PS Script Analyzer on Resource Files' Meta
Tests on all the DSC Resource modules in the DSC Resource Kit that have
been opted in to 'Common Tests - Custom Script Analyzer Rules'.

The DSCResource.Tests repository that will be used is
'https://github.com/SSvilen/DscResource.Tests' and the branch will be
'KeywordsCheck'.

```powershell
        Get-DscResourceKitInformation |
            Where-Object -FilterScript { $_.MetaTestOptIn -contains 'Common Tests - Custom Script Analyzer Rules' } |
            Start-DscResourceKitMetaTest `
                -TestFrameworkUri 'https://github.com/SSvilen/DscResource.Tests' `
                -TestFrameworkBranch 'KeywordsCheck' `
                -TestName 'Common Tests - PS Script Analyzer on Resource Files'
```
