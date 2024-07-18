# Created by: drewskinator99
$pattern = '^(.*?):\d{1,5}:[a-fA-F0-9]{32}:(.*?):'

# TESTING
#$inputFile = "C:\Path\FullResults.txt"
#$fpath = "C:\Path\"

# Variables
$fpath = Read-Host "Enter the Folder the ntds files live in: " 
$inputFile = Read-Host "Enter the full filepath of the filename to save the full ntds file in: "
# Get content from ntds files
$files =  Get-item ($fpath + "\*" )| Where-Object {$_.Name -match ".*.ntds"}
$filestoDelete = $files
# Generate content for file
foreach($file in $files){
    Get-Content $file >> $inputFile
}
Write-Output "Creating Hash Tables and Compiling data in $inputFile"
# Create a hashtable to store usernames and corresponding hashes
$hashTable = @{} 
# Read each line from the input file and populate the hashtable
foreach ($line in Get-Content $inputFile) {
    if ($line -match $pattern) {
        $username = $matches[1]
        $hashData = $matches[2]
        # Add or update the hashtable with username and hash
        $hashTable[$hashData] = $hashTable[$hashData] + @($username)
    } 
    else { Write-Host "Line does not match the expected format: $line" }
}
# Compare the hashes and display groups of usernames with the same hash
$groups = $hashTable.GetEnumerator() | Group-Object Value
$outputfile = Read-Host "Enter the full filepath of the results output: "
$userfile = Read-Host "Enter the full filepath of the users only output: "

# TESTING
#$outputfile =  "C:\Path\details.txt"
#$userfile = "C:\Path\userlist.txt"

# Find users with the same password
foreach ($group in $groups) {
    if ($group.Count -gt 1) {
        Write-Host "Users with the same hash:"
        foreach ($username in $group.Group) {
            $u = $username.Key
            $h = $username.Value
            if($h.Count -gt 1){
                write-output "Users with the same password:`n`t`t$h`nHash:  $u`n`n" >> $outputFile            
                $arr = $h | Out-String
                $arr >> $userfile
            }
        }
    }
}
Write-Output "Creating Spreadsheet of users and their last logon"

# Create an array of objects representing the data
$data = @(
    [PSCustomObject]@{ Name = ""; Enabled = ""; LastLogon=""; PasswordLastSet = ""}
   
)
# Setup place to save files
$date = Get-date -format "MM_dd_yy"
$dir = Read-Host "Enter the directory to save the user spreadsheet in: " 
$outputFilePath = $dir + "\enabledusers_$date.csv"

# TESTING
# $outputFilePath = "C:\Path\enabledusers_$date.csv"

# Create the CSV file with the specified header and data
$data | Export-Csv -Path $outputFilePath -NoTypeInformation
$data = @()
foreach($line in Get-content $userfile){
    if($line -like "domain.local*" -or $line -like "domain.com*"){
       $u = $line.split('\')[1]
       $object = Get-Aduser $u  | select Name, Enabled      
       foreach($user in $object){
            $username = $user.name
            $enabled = $user.enabled
            # Create an array of objects representing the data
            $user2 = Get-aduser $u -Properties LastLogon, PwdLastSet | select LastLogon, PwdLastSet
            $lastlogon = [DateTime]::fromFiletime($user2.LastLogon)
            $pwdlastset = [DateTime]::fromFiletime($user2.PwdLastSet)           
            $data += @(
                [PSCustomObject]@{ Name = $username; Enabled =$enabled; LastLogon = $lastlogon; PasswordLastSet = $pwdlastset}  
            )
       }
    }
} 
# output to screen
Write-Host $data -ForegroundColor Cyan
# Create the CSV file with the specified header and data
$data | Export-Csv -Path $outputFilePath -NoTypeInformation

# Delete ntds files
Write-Output "Deleting ntds files..."
foreach($f in $filestodelete){
    try{
        if(Test-Path $f.FullName){Remove-Item -Path $f.FullName -ErrorAction Stop}
        Write-Output "`tDone. deleting $($f.FullName)"
    }
    catch{
        Write-Host "Issue deleting ntds file $($f.FullName)!" -ForegroundColor Red
    }
}
# delete the input file
try{
    if(Test-Path $inputFile){Remove-Item -Path $inputFile -ErrorAction Stop}
    Write-Output "Removed $inputFile"
}
catch{
    Write-Host "Issue deleting input files!" -ForegroundColor Red
}