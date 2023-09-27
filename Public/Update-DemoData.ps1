function Update-DemoData {
    param (
        [Parameter(Mandatory=$true)]
        [string]$FilePath
    )
    $deltaLinkUrl = Read-DeltaLink -FilePath $FilePath

    if ( -Not (Get-Module -ListAvailable -Name Microsoft.Graph)) {
        Write-Host "Microsoft.Graph is installing. Hang tight, this might take a while" -ForegroundColor Red
        Install-Module Microsoft.Graph
        Import-Module Microsoft.Graph.Sites
        Import-Module Microsoft.Graph.Files
    }

    
    
    Write-Output "Link:  $($deltaLinkUrl)"

    New-MgGraphConnection
    
    $Delta = Invoke-MgGraphRequest -Uri $deltaLinkUrl -Method Get
    $baseline = Get-Content -Path 'delta/delta.json' | ConvertFrom-Json
   # Iterate through the value array
    foreach ($item in $Delta.value) {
        # Print details for each item or take any required action. Ignore root changes as there is ALWAYS root changes
        if (-Not ($item.name -eq 'root')) {   
            if ($item.deleted.state -eq 'deleted') {
                $deletedItem = $baseline.value | Where-Object { $_.id -eq $item.id}
                
                Write-Output "Deleted: $($deletedItem.name)"
                Write-Output "ID: $($deletedItem.id)"

                $filePath = "Downloads\$($deletedItem.id)"
                $ParentDriveID = "$($deletedItem.parentReference.driveId)"
                #Write-Output "drive $($ParentDriveID)"
                $fileName = "$($deletedItem.name)"

                $fileExists = Test-Path -Path $filePath -PathType Leaf
                
                if($filePath) {
                    Write-Output "$($deletedItem.name) exists and can be restored"
                } else {
                    Write-Output "no backup for $($item.name). unable to restore "
                }

                
            } else {
                Write-Output "Name: $($item.name)"
                Write-Output "ID: $($item.id)"
            }
            Write-Output "--------------------------------------------"
        }
       
    }

}