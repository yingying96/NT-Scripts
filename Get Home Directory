$Data = Import-Csv -Path "H:\Wave0.csv"
ForEach ($Line in $Data) {
    $NTName = $Line.sAMAccountName
    $User = Get-ADUser -Identity $NTName
   Get-ADUser -Identity $User -Properties sAMAccountName,HomeDirectory |`
   Select sAMAccountName,HomeDirectory | Export-CSV -Append "H:\Asia_HDrive.csv"

}
