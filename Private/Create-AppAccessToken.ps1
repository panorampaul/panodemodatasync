function Create-AppAccessToken {
  param(

  )

  $result = Test-EnvironmentVariables
  if ($result) {
    Write-Host "Good to go!"
    $clientId = $env:PELM_DR_APP_ID
    $clientSecret = $env:PELM_DR_APP_SECRET
    $tenantId = $env:PELM_DR_TENANT_NAME
    
    $tokenBody = @{

      Grant_Type = 'client_credentials'
      Scope = 'https://graph.microsoft.com/.default'
      Client_Id = $clientId
      Client_Secret = $clientSecret

    }

    $tokenResponse = Invoke-RestMethod -Uri "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token" -Method POST -Body $tokenBody -ErrorAction Stop

    Write-Host "Returning token $($tokenResponse.access_token)"

    return $tokenResponse.access_token

  } else {
    return
  }
}
