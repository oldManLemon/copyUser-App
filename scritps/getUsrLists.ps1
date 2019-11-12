param(
[string]$Server
) 

if (!$Server)
{
    $Server = $env:computername 
}
#Store Data in AppData for access later
$appDataLocation = $env:LOCALAPPDATA+'\aviovaManagementApp\'
$testPath = Test-Path $appDataLocation
if(!$testPath){
    New-Item -Path $env:LOCALAPPDATA -Name "aviovaManagementApp" -ItemType "directory"

}
$userDataLocation = $appDataLocation+"usrData\"
$testPath = Test-Path $userDataLocation

if(!$testPath){
    New-Item -Path $appDataLocation -Name "usrData" -ItemType "directory"
}
#Get CSV with Full Display Names and account names
Get-ADUser -Server $server -Filter '*' -Properties DisplayName, Samaccountname | select DisplayName, Samaccountname | Export-Csv $userDataLocation$server".csv"