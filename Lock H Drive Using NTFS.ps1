$Data = Import-Csv -Path "C:\Users\yaoying3\Desktop\Paths.csv" 
$Data.GetType().FullName

#Remember to use the powershell logging functionality for this.

foreach ($row in $Data)
{
    $NTID = $row.NTID
    $Path = $row.Path
    $acl = Get-Acl $Path
    Write-Host $acl
    $AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($NTID,"Write",'ContainerInherit, ObjectInherit',"None","Deny") 
    $acl.AddAccessRule($AccessRule)
    $acl | Set-Acl $Path

}
