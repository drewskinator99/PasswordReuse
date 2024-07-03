 # Class to store user and ntlm hash data
 class user {
    [string] $ntlmh
    [string]$user    
    user(
        [string] $ntlmh,
    [string]$user
    ){
        $this.ntlmh = $ntlmh
        $this.user = $user
    }
}
# Define the output file paths
$basepath = "C:\BasePathHere"
$logFile = "LogFilePathHere.log"
$Domain1UsersFile = Join-Path -path $basepath  -ChildPath "Domain1users.txt"
$Domain1NTDSFile = Join-Path -path $basepath  -ChildPath "DomainController.txt"
$Domain2Userfile = Join-path -Path $basepath -ChildPath "Domain2Users.txt"
$Domain2NtdsFile = Join-path -Path $basepath -ChildPath "Domain2.txt"
$Domain3UserFile = Join-path -Path $basepath -ChildPath "Domain3Users.txt"
$Domain3NtdsFile = Join-path -Path $basepath -ChildPath "Domain3.txt"

# Define the domains and output file paths
$domains = @("domain1.com", "domain2.com", "domain3.com")
$Userfilepaths = @($Domain1UsersFile, $Domain2Userfile, $Domain3UserFile)

# Ensure the output folder exists
if (-not (Test-Path -Path $basepath)) {
    New-Item -Path $basepath -ItemType Directory
}
# initialize counter
$index = 0
foreach ($domain in $domains) {
    # Set the output file path for the current domain
    $outputFilePath = $Userfilepaths[$index]
    # Get all users in the current domain
    $users = Get-ADUser -Server $domain -Filter * -Property SamAccountName
    # Create or overwrite the output file
    New-Item -Path $outputFilePath -ItemType File -Force
    # Loop through each user and write the SamAccountName to the output file
    foreach ($user in $users) {
        $user.SamAccountName | Out-File -FilePath $outputFilePath -Append
    }   
    Write-Host "Usernames for $domain have been written to $outputFilePath"
    $index++
}

# Domain 1 - Create Instance of User Class to perform tests against
$users = Get-Content $Domain1UsersFile
$ntds = Get-Content $Domain1NTDSFile
$userarr = @()
$arr = @{}
$duparr = @{}
foreach($n in $ntds){
    $ntlm = $n.split(":")[3]
    $user = $n.split(":")[0]
    if($user.Contains('\')){
      $user = $user.split('\')[1]
    }
    else{
      Write-Output "Error processing user credentials for user: $user" >> $LogFilePathHere
      continue
    }   
    $userobj = [user]::new($ntlm,$user) 
    $userarr += $userobj    
}

# Domain 1 - Check for self password re-use
$sorted = $userarr | sort -Property ntlmh
$Domain2roups = $sorted | Group-Object -Property ntlmh
$duplicatesFile = Join-Path -Path $basepath -ChildPath "Domain1SelfDuplicates.txt"
foreach($Domain2roup in $Domain2roups){
    if($Domain2roup.Count -ne 1){
        foreach($Domain2 in $Domain2roup.Group){
            $found = Get-ADuser $Domain2.user  -Properties Enabled, Name, samaccountname
             $name = $found.name
   
            $enabled = $found.Enabled
            if($enabled){
                $name >> $duplicatesFile  
            }
         }
    }
}
# Use the above as the standard for finding duplicates among the same domain. 

# Domain 2 - Create Instance of User Class to perform tests against
$Domain2users = Get-Content $Domain2Userfile
$Domain2ntds = Get-Content $Domain2NtdsFile
$Domain2userarr = @()
foreach($n in $Domain2ntds){
    $ntlm = $n.split(":")[3]
    $user = $n.split(":")[0]
    if($user.Contains('\')){
      $user = $user.split('\')[1]
      $user
    }
    else{
      Write-Output "Error processing user credentials for user: $user" >> $LogFilePathHere
      continue
    }
    $Domain2userobj = [user]::new($ntlm,$user) 
    $Domain2userarr += $Domain2userobj
}

# Domain 2 - Check for password re-use against Domain 2
$sorted = $Domain2userarr | sort -Property ntlmh
$Domain2roups = $sorted | Group-Object -Property ntlmh
$duplicatesFile = Join-Path -Path $basepath -ChildPath "Domain2SelfDuplicates.txt"
foreach($Domain2roup in $Domain2roups){
    if($Domain2roup.Count -ne 1){
        foreach($Domain2 in $Domain2roup.Group){
            $found = Get-ADuser $Domain2.user  -Properties Enabled, Name, samaccountname
            $name = $found.name
            $enabled = $found.Enabled
            if($enabled){
                $name >> $duplicatesFile  
            }
         }
    }
}

# Domain 3 - Create Instance of User Class to perform tests against
$Domain3users = Get-Content $Domain3UserFile
$Domain3ntds = Get-Content $Domain3NtdsFile
$Domain3userarr = @()
foreach($n in $Domain3ntds){
    $ntlm = $n.split(":")[3]
    $user = $n.split(":")[0]
    if($user.Contains('\')){
      $user = $user.split('\')[1]
      $user
    }
    else{
      Write-Output "Error processing user credentials for user: $user" >> $LogFilePathHere
      continue
    }
    $Domain3userobj = [user]::new($ntlm,$user) 
    $Domain3userarr += $Domain3userobj
}
$Domain2VSDomain1File = Join-path -Path $basepath -ChildPath "CrossDomainReuse-Domain2.txt"

# Domain 2 - Check for Password Re-use against Domain 1
Foreach($Domain1user in $userarr){

    foreach($Domain2user in $Domain2userarr){
        if($Domain2user.ntlmh -eq $Domain1user.ntlmh){
            $Domain2 = $Domain2user.user
            $Domain1 = $Domain1user.user
            $found = Get-ADuser $Domain1  -Properties Enabled, Name, samaccountname
            $name = $found.name
   
            $enabled = $found.Enabled
            if($enabled){
                Write-Output "$Domain2 from Domain2 and $Domain1  from Domain1 have the same pwd"  >> $Domain2VSDomain1File
            }
        }       
    }
}
$Domain3VSDomain1File = Join-path -Path $basepath -ChildPath "CrossDomainReuse-Domain3.txt"

# Domain 3 - Check for Password Re-use against Domain 1
Foreach($Domain1user in $userarr){
    foreach($Domain3user in $Domain3userarr){
        if($Domain3user.ntlmh -eq $Domain1user.ntlmh){
            $Domain3 = $Domain3user.user
            $Domain1 = $Domain1user.user
            $found = Get-ADuser $Domain1  -Properties Enabled, Name, samaccountname
            $name = $found.name   
            $enabled = $found.Enabled
            if($enabled){
                Write-Output "$Domain3 from Domain3 and $Domain1  from Domain1 have the same pwd" >> $Domain3VSDomain1File
            }        
        }        
    }
}
