
<#
    .SYNOPSIS
        Ensure TLS 1.2 is enabled in the PowerShell workspace.
#>
function Enable-Tls12
{
    [CmdletBinding()]
    param ()

    if (-not ([Net.ServicePointManager]::SecurityProtocol).ToString().Contains([Net.SecurityProtocolType]::Tls12))
    {
        [Net.ServicePointManager]::SecurityProtocol = `
            [Net.ServicePointManager]::SecurityProtocol.toString() + ', ' + [Net.SecurityProtocolType]::Tls12
    }
}

<#
    .SYNOPSIS
        Assemble the URI of remote file in a GitHub repository.

    .PARAMETER RepositoryUri
        The URI of the GitHub repository that contains the file.

    .PARAMETER Branch
        The branch of the GitHub repository that contains the file.

    .PARAMETER Path
        The path of the file to test for.
#>
function Get-RepositoryFileUri
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $RepositoryUri,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Branch = 'dev',

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Path
    )

    return '{0}/{1}/{2}' -f ($RepositoryUri -replace 'github.com','raw.githubusercontent.com'), $Branch, $Path
}

<#
    .SYNOPSIS
        Test if a remote file in a GitHub repository exists.

    .PARAMETER RepositoryUri
        The URI of the GitHub repository to test for the file.

    .PARAMETER Branch
        The branch of the GitHub repository to test for the file.

    .PARAMETER Path
        The path of the file to test for.
#>
function Test-RepositoryFileExists
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $RepositoryUri,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Branch = 'dev',

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Path
    )

    $uri = Get-RepositoryFileUri @PSBoundParameters

    try
    {
        $null = Invoke-WebRequest -Uri $uri -UseBasicParsing -Method Head -Verbose:$false
    }
    catch
    {
        Write-Verbose -Message ('Remote file at URI {0} does not exist.' -f $uri)
        return $false
    }

    Write-Verbose -Message ('Remote file at URI {0} exists.' -f $uri)
    return $true
}

<#
    .SYNOPSIS
        Pull list of repositories from the maintainers.md and return as an array of
        objects.

    .PARAMETER MaintainersUri
        The URI of the maintainers.md file to extract the list of repositories from.
#>
function Get-DscResourceModulesFromResourceKitMaintainers
{
    [CmdletBinding()]
    [OutputType([System.Collections.ArrayList])]
    param
    (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $MaintainersUri = 'https://raw.githubusercontent.com/PowerShell/DscResources/master/Maintainers.md'
    )

    Write-Verbose -Message ('Getting list of DSC Resource modules from {0}.' -f $MaintainersUri)

    try
    {
        $maintainers = (Invoke-WebRequest -Uri $MaintainersUri -UseBasicParsing -Verbose:$false).Content
    }
    catch
    {
        throw ('Error downloading maintainers list from {0}.' -f $MaintainersUri)
    }

    $repositories = $maintainers -Split "`n" | Select-String -Pattern '\| ([^\|]+) \| ([^\|]+) \|'

    $result = [System.Collections.ArrayList] @()

    foreach ($repository in $repositories)
    {
        if ($repository -match '\| ([^\|]+) \| ([^\|]+) \|')
        {
            $column1 = $matches[1]
            $column2 = $matches[2]

            # Skip list header rows and repositories that a
            if ($column1 -notmatch '[^-]+' `
                -or $column1 -eq 'Repository')
            {
                continue
            }

            # Extract the repository name and URI from column1
            $matches = [RegEx]::Match($column1, '\[([\w-\.]+)\]\(([^\)]+)\)')

            if ($matches.Success)
            {
                $name = $matches.Groups[1]
                $repositoryUri = $matches.Groups[2]
            }
            else
            {
                # An MD link wasn't found so must just contain a name
                $name = $column1
                $repositoryUri = ''
            }

            # Skip any of the DscResource repositories as these are not resource modules
            if ($name -like 'DscResource*')
            {
                continue
            }

            # Extract the maintainers from column2
            $maintainers = [RegEx]::Matches($column2, '\[@([\w]+)\]') | Foreach-Object -Process {
                $_.Groups[1].Value
            }

            # Put the extracted repository info into an object
            $result += [PSCustomObject] @{
                Name = $name
                RepositoryUri = $repositoryUri
                Maintainers = $maintainers
            }
        }
    }

    return ($result | Sort-Object -Property Name)
}

<#
    .SYNOPSIS
        Get the DSC Resource Module .MetaTestOptIn.json information from a GitHub
        repository.

    .PARAMETER RepositoryUri
        The URI of the GitHub repository to get the .MetaTestOptIn.json from.

    .PARAMETER Branch
        The branch of the GitHub repository to get the .MetaTestOptIn.json from.
#>
function Get-DscResourceModuleMetaTestOptIn
{
    [CmdletBinding()]
    [OutputType([System.Object])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $RepositoryUri,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Branch = 'dev'
    )

    $metaTestOptInUri =  Get-RepositoryFileUri -Path '.MetaTestOptIn.json' @PSBoundParameters
    $metaTestOptIn = $null

    try
    {
        $metaTestOptInRequest = Invoke-WebRequest -Uri $metaTestOptInUri -UseBasicParsing
    }
    catch
    {
        Write-Verbose -Message ('Repository does not contain a .MetaTestOptIn.json in {1} branch in {0}.' -f $RepositoryUri, $Branch)
    }

    if ($null -ne $metaTestOptInRequest)
    {
        Write-Verbose -Message ('Repository {0} has a .MetaTestOptIn.json file.' -f $RepositoryUri)

        $metaTestOptIn = $metaTestOptInRequest.Content | ConvertFrom-Json
    }

    return $metaTestOptIn
}

<#
    .SYNOPSIS
        Get the DSC Resource Module information from the GitHub repository.

    .DESCRIPTION
        This function assembles an object containing information about the
        DSC Resource module in the specified GitHub repository.

        It is intended to retrieve and evaluate a number of different elements
        from the repository and return them in properties of the object.

        The elements currently returned are:
        - ChangeLog - does the repository have a CHANGELOG.md
        - CodeOfConduct = does the repository have a CODE_OF_CONDUCT.md
        - MarkDownLint = does the repository have a .markdownlint.json
        - MetaTestOptIn - an array of meta tests opted into.

    .PARAMETER RepositoryUri
        The URI of the GitHub repository to get information from.

    .PARAMETER Branch
        The branch of the GitHub repository to get information from.
#>
function Get-DscResourceModuleInformation
{
    [CmdletBinding()]
    [OutputType([System.Object])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $RepositoryUri,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Branch = 'dev'
    )

    $name = [RegEx]::Match($RepositoryUri,'^https://github.com/[\w]+/([\w]+)').Groups[1].Value

    Write-Verbose -Message ('Assembling DSC Resource information for {0} from repository {1} in branch {2}.' -f $name, $RepositoryUri,$Branch)

    return [PSCustomObject] @{
        Name = $name
        RepositoryUri = $RepositoryUri
        $Branch = $Branch
        ChangeLog = (Test-RepositoryFileExists -Path 'CHANGELOG.md' @PSBoundParameters)
        CodeOfConduct = (Test-RepositoryFileExists -Path 'CODE_OF_CONDUCT.md' @PSBoundParameters)
        MarkDownLint = (Test-RepositoryFileExists -Path '.markdownlint.json' @PSBoundParameters)
        MetaTestOptIn = (Get-DscResourceModuleMetaTestOptIn @PSBoundParameters)
    }
}

<#
    .SYNOPSIS
        Assemble the DSC Resource Module information from all resources in the DSC
        Resource Kit.
#>
function Get-DscResourceKitInformation
{
    [CmdletBinding()]
    [OutputType([System.Collections.ArrayList])]
    param ()

    $resources = Get-DscResourceModulesFromResourceKitMaintainers | Where-Object -FilterScript {
        -not [System.String]::IsNullOrEmpty($_.RepositoryUri)
    }
    $resourceInformation = [System.Collections.ArrayList] @()

    foreach ($resource in $resources)
    {
        $resourceInformation += Get-DscResourceModuleInformation -RepositoryUri $resource.RepositoryUri
    }

    return $resourceInformation
}