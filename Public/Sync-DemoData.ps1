function Sync-DemoData {
  param(
    [Parameter(Mandatory = $true)]
    [string]$SearchSite,
    [Parameter(Mandatory = $true)]
    [string]$DriveName,
    [Parameter(Mandatory = $true)]
    [string]$SiteId

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
    $deltaValues = @()
    $url = Read-DeltaLink -FilePath $CachedDeltaFile
    $baseline = Get-Content -Path $CachedDeltaFile | ConvertFrom-Json

    Write-Output "delta $($url)"
    do {
      #Get the delta of changes since the last time the baseline was built
      $Delta = Invoke-MgGraphRequest -Uri $url -Method Get
      $deltaJsonData = $Delta | ConvertTo-Json -Depth 10
      $deltaValues += $Delta.value
      Write-Output "$($Delta.value.Count) items found"
      $url = $Delta. "@odata.nextLink"
    } while ($null -ne $url)


    Write-Output "$($deltaValues.Count) changes since baseline"
    # Iterate through the value array
    foreach ($item in $deltaValues) {
      #ignore root folder as it always changes on any update
      if (($item.Name -eq "root")) {
        Write-Output "$($item.id) root folder updated at $($item.lastModifiedDateTime)"
      } else {
        $driveTypeValue = [DriveType]::File
        if ($($item.Folder)) {
          $driveTypeValue = [DriveType]::Folder
        }
        $crudState = [CrudState]::Added

        $restorable = [Restorable]::NotRestorable
        $BaselineItem = $baseline.value | Where-Object { $_.id -eq $item.id }

        if ($($BaselineItem)) {
          if (-not ($item.Name -eq $BaselineItem.Name)) {
            $crudState = [CrudState]::Amended
          } else {
            $crudState = [CrudState]::NoAction
          }

        }

        $baselineFileExists = Test-Path -Path "Downloads/$($item.id)" -PathType Leaf
        $ParentItemFromDelta = $deltaValues | Where-Object { $_.id -eq $BaselineItem.parentReference.id }
        if ($($BaselineItem) -and ($item.Folder -or $baselineFileExists)) {
          $restorable = [Restorable]::HasParent

          if ($ParentItemFromDelta.Deleted) {
            $restorable = [Restorable]::NoParent
          }
        }


        if ($($item.Deleted)) {
          $crudState = [CrudState]::Deleted

        }

        #Write-Output "$($item.id) $driveTypeValue, $crudState, $restorable"
        switch ($crudState) {
          ([CrudState]::Added) {
            Delete-File -DriveTypeValue $driveTypeValue -Id $item.id -SiteID $SiteId
          }
          ([CrudState]::Amended) {
            Amend-File -DriveTypeValue $driveTypeValue -Id $item.id -SiteID $SiteId -FileName $BaselineItem.Name
          }
          ([CrudState]::Deleted) {
            if ($restorable -eq [Restorable]::HasParent) {
              if ($driveTypeValue -eq [DriveType]::Folder) {
                Restore-Folder -FileName $BaselineItem.Name -SiteID $SiteId -DriveItemId $BaselineItem.parentReference.id
              } else {
                Write-Output "$($item.id) $driveTypeValue, $crudState, $restorable $($BaselineItem.id)"
              }
            }
          }
        }
      }
    }
  } else {
    Write-Error "$($SearchSite) has not been baselined.  File $($CachedDeltaFile) not found. Creating a baseline now..."
    New-BaselineForSite -SearchSite $SearchSite
  }



}
