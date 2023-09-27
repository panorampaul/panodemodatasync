function UnpackFilesRecursively {
# Unpack set of items (files and folders)
param (
        [parameter(Mandatory = $true)]
        $Items, # Items to unpack
	
		[parameter(Mandatory = $true)]
        $SiteUri, # Base site URI
		
		[parameter(Mandatory = $true)]
        $FolderPath, # Folder path
		
        [parameter(Mandatory = $true)]
        $SiteFiles,
		
		[parameter(Mandatory = $false)]
		[bool]$IsNextLink
    )

  # Find sub-folders that we need to check for files
  $Folders = $Items.Value | ? {$_.Folder.ChildCount -gt 0 }
  # And any files in the folder
  $Files = $Items.Value | ? {$_.Folder.ChildCount -eq $Null}
  
  $before = $SiteFiles.count
  
  # Report the files
  ForEach ($D in $Files) {
    $FileSize = FormatFileSize $D.Size
    $OutFilePath = "Downloads/$($D.id)"
    $ReportLine       = [PSCustomObject] @{   
        FileName      = $D.Name
        Id            = $D.id
        Folder        = $FolderPath
        Author        = $D.createdby.user.displayname
        Created       = $D.createdDateTime
        Modified      = $D.lastModifiedDateTime
        Etag          = $D.eTag
        Ctag          = $D.cTag
        Size          = $FileSize
        ParentID      = $D.parentReference.id
        ParentDriveID = $D.parentReference.driveId
        Uri           = $D.WebUrl 
        OutFilePath   = $OutFilePath
        }
     $SiteFiles.Add($ReportLine) 

     Get-MgDriveItemContent -DriveId $D.parentReference.driveId -DriveItemId $D.id -OutFile $OutFilePath

  } # End If

  $NextLink = $Items."@odata.nextLink"
  $Uri = $Items."@odata.nextLink"
  While ($NextLink) { 
    $MoreData = Invoke-MgGraphRequest -Uri $Uri -Method Get
    UnpackFilesRecursively -Items $MoreData -SiteUri $SiteUri -FolderPath $FolderPath -SiteFiles $SiteFiles -IsNextLink $true
  
    $NextLink = $MoreData."@odata.nextLink"
    $Uri = $MoreData."@odata.nextLink" 
  } # End While
  
  $count = $SiteFiles.count - $before
  if (-Not $IsNextLink) {
    Write-Host "  $FolderPath ($count)"
  }
  
  # Report the files in each sub-folder
  ForEach ($Folder in $Folders) {
	$NewFolderPath = $FolderPath + "/" + $Folder.Name
	$Uri = $SiteUri + "/" + $Folder.parentReference.path + "/" + $Folder.Name + ":/children"
	$SubFolderData = Invoke-MgGraphRequest -Uri $Uri -Method Get
    UnpackFilesRecursively -Items $SubFolderData -SiteUri $SiteUri -FolderPath $NewFolderPath -SiteFiles $SiteFiles -IsNextLink $IsNextLink
  } # End Foreach Folders
}

function FormatFileSize {
# Format File Size nicely
param (
        [parameter(Mandatory = $true)]
        $InFileSize
    ) 

 If ($InFileSize -lt 1KB) { # Format the size of a document
        $FileSize = $InFileSize.ToString() + " B" } 
      ElseIf ($InFileSize -lt 1MB) {
        $FileSize = $InFileSize / 1KB
        $FileSize = ("{0:n2}" -f $FileSize) + " KB"} 
      Elseif ($InFileSize -lt 1GB) {
        $FileSize = $InFileSize / 1MB
        $FileSize = ("{0:n2}" -f $FileSize) + " MB" }
      Elseif ($InFileSize -ge 1GB) {
        $FileSize = $InFileSize / 1GB
        $FileSize = ("{0:n2}" -f $FileSize) + " GB" }
  Return $FileSize
} 

