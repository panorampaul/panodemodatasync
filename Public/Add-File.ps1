function Add-File {
    param ()
    $result = Test-EnvironmentVariables
    if($result) {
        Write-Host "Good to go!"
        $clientId = $env:PELM_DR_APP_ID  
$clientSecret = $env:PELM_DR_APP_SECRET
$tenantName = $env:PELM_DR_TENANT_NAME
$resource = "https://graph.microsoft.com/"  

$tokenBody = @{

    Grant_Type    = 'client_credentials'  
    Scope         = 'https://graph.microsoft.com/.default'  
    Client_Id     = $clientId  
    Client_Secret = $clientSecret
      
}  

$tokenResponse = Invoke-RestMethod -Uri "https://login.microsoftonline.com/$TenantName/oauth2/v2.0/token" -Method POST -Body $tokenBody -ErrorAction Stop

$Filepath = "Downloads/test.txt"

$Content = Get-Content -Path $Filepath
$Filename = (Get-Item -path $Filepath).Name
$ParentId = "b!unHWR0lli0mrWl0HOa531N9URVpz2GlHr4IMnfLzGLQ_OqxXB6rSRIlbjdaCrzHG"
$SiteId = "panoramdigitalltd.sharepoint.com,47d671ba-6549-498b-ab5a-5d0739ae77d4,5a4554df-d873-4769-af82-0c9df2f318b4"
$puturl = "https://graph.microsoft.com/v1.0/sites/$($SiteId)/drive/items/root:/Clauses/$($Filename):/content"

$upload_headers = @{

    "Authorization" = "Bearer $($tokenResponse.access_token)"
    "Content-Type"  = "text/plain"
}

Invoke-RestMethod -Headers $upload_headers -Uri $puturl -Body $Content -Method PUT

    }
}