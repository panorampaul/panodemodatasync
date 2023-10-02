function Add-File {
  param(
    [Parameter(Mandatory = $true)]
    $InFilePath,

  [Parameter(Mandatory = $true)]
    $SiteId,

     [Parameter(Mandatory = $true)]
    $FolderId,

    [Parameter(Mandatory = $true)]
    $FileName
  )
  $result = Test-EnvironmentVariables
  New-MgGraphConnection
  if ($result) {
    Write-Host "Good to go!"
    $clientId = $env:PELM_DR_APP_ID
    $clientSecret = $env:PELM_DR_APP_SECRET
    $tenantName = $env:PELM_DR_TENANT_NAME
    $resource = "https://graph.microsoft.com/"

    $tokenBody = @{

      Grant_Type = 'client_credentials'
      Scope = 'https://graph.microsoft.com/.default'
      Client_Id = $clientId
      Client_Secret = $clientSecret

    }

    $tokenResponse = Invoke-RestMethod -Uri "https://login.microsoftonline.com/$TenantName/oauth2/v2.0/token" -Method POST -Body $tokenBody -ErrorAction Stop

    $headers = @{

      "Authorization" = "Bearer $($tokenResponse.access_token)"
      "Content-Type" = "application/json"
    }

    $Content = Get-Content -Path $InFilePath

    $puturl = "https://graph.microsoft.com/v1.0/sites/$($SiteId)$($FolderId)/$($Filename):/content"

    Write-Host "$($puturl)"
    $upload_headers = @{

      "Authorization" = "Bearer $($tokenResponse.access_token)"
      "Content-Type" = "multipart/form-data"
    }

    Invoke-RestMethod -Headers $upload_headers -Uri $puturl -InFile $InFilePath -Method PUT -ContentType 'multipart/form-data' -Verbose

  }
}
