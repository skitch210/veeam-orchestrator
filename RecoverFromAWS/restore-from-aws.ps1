$backup = Get-VBREC2Backup -Name "aws backup"
$restorepoint = Get-VBRPublicCloudRestorePoint -Backup $backup
$server = Get-VBRServer -Type ESXi -Name esx02.support.local
Start-VBRInstantRecovery -RestorePoint $restorepoint -Server $server