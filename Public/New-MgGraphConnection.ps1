function New-MgGraphConnection {
  $result = Test-EnvironmentVariables

  if($result) {
   Connect-MgGraph -ClientId $env:PELM_DR_APP_ID -TenantId $env:PELM_DR_TENANT_ID -CertificateThumbprint $env:PELM_DR_APP_CERT_THUMBPRINT
   Get-MgContext
  }
}
