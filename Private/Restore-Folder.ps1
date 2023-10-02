function Restore-Folder {
  param(
    [Parameter(Mandatory = $true)]
    $FileName,

    [Parameter(Mandatory = $true)]
    $SiteId,

    [Parameter(Mandatory = $true)]
    $DriveItemId

  )

  $params = @"
{
  "name": "$FileName",
  "folder": { },
  "@microsoft.graph.conflictBehavior": "replace"
}
"@




  #POST /sites/{site-id}/drive/items/{parent-item-id}/children

  $url = "https://graph.microsoft.com/v1.0/sites/$($SiteId)/drive/items/$($DriveItemId)/children"


  $result = Invoke-MgGraphRequest -Uri $url -Method POST -Body $params -ContentType "application/json"

  Write-Output "Restore-Folder renamed $FileName $($result.id)"

}
