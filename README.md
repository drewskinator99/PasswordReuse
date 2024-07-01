# PasswordReuse
Powershell scripts to analylze cross-domain password reuse with NTLM hashes

These powershell script can be used to analzye the NTLM hashes of different domains and determine whether or not the password has been used in the same domain, or in the other domains being analyzed.

These scripts assume you have already obtained a dump of the .ntds files of each respective domain using a tool crackmapexec. It also assumes you have safely extracted the .ntds files from the machine used to compromise each respective domain and moved it onto a Windows host. 

# Crackmapexec command:

crackmapexec smb DC_IP_Address -u user -p 'pass' --ntds

# Steps used to clear traces on Kali 

Rem -r ~/.cme

cat /dev/null > ~/.zsh_history

# PasswordReuseCheck.ps1

This is a file that contains the first attempt to cross-analyze hashes and the usernames associated with them.

# PasswordHashes.ps1

This is a file that contains a re-formulated version of the script. 

## Output example:

### domain.txt:

Users with the same password:
  
  domain1\user1 domain1\user2

Hash: fef3894a0a732255041a32c833fbd12c

### userlist.txt:

domain1\user1
domain2\user3
domain1\user2

domain2\user6
domain3\user4

...where users are grouped based on matching hashes

### enabledusers_date_.csv

Columns:
  Name
  Enabled
  LastLogon
  PasswordLastSet



