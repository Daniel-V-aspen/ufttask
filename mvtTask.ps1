$sARTUri = 'http://HQQAEBLADE710.qae.aspentech.com:3000'
#$sARTUri = 'http://hqqaeblade710:3000'
$sARTServerUri = $sARTUri
$DebugPreference = "Continue"
$DebugPreference = 'SilentlyContinue'
while ($true) {
    try {
        iex ((New-Object System.Net.WebClient).DownloadString("$sARTUri/api/ps/ARTLibrary.ps1"))
        iex ((New-Object System.Net.WebClient).DownloadString("$sARTUri/api/ps/CommonHeader.ps1"))
        iex ((New-Object System.Net.WebClient).DownloadString("$sARTUri/api/ps/Library.ps1"))
        break            
    }
    catch {
        
    }
}


$pathLogs = "C:\p4\MvtUftLogs.txt"
class Logs 
{
    [string]$logsPath = ""
    [ValidateSet("INFO", "DEBUG", "WARNING", "ERROR")] [string]$cli_level = "DEBUG"
    [ValidateSet("INFO", "DEBUG", "WARNING", "ERROR")] [string]$file_level = "DEBUG"
    [Boolean]$write = $false
    [boolean] hidden $_fileExists = $false
    [string] hidden $_lastPath = ""

    Logs() {
        return
    }

    Logs(
        [string]$logsPath,
        [string]$cli_level,
        [string]$file_level,
        [Boolean]$write
    ) {
        $this.logsPath = $logsPath
        $this.cli_level = $cli_level
        $this.file_level = $file_level
        $this.write = $write
    }

    #Public Methods

    [void] start()
    {
        if($this.write)
        {
            $this.createFile()
        }
        
    }

    [void] debug([string]$logString)
    {
        $this.printLog("DEBUG", $logString)
        $this.writeLog("DEBUG", $logString)
    }

    [void] info([string]$logString)
    {
        $this.printLog("INFO", $logString)
        $this.writeLog("INFO", $logString)
    }

    [void] warning([string]$logString)
    {
        $this.printLog("WARNING", $logString)
        $this.writeLog("WARNING", $logString)
    }

    [void] error([string]$logString)
    {
        $this.printLog("ERROR", $logString)
        $this.writeLog("ERROR", $logString)
    }

    #private Methods

    [void] hidden createFile() 
    {
        if (-not(Test-Path -Path $this.logsPath))
        {
            New-Item -Path $this.logsPath -ItemType File
        }
        $this._fileExists = $true
        $this._lastPath = $this.logsPath
    }

    [void] hidden printLog(
        [string]$level,
        [string]$logString
    )
    {
        if($this.number($level) -gt $this.number($this.cli_level))
        {
           return 
        }
        $stamp = (Get-Date).toString("yyyy/MM/dd HH:mm:ss")
        $LogMessage = "$stamp $level $logString"
        $color = $this.color($level)
        Write-Host $LogMessage -ForegroundColor $color
    }

    [void] hidden writeLog(
        [string]$level,
        [string]$logString
    )
    {
        if(-not $this.write)
        {
            return
        }
        if($this.number($level) -gt $this.number($this.file_level))
        {
           return 
        } 
        if((-not $this._fileExists) -or ($this.logsPath -ne $this._lastPath))
        {
            $this._fileExists = $false
            $this.printLog("ERROR", "Run start() method before write a log")
        }
        $stamp = (Get-Date).toString("yyyy/MM/dd HH:mm:ss")
        $LogMessage = "$stamp $level $logString"
        Add-content $this.logsPath -value $LogMessage
    }

    [string] hidden color(
        [string]$level
    )
    {
        $color = switch ($level){
            "DEBUG"     { "Magenta" }
            "INFO"      { "Green" }
            "WARNING"  { "Yellow" }
            "ERROR"     { "Red" }
        }
        return $color
    }

    [int] hidden number(
        [string]$level
    )
    {
        $num = switch ($level){
            "DEBUG"     { 4 }
            "INFO"      { 3 }
            "WARNING"  { 2 }
            "ERROR"     { 1 }
        }
        return $num
    }

}

