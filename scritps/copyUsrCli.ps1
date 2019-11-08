#Turn into params
# $usrToCopy = Read-Host -Prompt 'Please enter the user you wish to copy here'
$usrToCopy = $args[0] #Probs should make this safer by being more verbose but for now testing
$firstName, $lastName = $usrToCopy.Split(' ')
$defaultPassword = ConvertTo-SecureString -String "Start#2019" -AsPlainText -Force
$filterForAdSearch = "givenName -like ""*$firstName*"" -and sn -like ""$lastName"""

$user = try {
    Get-ADUser -Filter $filterForAdSearch -Properties "UserPrincipalName", "MemberOf", "ProfilePath", "CN", "City", "c", "Country", "l", "mail", "mailNickname", "st", "State", "Department", "Description", "Title"
    Write-Host 'User' $usrToCopy 'will now be your template'
}
catch {
    Write-Host "Please check again, user is not found. 'n Is this user in Stuttgart?"
}
if ($user -is [array] ) {
    Write-Host 'There is has being an err, your selected user to copy has showed up more than once, it is an array not an obj. Breaking'
    break
}
$userInstance = Get-ADUser -Identity $user.SamAccountName

function checkUsrSam {
    Param ([string]$samName, [string]$fName, [string]$lName, [int]$run)
    
    
    $checkSam = try {
        Get-ADUser -Identity $samName
    }
    catch {
        write-host 'UserName Generated'
    }
       
    if ($checkSam) {
        #Should consider prompting here if you want to continue to run script

        $firstPart = $fName.Substring(0, $run)
        $samName = $firstPart + $lName
        $run = $run + 1
        checkUsrSam -samName $samName -fName $fname -lName $lName -run $run
    }
   
    else {
        return $samName
    }
}

IF ($user) {
    Write-Host 'User Found to be copied'
    # $newUsr = Read-Host -Prompt 'Enter name of new user'
    $newUsr = $args[1]
    $newFirstName, $newLastName = $newUsr.Split()

    #Flip the user names to match all other users
    $newUsr = $newLastName + ', ' + $newFirstName
  
    #Create user login
    $newSamAccountName = ($newFirstName[0] + $newLastName).ToLower()

    #Check to see if user login already exists and create a new version if exists
    #Example Tim Burton is tburton however if that exists it will create tiburton and timburton and so on and so fourth
    $newSamAccountName = checkUsrSam -samName $newSamAccountName -fName $newFirstName -lName $newLastName -run 1 #Set Run to one as <= is not simple in Powershell

    #keep $user Unmodded
    $stringMod = $user
    $frontGarbage, $endPrincipal = $stringMod.UserPrincipalName.Split('@')

    # Create a new principle name for login in modern Systems
    $newUsrPrincipalName = $newSamAccountName + '@' + $endPrincipal

    # Getting user into the correct OU by generating path
    $s = $stringMod.DistinguishedName
    $sectionOneGarbage, $sectionTwoGarbage, $sectionThree = $s.Split(',')
    $displayName = $newLastName + ', ' + $newFirstName
    $newPath
    $noComma = $sectionThree.Length
    $i = 1
    foreach ($section in $sectionThree) {
    
        $newPath += $section
        if ($i -lt $noComma) {
            $newPath += ','
        }
        $i++
    }
    #Create New User --This is really long and i want to multiline it or place it in a var but it hasn't gone well
    try{
        New-ADUser -Name $newUsr -SamAccountName $newSamAccountName -Instance $userInstance -DisplayName $displayName -GivenName $newFirstName -Surname $newLastName -AccountPassword $defaultPassword -Enabled $enabled -ChangePasswordAtLogon $true -UserPrincipalName $newUsrPrincipalName -Path $newPath
    }catch{
        Write-Host "Couldn't create user, most likely permission error"
        break
    }
    
        # New-ADUser -Name $newUsr -SamAccountName $newSamAccountName -Instance $userInstance -DisplayName $displayName -GivenName $newFirstName -Surname $newLastName -AccountPassword $defaultPassword -Enabled $enabled -ChangePasswordAtLogon $true -UserPrincipalName $newUsrPrincipalName -Path $newPath -Country $user.Country -Department $user.Department
   
    #--------Now we have the new user we need to move on to filling out some details and the groups--------#
    
    
    #Mirror all the groups the original account was a member of
    $user.Memberof | % { Add-ADGroupMember $_ $newSamAccountName }
    
    #Add some properties to the new user
    Set-ADuser -Identity $newSamAccountName -Description $user.Description -Department $user.Department -Country $user.Country -City $user.City -State $user.State -Title $user.Title

}
else {
    Write-Host 'Please check, user is not found is this user in Stuttgart?'
    Write-Host 'Bitte überprüfen, Benutuzer nicht gefundet, ist dieser Benutzer in Stuttgart?'
}

