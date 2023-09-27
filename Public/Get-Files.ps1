function Get-Files {
  param()
  $defaultTenantID = "96acafad-52a3-4209-b509-f0c3eb4b7fdf"
  $TenantID = Read-Host -Prompt "Tenant ID. Press enter to accept [$($defaultTenantId)]"
  $TenantID = ($defaultTenantID,$TenantID)[[bool]$TenantID]
  $defaultSiteName = "TestOfDriveRefresh"
  $SearchSite = Read-Host -Prompt "Site Name. Press enter to accept [$($defaultSiteName)]"
  $SearchSite = ($defaultSiteName,$SearchSite)[[bool]$SearchSite]




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
    $SiteName = $Site.DisplayName
    Write-Host "Found site to process:" $SiteName }
  elseif ($Sites.Count -gt 1) { # More than one site found. Ask which to use
    Clear-Host; Write-Host "More than one matching site was found. We need you to select a site to report."; [int]$i = 1
    Write-Host " "
    foreach ($SiteOption in $Sites) {
      Write-Host ("{0}: {1} ({2})" -f $i,$SiteOption.DisplayName,$SiteOption.Name); $i++ }
    Write-Host ""
    [int]$Answer = Read-Host "Enter the number of the site to use"
    if (($Answer -gt 0) -and ($Answer -le $i)) {
      [int]$Si = ($Answer - 1)
      $SiteName = $Sites[$Si].DisplayName
      Write-Host "OK. Selected site is" $Sites[$Si].DisplayName
      $Site = $Sites[$Si] }
  }

  if (!($Site)) {
    Write-Host ("Can't find the {0} site - script exiting" -f $Uri); break
  }

  # Get Drives in the site
  Write-Host ("Checking for document libraries in the {0} site" -f $Site.DisplayName)
  $Uri = "https://graph.microsoft.com/v1.0/sites/$($Site.Id)/drives"
  [array]$Drives = Invoke-MgGraphRequest -Uri $Uri -Method Get
  $Drives = $Drives.value

  if (!($Drives)) { # Nothing found
    Write-Host "No matching drives found - exiting"; break }
  if ($Drives.Count -eq 1) { # Only one drive found - go ahead
    $Drive = $Drives
    $DriveName = $Drive.Name
    Write-Host "Found drive to process:" $DriveName }
  elseif ($Drives.Count -gt 1) { # More than one drive found. Ask which to use
    Clear-Host; Write-Host "More than one drive found in site. We need you to select a drive to report."; [int]$i = 1
    Write-Host " "
    foreach ($DriveOption in $Drives) {
      Write-Host ("{0}: {1}" -f $i,$DriveOption.Name); $i++ }
    Write-Host ""
    [int]$Answer = Read-Host "Enter the number of the drive to use"
    if (($Answer -gt 0) -and ($Answer -le $i)) {
      [int]$Si = ($Answer - 1)
      $DriveName = $Drives[$Si].Name
      Write-Host "OK. Selected drive is" $Drives[$Si].Name
      $Drive = $Drives[$Si] }
  }

  if (!($Drive)) {
    Write-Host ("Can't find the {0} drive - script exiting" -f $Uri); break
  }


  # Use the selected drive
  $DocumentLibrary = $Drive

  $SiteUri = "https://graph.microsoft.com/v1.0/sites/$($Site.Id)"
  $Uri = "$SiteUri/drives/$($DocumentLibrary.Id)/root/children"



  # Create output list
  $SiteFiles = [System.Collections.Generic.List[Object]]::new()

  Write-Host "Reading: $Uri"

  # Get Items in document library
  [array]$Items = Invoke-MgGraphRequest -Uri $Uri -Method Get

  UnpackFilesRecursively -Items $Items -SiteUri $SiteUri -FolderPath $DocumentLibrary.Name -SiteFiles $SiteFiles

  Write-Host ("Total files found {0}" -f $SiteFiles.Count)
  $SiteFiles

  $jsonData = $SiteFiles | ConvertTo-Json
  $jsonPath = "delta/$($SearchSite)_$($DriveName)_files.json"
  $jsonData | Set-Content -Path $jsonPath

  # Create a baseline
  Write-Output "Site $($Site.Id)"
  $Uri = "https://graph.microsoft.com/v1.0/sites/$($Site.Id)/drive/root/delta"
  $Delta = Invoke-MgGraphRequest -Uri $Uri -Method Get
  $jsonData = $Delta | ConvertTo-Json -Depth 10
  $jsonPath = "delta/$($SearchSite)_delta.json"
  $jsonData | Set-Content -Path $jsonPath

}
