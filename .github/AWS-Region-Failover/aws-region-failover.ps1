Write-Host "Set AWS Info"

# Please Update the vb-aws-info.csv for your settings
$vbawsCSV = "C:\VRO\CSVs\vb-aws-info.csv" #CSV File to read from.
$vbawsInfo = Import-Csv $vbawsCSV

[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$Env:AWS_ACCESS_KEY_ID=$vbawsInfo.accessKey
$Env:AWS_SECRET_ACCESS_KEY=$vbawsInfo.secretKey
$Env:AWS_DEFAULT_REGION=$vbawsInfo.region

# Name of VB AWS Appliance in AWS
$name = $vbawsInfo.vbawsName

# Get Public IP address of VB AWS Appliance
$vbAwsInstance = aws ec2 describe-instances --filters "Name=tag-value,Values=$name" | ConvertFrom-Json
$url = $vbAwsInstance.Reservations.Instances.PublicIpAddress

# Set the URL and token URL
$base = "https://" + $url + ":11005/api/v1/"
$url1 = $base + "token"

$creds = @{
 "grant_type" = "password"
 "username" = $vbawsInfo.username
 "password" = $vbawsInfo.password
}

# Set Headers for Token URL 
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("x-api-version", "1.5-rev1")
$headers.Add("Content-Type", "application/x-www-form-urlencoded")
$headers.Add("Accept", "application/json")

# Setup the Rest API Bearer token
 $key = Invoke-RestMethod -Method 'Post' -Uri $url1 -Body $creds -Headers $headers
 $bear = "Bearer"
 $key1 = $key[0].access_token
 $auth = $bear + " " + $key1

 # Set Header with Bearer token
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("x-api-version", "1.5-rev1")
$headers.Add("Content-Type", "application/x-www-form-urlencoded")
$headers.Add("Accept", "application/json")
$headers.Add("Authorization",$auth)


Write-Host "Connect to VB-AWS Rest API"

$url = "https://vbaws.aws.vcspcorp.net:11005/api/v1/token"


write-host "Connect to VBAWS Rest API"

$urlVM = "https://vbaws.aws.vcspcorp.net:11005/api/v1/virtualMachines?SearchPattern=lab-webwp-01"
$virtSystems = Invoke-RestMethod -Method 'Get' -Uri $urlVM -Headers $headers2
$vmId = $virtSystems.results.Id

write-host " Select VM ID: " $vmId 

$urlRP = "https://vbaws.aws.vcspcorp.net:11005/api/v1/virtualMachines/restorePoints?VirtualMachineId=$vmId&Sort=pointInTimeDesc"
$restorePoints = Invoke-RestMethod -Method 'Get' -Uri $urlRP -Headers $headers2
$snapshots = $restorePoints.results | Where-Object {$_.jobType -eq "Replica"}
$rpId = $snapshots[0].id

write-host "Select Restore Point: " $rpId

$restoreBody = @'
{
    "reason": "Test powershell",
    "IAMRoleId": "bf2d042c-c352-41c2-a609-7341be37c2a2",
    "startInstance": true,
    "restorePrivateIp": false,
    "assignPublicIp": true,
    "toAlternative": {
      "name": "lab-webwp-01dr",
      "regionId": "5c156587-3110-4cb6-8958-8f6ccbd02bc4",
      "vmType": "t2.micro",
      "subnetId": "subnet-076fcab73fed5dfd9",
      "networkSecurityGroupId": "sg-084555b8a245e79cd",
      "preserveEncryptionForVolumes": true
    }
}
'@

$Params = @{
	Method = "Post"
	Uri = "https://vbaws.aws.vcspcorp.net:11005/api/v1/virtualMachines/restorePoints/$rpId/restoreVm"
	Body = $restoreBody
    Headers = $headers2
}

write-host "Invoke Rest API"

$ec2Restore = Invoke-RestMethod @Params
