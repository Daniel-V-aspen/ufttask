#folders
$dir2Test = ('C:\Program Files (x86)\Microsoft Visual Studio\2019\Enterprise\Common7\IDE\PublicAssemblies',
    'C:\Program Files (x86)\Microsoft Visual Studio\2019\Enterprise\Common7\IDE\PublicAssemblies',
    'C:\Program Files (x86)\Micro Focus\UFT Developer\bin\')

#Define a function to create the Result Object as a Matrix
$reportTable = @()
function ReportObject($id, $description, $result)
{
    $obj = New-Object PSObject
    $obj|Add-Member -MemberType NoteProperty -Name "Id" -Value $id
    $obj|Add-Member -MemberType NoteProperty -Name "Description" -Value $description
    $obj|Add-Member -MemberType NoteProperty -Name "Result" -Value $result
    return $obj
}

for($i=0; $i -lt $dir2Test.Count; $i++)
{
    if(-not(Test-Path -Path $dir2Test[$i]))
    {
        $des = "Dlls pre requisites not found: <$($dir2Test[$i])>"
        $logger.error($des)
        $id = "Rerequisite$($i)"
        $reportTable += @(ReportObject -id $id -description $des -result "Fail")
    }
}

  