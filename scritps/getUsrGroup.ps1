param(
[string]$name,
[string]$server
) 

if($server -eq $NULL -or $name -eq $NULL -or $server -eq "" -or $name -eq ""){
    Write-Error 'Failed: Your server or name not specified, see below to see which was not specified' -ErrorId "SeverOrNameFault"
    Write-Error "Server:" $server
    Write-Error "Name:" $name

}
#Set Server
$Server = $env:computername 
$membership = Get-ADUser -Identity $name -Properties "MemberOf"
$membership.MemberOf | % {(Get-ADGroup $_).Name}