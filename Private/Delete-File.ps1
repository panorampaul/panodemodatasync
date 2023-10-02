function Delete-File {
    param (
        [DriveType]$DriveTypeValue,
        [string] $Id,
        [string] $DriveID
    )

      if($DriveTypeValue -eq [DriveType]::File) {
              Write-Output "Delete-File file: $($Id) $($DriveID)"
            } else {
              Write-Output "Delete-File folder: $($Id) $($DriveID)"
            }
}