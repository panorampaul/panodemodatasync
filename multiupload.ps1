$clientId = "d97b0e58-0949-4003-b5e5-6a8757250cdb"
$clientSecret = "Zwy8Q~K7m-6uA3Ks0xhfMGG9XS4Q-SA5Wg5bnbvR"
$tenantName = "panoramdigitalltd.onmicrosoft.com"
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

$Filepath = "Downloads/testfile.docx"

$Content = Get-Content -Path $Filepath
$Filename = (Get-Item -Path $Filepath).Name


$URL = "https://graph.microsoft.com/v1.0/sites?search=TestOfDriveRefresh"


[array]$Sites = Invoke-RestMethod -Headers $headers -Uri $URL -Method Get

$Sites = $Sites.value

if (!($Sites)) {
  Write-Host "No Matching sites"
}
elseif ($Sites.Count -eq 1) {
  $Site = $Sites
  $SiteName = $Site.DisplayName
  Write-Host "Found site to process:" $SiteName

  $URL = "https://graph.microsoft.com/v1.0/sites/$($Site.ID)/drives"

  Write-Host "url $($URL)"

  [array]$Drives = Invoke-RestMethod -Headers $headers -Uri $URL -Method Get

  $Drives = $Drives.value


  if (!($Drives)) {
    Write-Host "No Matching drives"
  }
  elseif ($Drives.Count -eq 1) {
    $Drive = $Drives
    $DriveName = $Drive.Name
    Write-Host "Found drive to process:" $DriveName
  }
  else {
    Write-Host "Multiple drives $($Drives)"
    foreach ($Drive in $Drives) {
      if ($Drive.Name -eq "Documents") {
        $upload_session = "https://graph.microsoft.com/v1.0/drives/$($Drive.ID)/root:/Clauses/$($Filename):/createUploadSession"

        $upload_session_url = (Invoke-RestMethod -Uri $upload_session -Headers $headers -Method Post).uploadUrl

        #Write-Host "$($upload_session_url)"
        $ChunkSize = 62259200
        $file = New-Object System.IO.FileInfo ($Filepath)
        $reader = [System.IO.File]::OpenRead($Filepath)
        $buffer = New-Object -TypeName Byte[] -ArgumentList $ChunkSize
        $position = 0
        $counter = 0

        Write-Host "ChunkSize: $ChunkSize" -ForegroundColor Cyan
        Write-Host "BufferSize: $($buffer.Length)" -ForegroundColor Cyan

        $moreData = $true


        while ($moreData) {
          #Read a chunk
          $bytesRead = $reader.Read($buffer,0,$buffer.Length)
          $output = $buffer
          if ($bytesRead -ne $buffer.Length) {
            #no more data to be read
            $moreData = $false
            #shrink the output array to the number of bytes
            $output = New-Object -TypeName Byte[] -ArgumentList $bytesRead
            [array]::Copy($buffer,$output,$bytesRead)
            Write-Host "no more data $($bytesRead)" -ForegroundColor Yellow
          }
          $RangeString = "bytes $position-$($position + $output.Length - 1)/$($file.Length)"
          #Upload the chunk
          Write-Host "Content-Length = $($output.Length)" -ForegroundColor Cyan
          Write-Host "Content-Range  = $($RangeString)" -ForegroundColor Cyan
          $Header = @{
            'Content-Length' = $($output.Length)
            'Content-Range' = $($RangeString)
            'Content-Type' = 'application/octet-stream'
          }

          $position = $position + $output.Length
          Invoke-RestMethod -Method Put -Uri $upload_session_url -Body $output -Headers $Header -SkipHeaderValidation
          #Increment counter
          $counter++
        }
        $reader.Close()


      }
    }
  }

} else {
  Write-Host "Multiple sites"
}




#$Filename = (Get-Item -Path $Filepath).Name

#Write-Host "$Document_drive_ID"
