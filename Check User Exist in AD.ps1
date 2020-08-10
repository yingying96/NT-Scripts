$Data = Import-Csv -Path "H:\Users.csv" 
ForEach ($Line in $Data) { 

    Try{ 
        $NTName = $Line.NTID 
        $User = Get-ADUser -Identity $NTName 

        Write-Host "User $NTName exists in AD." 
        Out-file H:\exists.csv -append -inputobject "Exists in AD." 

    } 


    Catch{ 

        Write-Host "CATCG User $NTName DOES NOT exist in AD." 
        Out-file H:\exists.csv -append -inputobject "User $NTName does not exists in AD." 

    } 
} 
