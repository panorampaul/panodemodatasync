function Restore-PanoDemoDatabase {
    param()
   
    # Check AWS credentials
    Write-Host "Step 1: ensure prereqs are installed and do a non destructive AWS command to test the setup works"
    try {
        if (-Not (Get-Module -ListAvailable -Name AWS.Tools.Common)) {
            Write-Host "AWS.Tools is installing.  This may take a while."
            Install-Module -Name AWS.Tools.Installer
            Import-Module AWS.Tools.Common
        } else {
            Write-Host "AWS tools are installed." -ForegroundColor Green
        }
        Get-AWSCmdletName -ApiOperation DescribeInstances
        
    } catch {
        Write-Host "Error verifying AWS credentials: $_" -ForegroundColor Red
        exit
    }
    Write-Host "AWS credentials verified successfully." -ForegroundColor Green
    # Set AWS region
    $region = "eu-west-2"  # Change this to your region
    # Rename the existing RDS instance
    $instanceID = "demo-panoram-server"
    $copyInstanceID = "$instanceID-old"
    $snapshotID = "arn:aws:rds:eu-west-2:659554164570:snapshot:chrisopanodemospecialbackup15september2023"
    Write-Host "Step 2: rename $instanceID to $copyInstanceID"
    # Rename RDS instance
    Edit-RDSDBInstance -Region $region -DBInstanceIdentifier $instanceID -NewDBInstanceIdentifier $copyInstanceID -ApplyImmediately 1
    Write-Host "Edit command issued. Will now wait/loop for 60 seconds until $copyInstanceID appears"
    #Monitor the RDS instance until the renaming operation is complete
    do {
        Start-Sleep -Seconds 60
        try {
            $status = Get-RDSDBInstance -Region $region -DBInstanceIdentifier $copyInstanceID | Select-Object -ExpandProperty DBInstanceStatus
            Write-Host "$copyInstanceID Current status: $status"
        } catch {
            Write-Host "$copyInstanceID Current status: in progress"
        }
        
    } while ($status -ne "available")

    #Restore the DB instance from the snapshot
    Write-Host "Step 3: create a new instance $instanceID from the snapshot called chrisopanodemospecialbackup15september2023."
    Restore-RDSDBInstanceFromDBSnapshot -Region $region -DBSnapshotIdentifier $snapshotID -DBInstanceIdentifier $instanceID -PubliclyAccessible 1 -VpcSecurityGroupId sg-06cdd9696c6fc8478 -DBSubnetGroupName dbsubnet-c576be5

    Write-Host "DB instance restoration initiated. Will now wait/loop for 60 seconds"

    do {
        Start-Sleep -Seconds 60
        $status = Get-RDSDBInstance -Region $region -DBInstanceIdentifier $instanceID | Select-Object -ExpandProperty DBInstanceStatus
        Write-Host "$instanceID Current status: $status"
    } while ($status -ne "available")

    #Delete the DB instance from the snapshot
    Write-Host "Step 4: delete the instance $copyInstanceID"
    Remove-RDSDBInstance -DBInstanceIdentifier $copyInstanceID -SkipFinalSnapshot 1 -Confirm:$false
    Write-Host "Restoration completed"
}
