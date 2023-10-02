function Sync-DemoData {
  param(
    [Parameter(Mandatory = $true)]
    [string]$SearchSite,
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

  $CachedDeltaFile = "delta/$($SearchSite)_baseline.json"

  $baselineFileExists = Test-Path -Path $CachedDeltaFile -PathType Leaf

  if ($baselineFileExists) {
    $deltaLinkUrl = Read-DeltaLink -FilePath $CachedDeltaFile
    Write-Output "delta $($deltaLinkUrl)"

    #Get the delta of changes since the last time the baseline was built
    $Delta = Invoke-MgGraphRequest -Uri $deltaLinkUrl -Method Get

    Write-Output "Loading $($CachedDeltaFile)"
    $baseline = Get-Content -Path $CachedDeltaFile | ConvertFrom-Json

    $deltaJsonData = $Delta | ConvertTo-Json -Depth 10
    $deltaJsonPath = "delta/$($SearchSite)_delta.json"
    $deltaJsonData | Set-Content -Path $deltaJsonPath

    Write-Output "Delta saved to $($deltaJsonPath)"
    if (-not $Delta.value.Count) {
      Write-Output "No changes detected"
      return
    }
    Write-Output "$($Delta.value.Count) changes since baseline"
    # Iterate through the value array
    foreach ($item in $Delta.value) {
      #ignore root folder as it always changes on any update
      if (-not ($item.Name -eq "root")) {
        $driveTypeValue = [DriveType]::File
        if ($($item.Folder)) {
          $driveTypeValue = [DriveType]::Folder
        }
        $crudState = [CrudState]::Added

        $restorable = [Restorable]::NotRestorable
        $BaselineItem = $baseline.value | Where-Object { $_.id -eq $item.id }
        
        if ($($BaselineItem)) {
          $crudState = [CrudState]::Amended
        }

        $baselineFileExists = Test-Path -Path "Downloads/$($item.id)" -PathType Leaf
        $ParentItemFromDelta = $Delta.value | Where-Object { $_.id -eq $BaselineItem.parentReference.id }
        if ($($BaselineItem) -and ($item.Folder -or $baselineFileExists)) {
          $restorable = [Restorable]::HasParent
          
          if ($ParentItemFromDelta.Deleted) {
            $restorable = [Restorable]::NoParent
          }
        }


        if ($($item.Deleted)) {
          $crudState = [CrudState]::Deleted
          
        }

        #Write-Output "$($item.id) $crudState, $restorable"
        switch ($crudState) {
          ([CrudState]::Added) {
            Delete-File -DriveTypeValue $driveTypeValue -Id $item.id -DriveID $item.parentReference.driveId

          }
          ([CrudState]::Amended) {
            #Write-Output "To amend: $($item.id)"
          }
          ([CrudState]::Deleted) {
            #Write-Output "To restore: $($item.id)"
          }
        }



      }
    }
  } else {
    Write-Error "$($SearchSite) has not been baselined.  File $($CachedDeltaFile) not found. Creating a baseline now..."
    New-BaselineForSite -SearchSite $SearchSite
  }



}
