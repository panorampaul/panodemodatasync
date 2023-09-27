function New-MgGraphConnection {
  param(
    [bool]$ShowContext = $false
  )
  $result = Test-EnvironmentVariables

  if ($result) {
    $existingConnection = Get-MgContext

    if (-not ($existingConnection)) {
      Connect-MgGraph -ClientId $env:PELM_DR_APP_ID -TenantId $env:PELM_DR_TENANT_ID -CertificateThumbprint $env:PELM_DR_APP_CERT_THUMBPRINT
    }
    if ($ShowContext) {
      Get-MgContext
    }
  }
}
