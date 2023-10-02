function New-BaselineForSite {
 
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

  # Connect to the Microsoft Graph with the permission to read sites
  New-MgGraphConnection

  Write-Host "Looking for matching sites..."
  $Uri = "https://graph.microsoft.com/v1.0/sites?search=$($SearchSite)"
  [array]$Sites = Invoke-MgGraphRequest -Uri $uri -Method Get
  $Sites = $Sites.value


  if (!($Sites)) { # Nothing found
    Write-Host "No matching sites found - exiting"; break }
  if ($Sites.Count -eq 1) { # Only one site found - go ahead
    $Site = $Sites
    $SearchSite = $Site.DisplayName
    Write-Host "Found site to process:" $SearchSite }
  elseif ($Sites.Count -gt 1) { # More than one site found. Ask which to use
    Clear-Host; Write-Host "More than one matching site was found. We need you to select a site to report."; [int]$i = 1
    Write-Host " "
    foreach ($SiteOption in $Sites) {
      Write-Host ("{0}: {1} ({2})" -f $i,$SiteOption.DisplayName,$SiteOption.Name); $i++ }
    Write-Host ""
    [int]$Answer = Read-Host "Enter the number of the site to use"
    if (($Answer -gt 0) -and ($Answer -le $i)) {
      [int]$Si = ($Answer - 1)
      $SearchSite = $Sites[$Si].DisplayName
      Write-Host "OK. Selected site is" $Sites[$Si].DisplayName
      $Site = $Sites[$Si] }
  }

  if (!($Site)) {
    Write-Host ("Can't find the {0} site - script exiting" -f $Uri); break
  }

  # Create a baseline
  Write-Output "Site $($Site.Id)"
  $Uri = "https://graph.microsoft.com/v1.0/sites/$($Site.Id)/drive/root/delta"
  $Delta = Invoke-MgGraphRequest -Uri $Uri -Method Get
  $jsonData = $Delta | ConvertTo-Json -Depth 10
  $jsonPath = "delta/$($SearchSite)_baseline.json"
  $jsonData | Set-Content -Path $jsonPath

}
