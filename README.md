# bash-nmap-scans
The two nmap scans you run all the time... just create an alias for this script and no longer worry about those repetitive same nmap scan commands.

# What does this simple script do?

The first scan just does a regular "sudo nmap -p- -Pn <target> -oG <file>".

The second scan takes all those open ports from the first scan and runs > "sudo nmap -p<ports> -Pn -sC -sV <target> -oN <file>".

## Bonus Scan for UDP:

"sudo nmap -sU --open --top-ports 100"
