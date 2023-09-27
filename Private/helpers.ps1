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

     Get-MgDriveItemContent -DriveId $D.parentReference.driveId -DriveItemId $D.id -OutFile $OutFilePath -Verbose

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

