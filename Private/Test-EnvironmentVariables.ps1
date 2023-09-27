function Test-EnvironmentVariables {
    # List of environment variables to check
    $variablesToCheck = @("PELM_DR_APP_ID","PELM_DR_APP_CERT_THUMBPRINT", "PELM_DR_APP_SECRET","PELM_DR_TENANT_ID","PELM_DR_TENANT_NAME" )

    foreach ($var in $variablesToCheck) {
        if (-not (Get-Content "env:$var")) {
            Write-Error "Environment variable $var is not populated. Exiting function."
            return $false
        }
    }

    # Rest of your function code
    Write-Host "All environment variables are populated!"
    return $true
}