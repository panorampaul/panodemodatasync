function Copy-Site {
    param ()
    $defaultSiteName = "TestOfDriveRefresh"
    $SearchSite = Read-Host -Prompt "Site Name. Press enter to accept [$($defaultSiteName)]"
    $SearchSite = ($defaultSiteName, $SearchSite)[[bool]$SearchSite]
    $defaultBackupSiteName = "TestOfDriveRefreshClone"
    $BackupSiteName = Read-Host -Prompt "Backup Site Name. Press enter to accept [$($defaultBackupSiteName)]"
    $BackupSiteName = ($defaultBackupSiteName, $BackupSiteName)[[bool]$BackupSiteName]
    

    Write-Host "Clone-Site tenant id: $TenantId site: $SearchSite" 

    if ( -Not (Get-Module -ListAvailable -Name Microsoft.Graph)) {
        Write-Host "Microsoft.Graph is installing. Hang tight, this might take a while" -ForegroundColor Red
        Install-Module Microsoft.Graph
    
    }

    if ($ImportMSGraph -eq "y") {
        Import-Module Microsoft.Graph
    }

    New-MgGraphConnection
    
    $ID = Get-MgSite -Search $SearchSite | Select-Object -ExpandProperty Id

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