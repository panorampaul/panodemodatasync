## Introduction

Script to implement [a restoration process for Panoram Demos](https://panoramdigital.atlassian.net/jira/software/c/projects/DVOP/issues/DVOP-122)

## Setup

### Azure App Registration

The scripts use an app registered in [Azure](https://portal.azure.com/#view/Microsoft_AAD_RegisteredApps/ApplicationMenuBlade/~/Overview/appId/d97b0e58-0949-4003-b5e5-6a8757250cdb/isMSAApp~/false) The script uses a self signed certificate for authentication (see below) the certificate expires on 26/09/2024

### AWS

#### Credentials

The script uses the current credentials for the machine/user running the script. Set up your AWS CLI and credentials before running the script.

### Certificate

Import the certificate from [S3](https://devops-eu-west-tools.s3.eu-west-2.amazonaws.com/panodemodatasync.p12)

### Environment Variables

Set up your environment variables. You can obtain the values from AWS Secrets Managerarn:aws:secretsmanager:eu-west-2:659554164570:secret:panodemodatasync_env_vars-EZ6lju

```
export PELM_DR_APP_ID=XXXX
export PELM_DR_APP_SECRET=XXXX
export PELM_DR_TENANT_ID=XXXX
export PELM_DR_SITE_ID=TestOfDriveRefresh
export PELM_DR_TENANT_NAME=panoramdigitalltd.onmicrosoft.com
export PELM_DR_APP_CERT_THUMBPRINT=1AE71B50CFCB614A82422F9EFB9D0C493DACF534
```

## Running

### Syncing Sharepoint

* Open Powershell
* Run `./importModule.ps1`
* Run `RebaselineSite` This will take a copy of the site and save a delta of the site state as well as all the files
* Make some changes to the site
* Run `Sync-DemoData` This will reset the site back to the delta/baseline and recreate a new baseline

### Restoring the MySQL database 

* Open Powershell
* Run `./importModule.ps1`
* Run `Restore-PanoDemoDatabase` 
The script will error if the AWS credentials used are missing or insufficient for AWS RDS.  Otherwise it will rename the current database, restore the 'good' snapshot and rename it.  This process takes around 15 minutes to complete.

## Notes

Run the following to format the code
```powershell
Install-Module -Name PowerShell-Beautifier
Edit-DTWBeautifyScript FILELOCATION

