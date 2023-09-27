Function Invoke-MSGraphUpload {
    param(
        [parameter(Mandatory = $true)]$FullPath,
        [parameter(Mandatory = $true)]$UploadUri)

    $AuthHeader = @{
        'Content-Type'  = 'application/json'
        'Authorization' = "Bearer $($global:AuthToken.access_token)"
    }

    $Checksum = (Get-FileHash -Path $FullPath).Hash

    $Body = @{
        'item' = @{
            '@microsoft.graph.conflictBehavior' = "replace"
        }
    }

    $Body = $Body | ConvertTo-Json -Compress

    $Response = Invoke-MgGraphRequest -Uri $UploadUri -Method Post -Body $Body

    #Fragments
    <#
        https://learn.microsoft.com/en-us/graph/api/driveitem-createuploadsession?view=graph-rest-1.0
        To upload the file, or a portion of the file, your app makes a PUT request to the uploadUrl value received 
        in the createUploadSession response. You can upload the entire file, or split the file into multiple byte ranges, 
        as long as the maximum bytes in any given request is less than 60 MiB.

        The fragments of the file must be uploaded sequentially in order. Uploading fragments out of order will result in an error.

        Note: If your app splits a file into multiple byte ranges, the size of each byte range MUST be a multiple of 320 KiB (327,680 bytes). 
        Using a fragment size that does not divide evenly by 320 KiB will result in errors committing some files.
    #>

    If ($Response.StatusCode -eq "200") {
        $ChunkSize = 62259200
        $file = New-Object System.IO.FileInfo($FullPath)
        $reader = [System.IO.File]::OpenRead($FullPath)
        $buffer = New-Object -TypeName Byte[] -ArgumentList $ChunkSize
        $position = 0
        $counter = 0
        Write-Host "ChunkSize: $ChunkSize" -ForegroundColor Cyan
        Write-Host "BufferSize: $($buffer.Length)" -ForegroundColor Cyan
        $moreData = $true
        While($moreData) {
            #Read a chunk
            $bytesRead = $reader.Read($buffer, 0, $buffer.Length)
            $output = $buffer
            If($bytesRead -ne $buffer.Length) {
                #no more data to be read
                $moreData = $false
                #shrink the output array to the number of bytes
                $output = New-Object -TypeName Byte[] -ArgumentList $bytesRead
                [Array]::Copy($buffer, $output, $bytesRead)
                Write-Host "no more data" -ForegroundColor Yellow
            }
            #Upload the chunk
            $Header = @{
                'Content-Length' = $($output.Length)
                'Content-Range'  = "bytes $position-$($position + $output.Length - 1)/$($file.Length)"
            }

            Write-Host "Content-Length = $($output.Length)" -ForegroundColor Cyan
            Write-Host "Content-Range  = bytes $position-$($position + $output.Length - 1)/$($file.Length)" -ForegroundColor Cyan
            #$position = $position + $output.Length - 1
            $position = $position + $output.Length
            Invoke-MgGraphRequest -Method Put -Uri $Response.uploadUrl -Body $output -Headers $Header -ContentType "application/octet-stream"
            #Increment counter
            $counter++
        }
        $reader.Close()
    }
}