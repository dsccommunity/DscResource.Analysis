
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

function Get-DscRepositoriesFromResourceKitMaintainers
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [System.String]
        $MaintainersUri = 'https://raw.githubusercontent.com/PowerShell/DscResources/master/Maintainers.md'
    )

    # Pull list of repositories from the maintainers.md
    try
    {
        $maintainers = (Invoke-WebRequest -Uri $MaintainersUri -UseBasicParsing).Content
    }
    catch
    {
        throw ('Error downloading maintainers list from {0}.' -f $MaintainersUri)
    }

    $regex = '\| \[[a-zA-Z]+]\((http[s]?\:\/\/github\.com\/[a-zA-Z]+\/[a-zA-Z]+)\)'
    $modules = $maintainers -Split "`n" | Select-String -Pattern $regex
    $repositories = @()

    foreach ($module in $modules)
    {
        if ($module -match $regex)
        {
            $repositories += $matches[1]
        }
    }

    return $repositories
}

# Assess each repository
foreach ($repository in $repositories)
{
    $metaTestOptInUri = '{0}/dev/.MetaTestOptIn.json' -f ($repository -replace 'github.com','raw.githubusercontent.com')
    try
    {
        $metaTestOptInRequest = Invoke-WebRequest -Uri $metaTestOptInUri -UseBasicParsing
    }
    catch
    {
        Write-Verbose -Message ('Failed to download .MetaTestOptIn.json from dev branch in {0}' -f $repository)
    }

    if ($null -ne $metaTestOptInRequest)
    {
        Write-Verbose -Message ('Repository {0} has a .MetaTestOptIn.json file' -f $repository)
        $metaTestOptIn = [System.Array]($metaTestOptInRequest.Content | ConvertFrom-Json) | Sort-Object
        New-CustomObject -
        foreach ($metaTestOptInItem -in $metaTestOptIn)
        {
            if ($metaTestOptIn -contains $optIn)
            {
                Write-Verbose -Message ('Repository {0} has opted in to {1}' -f $repository, $optIn)
            }
            else
            {
                Write-Verbose -Message ('Repository {0} has NOT opted in to {1}' -f $repository, $optIn)
            }
        }
    }
    else
    {
        Write-Verbose -Message ('Repository {0} has NOT opted in to {1}' -f $repository, $optIn)
    }
}