function Report-Files {
  param ()
    $defaultTenantID = "96acafad-52a3-4209-b509-f0c3eb4b7fdf"
    $TenantID = Read-Host -Prompt "Tenant ID. Press enter to accept [$($defaultTenantId)]"
    $TenantID = ($defaultTenantID, $TenantID)[[bool]$TenantID]
    $defaultSiteName = "TestOfDriveRefresh"
    $SearchSite = Read-Host -Prompt "Site Name. Press enter to accept [$($defaultSiteName)]"
    $SearchSite = ($defaultSiteName, $SearchSite)[[bool]$SearchSite]
    



  # Connect to the Microsoft Graph with the permission to read sites
  #Disconnect-MgGraph | Out-Null # Make sure that we sign out of existing sessions
  Connect-MgGraph -Scopes Sites.Read.All, Sites.FullControl.All, Sites.ReadWrite.All, Files.Read.All, Files.ReadWrite.All


  Write-Host "Looking for matching sites..."
  $Uri = 'https://graph.microsoft.com/v1.0/sites?search="' + $SearchSite + '"'
  [array]$Sites = Invoke-MgGraphRequest -Uri $uri -Method Get
  $Sites = $Sites.Value


  If (!($Sites)) { # Nothing found
       Write-Host "No matching sites found - exiting"; break }
  If ($Sites.Count -eq 1) { # Only one site found - go ahead
       $Site = $Sites
       $SiteName = $Site.DisplayName
      Write-Host "Found site to process:" $SiteName }
  Elseif ($Sites.Count -gt 1) { # More than one site found. Ask which to use
       CLS; Write-Host "More than one matching site was found. We need you to select a site to report."; [int]$i=1
       Write-Host " "
      ForEach ($SiteOption in $Sites) {
          Write-Host ("{0}: {1} ({2})" -f $i, $SiteOption.DisplayName, $SiteOption.Name); $i++}
          Write-Host ""
      [Int]$Answer = Read-Host "Enter the number of the site to use"
      If (($Answer -gt 0) -and ($Answer -le $i)) {
          [int]$Si = ($Answer-1)
          $SiteName = $Sites[$Si].DisplayName 
          Write-Host "OK. Selected site is" $Sites[$Si].DisplayName 
          $Site = $Sites[$Si] }
  }

  If (!($Site)) { 
      Write-Host ("Can't find the {0} site - script exiting" -f $Uri) ; break 
  }

  # Get Drives in the site
  Write-Host ("Checking for document libraries in the {0} site" -f $Site.DisplayName)
  $Uri = "https://graph.microsoft.com/v1.0/sites/$($Site.Id)/drives" 
  [array]$Drives = Invoke-MgGraphRequest -Uri $Uri -Method Get
  $Drives = $Drives.Value

  If (!($Drives)) { # Nothing found
       Write-Host "No matching drives found - exiting"; break }
  If ($Drives.Count -eq 1) { # Only one drive found - go ahead
       $Drive = $Drives
       $DriveName = $Drive.Name
      Write-Host "Found drive to process:" $DriveName }
  Elseif ($Drives.Count -gt 1) { # More than one drive found. Ask which to use
       CLS; Write-Host "More than one drive found in site. We need you to select a drive to report."; [int]$i=1
       Write-Host " "
      ForEach ($DriveOption in $Drives) {
        Write-Host ("{0}: {1}" -f $i, $DriveOption.Name); $i++}
        Write-Host ""
      [Int]$Answer = Read-Host "Enter the number of the drive to use"
      If (($Answer -gt 0) -and ($Answer -le $i)) {
          [int]$Si = ($Answer-1)
          $DriveName = $Drives[$Si].Name 
          Write-Host "OK. Selected drive is" $Drives[$Si].Name 
          $Drive = $Drives[$Si] }
  }

  If (!($Drive)) { 
      Write-Host ("Can't find the {0} drive - script exiting" -f $Uri) ; break 
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