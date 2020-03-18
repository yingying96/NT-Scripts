$SwiftUser=Get-ADGroupMember "pisolatedswift" | Select sAMAccountName
 
foreach ($row in $SwiftUser)
{
    $NTID = $row.sAMAccountName
    $NewPath = Join-Path C:\Users\yaoying3\Desktop\Swift $NTID
    New-Item -Path $NewPath -ItemType Directory 
 
    $acl = Get-Acl $NewPath
    $AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($NTID,"Modify",'ContainerInherit, ObjectInherit',"None","Allow") 
    $acl.AddAccessRule($AccessRule)
    $acl | Set-Acl $NewPath
 
}
