function Read-DeltaLink {
    param (
        [Parameter(Mandatory=$true)]
        [string]$FilePath
    )

    # Check if file exists
    if (-not (Test-Path $FilePath)) {
        Write-Error "File not found: $FilePath"
        return
    }

    # Read the file content and parse JSON
    $jsonContent = Get-Content -Path $FilePath | ConvertFrom-Json

    # Extract @odata.deltaLink
    $deltaLink = $jsonContent.'@odata.deltaLink'

    if ($deltaLink) {
        return $deltaLink
    } else {
        Write-Error "@odata.deltaLink not found in the JSON data"
        return
    }
}