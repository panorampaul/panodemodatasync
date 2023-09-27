function Copy-Site {
    param ()
    $defaultTenantID = "96acafad-52a3-4209-b509-f0c3eb4b7fdf"
    $TenantID = Read-Host -Prompt "Tenant ID. Press enter to accept [$($defaultTenantId)]"
    $TenantID = ($defaultTenantID, $TenantID)[[bool]$TenantID]
    $defaultSiteName = "TestOfDriveRefresh"
    $SiteName = Read-Host -Prompt "Site Name. Press enter to accept [$($defaultSiteName)]"
    $SiteName = ($defaultSiteName, $SiteName)[[bool]$SiteName]
    $defaultBackupSiteName = "TestOfDriveRefreshClone"
    $BackupSiteName = Read-Host -Prompt "Backup Site Name. Press enter to accept [$($defaultBackupSiteName)]"
    $BackupSiteName = ($defaultBackupSiteName, $BackupSiteName)[[bool]$BackupSiteName]
    

    Write-Host "Clone-Site tenant id: $TenantId site: $SiteName" 

    if ( -Not (Get-Module -ListAvailable -Name Microsoft.Graph)) {
        Write-Host "Microsoft.Graph is installing. Hang tight, this might take a while" -ForegroundColor Red
        Install-Module Microsoft.Graph
    
    }

    if ($ImportMSGraph -eq "y") {
        Import-Module Microsoft.Graph
    }

    Connect-MgGraph -TenantId $TenantID -Scopes 'Sites.FullControl.All', 'Sites.ReadWrite.All'

    $ID = Get-MgSite -Search $SiteName | Select-Object -ExpandProperty Id

    #$BID = Get-MgSite -Search $BackupSiteName | Select-Object -ExpandProperty Id

    #Get-MgSiteDrive -SiteId $ID | Select-Object -ExpandProperty Id

    #$DriveItems = Get-MgDriveRootDelta -DriveID "b!unHWR0lli0mrWl0HOa531N9URVpz2GlHr4IMnfLzGLQ_OqxXB6rSRIlbjdaCrzHG" | Select-Object -ExpandProperty Id

    #foreach($item in $DriveItems) {
    #    Write-Host "Item $item"
    #    Get-MgDriveItem -DriveId $ID -DriveItemId $item -ExpandProperty "children"
    #}

    $Uri = "https://graph.microsoft.com/v1.0/sites/$ID/drive/root/delta"
    $Delta = Invoke-MgGraphRequest -Uri $Uri -Method Get
    $jsonData = $Delta | ConvertTo-Json -Depth 10
    $jsonPath = "delta/delta.json"
    $jsonData | Set-Content -Path $jsonPath

 }