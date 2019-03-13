Import-Module activedirectory
$names = "ex-list.txt"
$group = "G-GLOBAL-M3CloudUsers"
$members =  Get-ADGroupMember -Identity $group -Recursive | Select -ExpandProperty SamAccountName
$summary = "ex-summary.txt"
if (Test-Path $summary){
    Remove-Item $summary
}

foreach($line in Get-Content $names) {
        write-host `n
        write-host "[+] Checking user $line in file $names" -ForegroundColor Green
        try {
            $eaName = $null;
            $eaName = Get-ADUser -Identity $line -Properties extensionAttribute1 
            if (($eaName).extensionAttribute1 -ne $null) {
                $eaText = ($eaName).extensionAttribute1
                Write-Host "[!] ExtensionAttribute1 $eaText taken by user $line"
            } else {
            $firstname = Get-ADUser $line |% {$_.givenname}
            $lastname = Get-ADUser $line |% {$_.surname}
            $firstname = $firstname.Substring(0,3)
            $lastname = $lastname.Substring(0,3)
            $eA1 = $lastname + $firstname
            $eA1 = $eA1.ToUpper()
            try {
                $eaInfo = $null;
                $eaInfo = Get-ADUser -LDAPFilter "(extensionAttribute1=$eA1)"
                write-host "[?] Checking if extensionattribute1 $eA1 is taken.."
                if ($eaInfo -ne $null) {
                    Write-Host "[!] ExtensionAttribute $eA1 already taken." -ForegroundColor yellow
                    ($line).SamAccountName
                } else {
                    write-host "[+] $eA1 is available" -ForegroundColor Green
                    Write-Host "[!] No extensionAttribute present on user $line"
                    Write-Host "[+] Setting extensionAttribute1 $eA1 which is available" -ForegroundColor yellow
                    try {
                        $SetEaInfo = Set-ADUser $line –replace @{extensionAttribute1=”$eA1”}
                        Write-host "[+] Success. extensionAttribute1 $eA1 set for user $line" -ForegroundColor Green
                        add-content ex-summary.txt "User: $line`n"
                        add-content ex-summary.txt "eA1: $eA1`n"
                    }
                    catch {
                        write-host "[!] Error setting eA1 value, please try again or proceed manually."
                    }
                }
            }
            catch {
                write-host "[!] Error! Are you sure the name is correct? You typed $eaName." -ForegroundColor Red
            }
          }
        }
        catch {
            write-host "[!] Error! Are you sure the name is correct? You typed $line." -ForegroundColor Red
        }
        write-host "[?] Checking if user $line is member of G-GLOBAL-M3CloudUsers..."
        if($members -contains $line) {
            write-host "[-] User $line already exists in M3 group" -ForegroundColor Red
        } else {
            Add-ADGroupMember -Identity $group -Members $line

            write-host "[+] User $line added to G-GLOBAL-M3CloudUsers"
            add-content ex-summary.txt "Group: G-GLOBAL-M3CloudUsers`n"
    }
    add-content ex-summary.txt "-----------------------------"
}
