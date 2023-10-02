function Amend-File {
  param(
    [string]$$SiteId,
    [DriveType]$DriveTypeValue,
    [string]$Id,
    [string]$FileName
  )

  try {

    $jsonData = @"
{
    "name": "$FileName"
}
"@

    $url = "https://graph.microsoft.com/v1.0/sites/$($$SiteId)/drive/items/$($Id)"

    $result = Invoke-MgGraphRequest -Uri $url -Method Patch -Body $jsonData -ContentType "application/json"

    Write-Output "Amend-File completed"
  } catch {
    # Check if the error is a web exception
    if ($_.Exception.Response) {
      $statusCode = $_.Exception.Response.StatusCode

      # Check for specific status codes
      switch ($statusCode) {
        'Conflict' {
          Write-Output "Amend-File Conflict error occurred: 409 run sync again until this clears"
          # Handle the 409 status code
        }
        'Locked' {
          Write-Output "Amend-File Resource is locked error: 423 ensure file or folder is not open"
          # Handle the 423 status code
        }
        default {
          Write-Output "Amend-File An unexpected error occurred: $statusCode"
        }
      }
    }
    else {
      Write-Output "Amend-File An error occurred: $($_.Exception.Message)"
    }
  }


}
