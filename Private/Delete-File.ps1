function Delete-File {
  param(
    [string]$SiteID,
    [DriveType]$DriveTypeValue,
    [string]$Id

  )

  try {

    $url = "https://graph.microsoft.com/v1.0/sites/$($SiteID)/drive/items/$($Id)"

    $result = Invoke-MgGraphRequest -Uri $url -Method Delete

    Write-Output "Delete-File completed$($result)"
  } catch {
    # Check if the error is a web exception
    if ($_.Exception.Response) {
      $statusCode = $_.Exception.Response.StatusCode

      # Check for specific status codes
      switch ($statusCode) {
        'Conflict' {
          Write-Output "Delete-File Conflict error occurred: 409 run sync again until this clears"
          # Handle the 409 status code
        }
        'Locked' {
          Write-Output "Delete-File Resource is locked error: 423 ensure file or folder is not open"
          # Handle the 423 status code
        }
        default {
          Write-Output "Delete-File An unexpected error occurred: $statusCode"
        }
      }
    }
    else {
      Write-Output "Delete-File An error occurred: $($_.Exception.Message)"
    }
  }


}
