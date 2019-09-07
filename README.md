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