$logger = [Logs]::new()
$logger.logsPath = $pathLogs
$logger.write = $true
$logger.cli_level = 'DEBUG'
$logger.start()

#Folders that need to be in the VM
$dirUft = ('C:\Program Files (x86)\Micro Focus\UFT Developer\SDK\DotNet',
    'C:\Program Files (x86)\Micro Focus\UFT Developer\bin\')

#UFT Service variables
$pathLeanft = 'C:\Program Files (x86)\Micro Focus\UFT Developer\bin\leanft.bat'
$pathLeanStart = '.\.uftServiceStart.txt'
$pathLeanStatus = '.\.uftServiceStatus.txt'

#Build Solution
$buildFile = '.\.buildInformation.txt'

#Information needed for the report
$reportTable = @()
function ReportObject($id, $description, $result)
{
    $obj = New-Object PSObject
    $obj|Add-Member -MemberType NoteProperty -Name "Id" -Value $id
    $obj|Add-Member -MemberType NoteProperty -Name "Description" -Value $description
    $obj|Add-Member -MemberType NoteProperty -Name "Result" -Value $result
    return $obj
}

#inputs MVT
$P4_Path = Load-Setting -sARTServerUri $sARTServerUri -vision $vision -project $blueprint -task $task1 -key P4_Path #The P4/GIT project you want to sync up to local VM. Example: ['https://aspentech-alm.visualstudio.com/AspenTech/_git/MES_MVT|branchName']
$projectName = Load-Setting -sARTServerUri $sARTServerUri -vision $vision -project $blueprint -task $task1 -key Project Name #Name of the project in Visual Studio
$testplanPath = Load-Setting -sARTServerUri $sARTServerUri -vision $vision -project $blueprint -task $task1 -key Test Plan path #Path to the testplan csv, the file must have the columns Id (Id in ADO), Description, Function Name (Name in project)
#Check Screen Resolution
$width = Load-Setting -sARTServerUri $sARTUri -vision $vision -project $blueprint -task $task1 -key "width" -LoadOnce #The width of the screen. If you don't want to set the resolution, leave it to be blank example: 1920
$height = Load-Setting -sARTServerUri $sARTUri -vision $vision -project $blueprint -task $task1 -key "height" -LoadOnce #The height of the screen. If you don't want to set the resolution, leave it to be blank: example: 1080
$domain = Load-Setting -sARTServerUri $sARTUri -vision $vision -project $blueprint -task $task1 -key "domain" -LoadOnce # The domain of the user account you use to login ex: machine name or corp. 
$userName = Load-Setting -sARTServerUri $sARTUri -vision $vision -project $blueprint -task $task1 -key "userName" -LoadOnce # the username of the current box. If you don't want to set the resolution, leave it to be blank: example: administrator
$password = Load-Setting -sARTServerUri $sARTUri -vision $vision -project $blueprint -task $task1 -key "password" -LoadOnce # the password of the current box. If you don't want to set the resolution, leave it to be blank: example: Aspen100
$ip = Get-IPAddressV2 -MachineName $env:COMPUTERNAME
#Email report
$Email_List = Load-Setting -sARTServerUri $sARTServerUri -vision $vision -project $blueprint -task $task1 -key Email_List -LoadOnce #The recepient of your MVT execution result in json format. Example: ["weiwei.wu@aspentech.com","albert.lee@aspentech.com"]
$Email_Subject = Load-Setting -sARTServerUri $sARTServerUri -vision $vision -project $blueprint -task $task1 -key Email_Subject -LoadOnce #The subject of your email. If you does not provide anything, the default value will be "Automated MVT Email Result

#inputs Debug ------------------------------------------------------------------------------------ Change this
#$projectPath = 'C:\Users\administrator\Desktop\Git\MtellCore-UFT'
#$projectName = 'Mtell Automation'
#$testplanPath = 'testplan.txt' #Id, Function name



#Clone Repo
#Moving into project path ------------------------------------------------------------------------------------ Change this


$logger.debug("Changing directory to path <$($projectPath)>")

#debug ------------------------------------------------------------------------------------ Change this
cd $projectPath

#Install prerequisites
$logger.info("Installing prerequisites")
$logger.debug("Choco")
try
{
    choco --version
}
catch
{
    $logger.info("Installing Chocolatey")
    Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
}
$logger.info("Installing Nuget")
choco install nuget.commandline -f -y

$logger.info('Installing Node')
&choco install nodejs --version=16.19.0 -f -y

$logger.debug("Installing Unit Test Package")
NuGet Install VS.QualityTools.UnitTestFramework
$pathLstUtest = Get-ChildItem -Path '.\' -Recurse -ErrorAction SilentlyContinue -Filter *QualityTools.UnitTestFramework.dll | Where-Object Mode -Match 'a' | Sort-Object -Property LastWriteTime -Descending
$pathUTest = $pathLstUtest[0].FullName

$logger.debug("dotnet")
try
{
    dotnet --version
}
catch
{
    $logger.info("Installing dotnet")
    choco install dotnet --pre 
}

#Validate Prerequisites
for($i=0; $i -lt $dirUft.Count; $i++)
{
    if(-not(Test-Path -Path $dirUft[$i]))
    {
        $des = "Dlls UFT pre requisites not found: <$($dirUft[$i])>"
        $logger.error($des)
        $id = "Rerequisite$($i)"
        $reportTable += @(ReportObject -id $id -description $des -result "Fail")
    }
}
if(-not(Test-Path -Path $pathUTest))
{
    $des = "Dlls Unit Test Framework pre requisites not found: <$($dirUft[$i])>"
    $logger.error($des)
    $id = "Rerequisite$($i)"
    $reportTable += @(ReportObject -id $id -description $des -result "Fail")
}

#Start Services
$logger.info("Start Leanft Services")
$leanRunning = $false
for($i = 0; $i -lt 4; $i++)
{
    & $pathLeanft start  > $pathLeanStart
    Start-Sleep -Seconds 2
    $startInfo = Get-Content $pathLeanStart
    if($startInfo -match 'already up')
    {
        $logger.info("Leanft Service is running")
        $leanRunning = $true
        break
    }
    Start-Sleep -Seconds 2
    & $pathLeanft info  > $pathLeanStatus
    $startInfo = Get-Content $pathLeanStart
    if($statusInfo -match 'currently running')
    {
        $logger.info("Leanft Service is running")
        $leanRunning = $true
        break
    }
    $logger.debug("Try to run Leanft Service: $($i+1)")
}

if(-not($leanRunning))
{
    $reportTable += @(ReportObject -id "Leanft Service" -description "Unable to run the service" -result "Fail")
}


#Variables Build Solution
$references = @{
    'Microsoft.VisualStudio.QualityTools.UnitTestFramework' = $pathUTest;
    'HP.LFT.SDK' = 'C:\Program Files (x86)\Micro Focus\UFT Developer\SDK\DotNet\HP.LFT.SDK.dll';
    'HP.LFT.UnitTesting' = 'C:\Program Files (x86)\Micro Focus\UFT Developer\SDK\DotNet\HP.LFT.UnitTesting.dll';
    'HP.LFT.Common' = 'C:\Program Files (x86)\Micro Focus\UFT Developer\SDK\DotNet\HP.LFT.Common.dll';
    'HP.LFT.Communication.SocketClient' = 'C:\Program Files (x86)\Micro Focus\UFT Developer\bin\HP.LFT.Communication.SocketClient.dll';
    'HP.LFT.Report' = 'C:\Program Files (x86)\Micro Focus\UFT Developer\SDK\DotNet\HP.LFT.Report.dll';
    'HP.LFT.Verifications' = 'C:\Program Files (x86)\Micro Focus\UFT Developer\SDK\DotNet\HP.LFT.Verifications.dll'
    'WebSocket4Net' = 'C:\Program Files (x86)\Micro Focus\UFT Developer\bin\WebSocket4Net.dll'
    }

$logger.info("Looking for the .csproj file")
$pathLstCsproj = Get-ChildItem -Path .\ -Recurse -Filter *.csproj
$pathCsproj = $pathLstCsproj[0].FullName
$logger.debug("CSPROJ found, path: <$($pathCsproj)>")

[xml]$csprojInfo = Get-Content $pathCsproj

$logger.info("Starting process to replace the references")
$findRequirements = $false
$refFound = 0
$childHint = $csprojInfo.CreateElement('HintPath')
for($i = 0; $i -lt $csprojInfo.Project.ItemGroup.Count; $i++)
{
    if($csprojInfo.Project.ItemGroup[$i].Reference.Count -gt 0)
    {
        $findRequirements = $true
        for($ref = 0; $ref -lt $csprojInfo.Project.ItemGroup[$i].Reference.Count; $ref++)
        {
            if($references[$csprojInfo.Project.ItemGroup[$i].Reference[$ref].Include.split(',')[0]] -ne $null)
            {
                $refKey = $csprojInfo.Project.ItemGroup[$i].Reference[$ref].Include.split(',')[0]
                $logger.debug("Reference: $($refKey) found")
                $refFound++
                $logger.debug("Adding HintPath: $($references[$refKey])")
                $childHint = $csprojInfo.CreateElement('HintPath') 
                if(-not($csprojInfo.Project.ItemGroup[$i].Reference[$ref].HintPath))
                {
                    [void]$csprojInfo.Project.ItemGroup[$i].Reference[$ref].AppendChild($childHint)
                }
                $csprojInfo.Project.ItemGroup[$i].Reference[$ref].HintPath = $references[$refKey].ToString()
            }
        }
    }
}
$logger.info("Saving changes in the .csparoj <$($pathCsproj)>")
$csprojInfo.Save($pathCsproj)

#Delete xmlns = '' in the csproj
$logger.info('Delete xmlns="" from the csproj created by ps')
$csprojInfoTxt = Get-Content $pathCsproj
$csprojInfoTxt = $csprojInfoTxt.replace(' xmlns=""','')
Set-Content -Path $pathCsproj -Value $csprojInfoTxt

if(-not($findRequirements))
{
    $logger.error("References not found")
    $reportTable += @(ReportObject -id "References" -description "Unable to find the references" -result "Fail")
}

if($refFound -ne $references.Count)
{
    $logger.error("Number of references doesn't match with the number of references expected")
    $reportTable += @(ReportObject -id "Number of references found" -description "Unable to find all the references, References found: <$($refFound), expected references $($references.Count)>" -result "Fail")
}

#Get list of TCS to run
$tc2Run = ''
if($reportTable.Length -eq 0)
{
    if($testplanPath -eq "" -or $testplanPath -eq $null)
    {
        $logger.error("Test plan file not found")
    } else {
        $testplanFullPath = Join-Path -Path $projectPath -ChildPath $testplanPath
        if(-not(Test-Path -Path $testplanFullPath))
        {
            $logger.error("Test plan file not found")
        
        } else {
            $tpInfo = @{}
            foreach($testcase in $testPlanInfo)
            {
                $tpInfo[$testcase.name] = $testcase.id
                $tc2Run += $testcase.name + ','
            }
            $logger.debug("List of test cases in the test plan <$($tc2Run)>")
        }
    }
}

#set screen resolution if all variables are not empty
$logger.info("Changing Screen resolution")
if($width -ne $null -and $height -ne $null -and $domain -ne $null -and $userName -ne $null -and $password -ne $null -and $width -ne '' -and $height -ne '' -and $domain -ne '' -and $userName -ne '' -and $password -ne ''){
    $iRetry=0
    while($true)
    {
        $iRetry=$iRetry+1
        if($iRetry -eq 10){
            Read-Host -Prompt "Unable to adjust screen resolution "
            $iRetry=0
        }
        Write-Progress -Activity "Set Screen Resolution to $width x $height" -Completed
        $resolution = Get-ScreenResolution
        if([int]($width) -ne $resolution.width -or [int]($height) -ne $resolution.height)
        {
            Set-ScreenResolutionViaRdp -sARTUri $sARTUri -machine $ip -domain $domain -userName $userName -password $password -width ([int]($width)) -height ([int]($height))
            $value = 10 * $iRetry
            Start-Sleep -Seconds $value
            #Start-Sleep -Seconds 10*$iRetry
        }
        else
        {
            Write-Progress -Activity "Set Screen Resolution to $width x $height" -Completed
            break
        }
    }
}

#Build Solution
if($reportTable.Length -eq 0)
{
    $logger.info("Build information in: <$($projectPath) + $buildFile>")
    dotnet build > $buildFile 

    #Looking for the dll
    $logger.info("Looking for the dll")
    Start-Sleep -Seconds 5
    $buildInfo = Get-Content $buildFile
    $dllPath = $false
    for($i = 0; $i -lt $buildInfo.Count; $i++)
    {
        if($buildInfo[$i] -match $projectName)
        {
            $logger.info("Dll found")
            Write-Host $buildInfo[$i]
            $elements = $buildInfo[3].Split('>')
            $dllPath = $elements[$elements.Count - 1].Substring(1)
            break
        }
    }
    if (-not($dllPath))
    { 
        $logger.error("Dll not found")
    } else {
        $logger.info("dll in path <$($dllPath)>")
        if (-not(Test-Path -Path $dllPath))
        {
            $logger.error("Dll path not found, path: <$($dllPath)>")
            $reportTable += @(ReportObject -id "Dll not found" -description "Unable to find dll path, build information in <$($projectPath)\$buildFile>" -result "Fail")
        }
    }
}

if($reportTable.Length -eq 0)
{
    # Execute the automation
    $logger.info('Excecuting UFT')
    if($tc2Run -eq '' -or $tc2Run -eq $null)
    {
        vstest.console.exe $dllPath /Logger:trx
    }
    else
    {
        vstest.console.exe $dllPath /Tests:$tc2Run /Logger:trx
    }
}

if($reportTable.Length -eq 0)
{
    #Get results
    $logger.info("Looking for the results file")
    $reportFilePath = Get-ChildItem -Path '.\' -Recurse -ErrorAction SilentlyContinue -Filter *.trx | Sort-Object -Property LastWriteTime -Descending
    $logger.info("Report file found in the path: <$($reportFilePath[0].FullName)>")


    #Extracting the content from the last File storaged inside a variable named $text
    $logger.info("Creating MVT report")
    [xml]$xmlReport = Get-Content -Path $reportFilePath[0].FullName
    $xmlData = $xmlReport.TestRun.Results

    #Creating MVT Report
    $reportTable = @()        
    foreach($result in $xmlData){
        if($tpInfo -eq $null -or $tpInfo[$result.UnitTestResult.testName] -eq '' -or $tpInfo[$result.UnitTestResult.testName] -eq $null)
        {
            $id = $result.UnitTestResult.testName
        }
        else
        {
            $id = $tpInfo[$result.UnitTestResult.testName]
        }
        $description = 'Test Name: <' + $result.UnitTestResult.testName + '> Duration ' + [string]$result.UnitTestResult.duration
        if ($result.UnitTestResult.outcome.Contains("Passed")) {
            $result = "Pass"
        }
        else {
            $result = "Fail"
        }
        $logger.debug("TC: <$($result.UnitTestResult.testName)> Result: <$($result.UnitTestResult.outcome)>")
        $reportTable += @(ReportObject -id $id -description $description -result $result)
    }
    
}
$mvtReport = Join-Path -Path $projectPath -ChildPath 'mvtReport.csv'
$logger.info("Mvt Report in path: <$($mvtReport)>")
$reportTable | Export-Csv -Path $mvtReport -NoTypeInformation -Encoding UTF8 -Force

