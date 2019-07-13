
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
        Pull list of repositories from the maintainers.md and return as an array of
        objects.

    .PARAMETER MaintainersUri
        The URI of the maintainers.md file to extract the list of repositories from.
#>
function Get-DscRepositoriesFromResourceKitMaintainers
{
    [CmdletBinding()]
    [OutputType([System.Collections.ArrayList])]
    param
    (
        [Parameter()]
        [System.String]
        $MaintainersUri = 'https://raw.githubusercontent.com/PowerShell/DscResources/master/Maintainers.md'
    )

    try
    {
        $maintainers = (Invoke-WebRequest -Uri $MaintainersUri -UseBasicParsing).Content
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

            # Skip list header rows
            if ($column1 -notmatch '[^-]+' -or $column1 -eq 'Repository')
            {
                continue
            }

            # Extract the repository name and URI from column1
            $matches = [RegEx]::Match($column1, '\[([\w]+)\]\(([^\)]+)\)')

            if ($matches.Success)
            {
                $name = $matches.Groups[1]
                $uri = $matches.Groups[2]
            }
            else
            {
                # An MD link wasn't found so must just contain a name
                $name = $column1
                $uri = ''
            }

            # Extract the maintainers from column2
            $maintainers = [RegEx]::Matches($column2, '\[@([\w]+)\]') | Foreach-Object -Process {
                $_.Groups[1].Value
            }

            # Put the extracted repository info into an object
            $result += [PSCustomObject] @{
                Name = $name
                Uri = $uri
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
        [Parameter()]
        [System.String]
        $RepositoryUri,

        [Parameter()]
        [System.String]
        $Branch = 'dev'

    )

    $metaTestOptInUri = '{0}/{1}/.MetaTestOptIn.json' -f ($RepositoryUri -replace 'github.com','raw.githubusercontent.com'), $Branch
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
