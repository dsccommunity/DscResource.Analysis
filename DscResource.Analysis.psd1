@{
    # Version number of this module.
    moduleVersion     = '1.0.0.0'

    # ID used to uniquely identify this module
    GUID              = 'c9b769c1-0aa4-47c5-bdfc-d617ff7f2ae2'

    # Author of this module
    Author            = 'Daniel Scott-Raynsford'

    # Company or vendor of this module
    CompanyName       = 'Daniel Scott-Raynsford'

    # Copyright statement for this module
    Copyright         = '(c) Daniel Scott-Raynsford. All rights reserved.'

    # Description of the functionality provided by this module
    Description       = 'Module to perform analysis on PowerShell DSC Resource repositories to report on health and other properties.'

    # Minimum version of the Windows PowerShell engine required by this module
    PowerShellVersion = '4.0'

    # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData       = @{

        PSData = @{

            # Tags applied to this module. These help with module discovery in online galleries.
            Tags         = @('DesiredStateConfiguration', 'DSC', 'DSCResourceKit', 'DSCResource')

            # A URL to the license for this module.
            LicenseUri   = 'https://github.com/PlagueHO/DscResource.Analysis/blob/master/LICENSE'

            # A URL to the main website for this project.
            ProjectUri   = 'https://github.com/PlagueHO/DscResource.Analysis'

            # A URL to an icon representing this module.
            # IconUri = ''

            # ReleaseNotes of this module
            ReleaseNotes = ''

        } # End of PSData hashtable
    } # End of PrivateData hashtable
}
