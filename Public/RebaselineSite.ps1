function RebaselineSite {
    
    [CmdletBinding()]
  param(
    [Parameter(Mandatory = $false)]
    [string]$SearchSite
  )

  $defaultSiteName = "TestOfDriveRefresh"

  # Check if SearchSite parameter was not provided
  if (-not $SearchSite) {
    $SearchSite = Read-Host -Prompt "Site Name. Press enter to accept [$($defaultSiteName)]"
    $SearchSite = ($defaultSiteName,$SearchSite)[[bool]$SearchSite]
  }
  New-BaseLineForSite -SearchSite $SearchSite
  Backup-DriveItemsForSite -SearchSite $SearchSite
}