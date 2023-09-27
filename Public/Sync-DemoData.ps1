function Sync-DemoData {
  param(
    [Parameter(Mandatory = $true)]
    [string]$SiteName,
    [Parameter(Mandatory = $true)]
    [string]$DriveName

  )
  
  if (-not (Get-Module -ListAvailable -Name Microsoft.Graph)) {
    Write-Host "Microsoft.Graph is installing. Hang tight, this might take a while" -ForegroundColor Red
    Install-Module Microsoft.Graph
    Import-Module Microsoft.Graph.Sites
    Import-Module Microsoft.Graph.Files
  }

  New-MgGraphConnection

  $CachedDeltaFile = "delta/$($SiteName)_delta.json"

  $baselineExists = Test-Path -Path $CachedDeltaFile -PathType Leaf

  if($baselineExists) {
   $deltaLinkUrl = Read-DeltaLink -FilePath $CachedDeltaFile
  Write-Output "delta $($deltaLinkUrl)"

  #Get the delta of changes since the last time the baseline was built
  $Delta = Invoke-MgGraphRequest -Uri $deltaLinkUrl -Method Get
  
  Write-Output "Loading $($CachedDeltaFile)"
  $baseline = Get-Content -Path $CachedDeltaFile | ConvertFrom-Json
  if (-not $Delta.value.Count) {
     Write-Output "No changes detected"
     return
  }
  # Iterate through the value array
  foreach ($item in $Delta.value) {
    #ignore root folder as it always changes on any update
    if(-Not($item.Name -eq "root")) {
      Write-Output "Item $($item.ID)"
    }
  }
  } else {
     Write-Error "$($SiteName) has not been baselined.  File $($CachedDeltaFile) not found. Creating a baseline now..."
     New-BaselineForSite -SearchSite $SiteName
  }

 

}
