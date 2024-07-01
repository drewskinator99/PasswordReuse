# PasswordReuse
Powershell script to analylze cross-domain password reuse with NTLM hashes

This powershell script can be used to analzye the NTLM hashes of different domains and determine whether or not the password has been used in the same domain, or in the other domains being analyzed.

This script assumes you have already obtained a dump of the .ntds files of each respective domain using a tool crackmapexec. It also assumes you have safely extracted the .ntds files from the machine used to compromise each respective domain and moved it onto a Windows host. 

# Crackmapexec command:

crackmapexec smb DC_IP_Address -u user -p 'pass' --ntds

# Steps used to clear traces on Kali 

Rem -r ~/.cme

cat /dev/null > ~/.zsh_history


