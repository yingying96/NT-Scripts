#Get list of folders
$Folders = Get-ChildItem -Path C:\Users\yaoying3\Desktop\Swift -Directory -Force -ErrorAction SilentlyContinue | Select-Object Name


$SwiftUser=Get-ADGroupMember "pisolatedswift" | Select sAMAccountName
    
#Check if there are any new users
foreach ($row in $SwiftUser) {

    $Path = Join-Path C:\Users\yaoying3\Desktop\Swift $row.sAMAccountName
    $ExistingUsers = Test-Path $Path -PathType Any

    #There are new swift users
    If ($ExistingUsers -eq $false) {

        #Create folders for new swift users
        $NTID = $row.sAMAccountName
        New-Item -Path $Path -ItemType Directory 

        $acl = Get-Acl $Path
        $AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($NTID,"Modify",'ContainerInherit, ObjectInherit',"None","Allow") 
        $acl.AddAccessRule($AccessRule)
        $acl | Set-Acl $Path

        Write-Host $NTID is a new swift user and folder is successfully created

        
    }
}


#Delete folders for leavers
foreach ($row in $Folders) {

    If ($SwiftUser.sAMAccountName -contains $row.Name) {
        Write-Host "$row.Name is a member of pisolatedswift group"
    }

    Else {
        Write-Host "$row is not a member of pisolatedswift group, folder will be removed"
        $ExistingFolder = Join-Path C:\Users\yaoying3\Desktop\Swift $row.Name
        Remove-Item -Path $ExistingFolder -Recurse
    }

}

