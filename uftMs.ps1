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
        Write-Host "`nCould NOT import the ART Libraries"
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

$msPaths = @("C:\Program Files (x86)\Microsoft Visual Studio\2017\Enterprise\MSBuild\Current\Bin",
               "C:\Program Files (x86)\Microsoft Visual Studio\2019\Enterprise\MSBuild\Current\Bin",
               "C:\Program Files (x86)\Microsoft Visual Studio\2017\Professional\MSBuild\Current\Bin",
               "C:\Program Files (x86)\Microsoft Visual Studio\2019\Professional\MSBuild\Current\Bin")

#Folders that need to be in the VM
$dirUft = ('C:\Program Files (x86)\Micro Focus\UFT Developer\SDK\DotNet',
    'C:\Program Files (x86)\Micro Focus\UFT Developer\bin\')

#UFT Service variables
$pathLeanft = 'C:\Program Files (x86)\Micro Focus\UFT Developer\bin\leanft.bat'
$pathLeanStart = '.\.uftServiceStart.txt'
$pathLeanStatus = '.\.uftServiceStatus.txt'

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
$projectName = Load-Setting -sARTServerUri $sARTServerUri -vision $vision -project $blueprint -task $task1 -key "Project Name" #Name of the project in Visual Studio
$testplanPath = Load-Setting -sARTServerUri $sARTServerUri -vision $vision -project $blueprint -task $task1 -key "Test Plan path" #Path to the testplan csv, the file must have the columns Id (Id in ADO), Description, Function Name (Name in project)
#Check Screen Resolution
$width = Load-Setting -sARTServerUri $sARTUri -vision $vision -project $blueprint -task $task1 -key "width" -LoadOnce #The width of the screen. If you don't want to set the resolution, leave it to be blank example: 1920
$height = Load-Setting -sARTServerUri $sARTUri -vision $vision -project $blueprint -task $task1 -key "height" -LoadOnce #The height of the screen. If you don't want to set the resolution, leave it to be blank: example: 1080
$domain = Load-Setting -sARTServerUri $sARTUri -vision $vision -project $blueprint -task $task1 -key "domain" -LoadOnce # The domain of the user account you use to login ex: machine name or corp. 
$userName = Load-Setting -sARTServerUri $sARTUri -vision $vision -project $blueprint -task $task1 -key "userName" -LoadOnce # the username of the current box. If you don't want to set the resolution, leave it to be blank: example: administrator
$password = Load-Setting -sARTServerUri $sARTUri -vision $vision -project $blueprint -task $task1 -key "password" -LoadOnce # the password of the current box. If you don't want to set the resolution, leave it to be blank: example: Aspen100
$ip = Get-IPAddressV2 -MachineName $env:COMPUTERNAME
#Email report
$Email_List = Load-Setting -sARTServerUri $sARTServerUri -vision $vision -project $blueprint -task $task1 -key "Email_List" -LoadOnce #The recepient of your MVT execution result in json format. Example: ["weiwei.wu@aspentech.com","albert.lee@aspentech.com"]
$Email_Subject = Load-Setting -sARTServerUri $sARTServerUri -vision $vision -project $blueprint -task $task1 -key "Email_Subject" -LoadOnce #The subject of your email. If you does not provide anything, the default value will be "Automated MVT Email Result
$logger.debug($P4_Path)
$logger.debug($projectName)
$logger.debug($width)
$logger.debug($height)
$logger.debug($domain)
$logger.debug($userName)
$logger.debug($password)
$logger.debug($ip)
$logger.debug($Email_List)
$logger.debug($Email_Subject)

#inputs Debug ------------------------------------------------------------------------------------ Change this
#$projectPath = 'C:\Users\administrator\Desktop\Git\MtellCore-UFT'
#$projectName = 'Mtell Automation'
#$testplanPath = 'testplan.txt' #Id, Function name

$logger.info("Lokking for MSBuild")
$msExists = $false
foreach($path in $msPaths)
{
    if(Test-Path $path)
    {
        $logger.info("MSBuild path <$($path)>")
        $env:Path += ";" + $path   
        $msExists = $true     
    }
}
if(-not($msExists))
{
    $reportTable += @(ReportObject -id "MSBuild" -description "Unable to find MS BUILD" -result "Fail")
}

#Clone Repo
$logger.info('Clonning repo')
$cmd = { Sync-FromP4 -P4_User wuwei -P4_Server hqperforce2.corp.aspentech.com:1666 -P4_Location_List @($P4_Path) -P4_PASSWORD $secureString_wwwPass -P4_Work_Space_Folder c:\p4 -P4_Work_Space_Name ART -gitAccessToken $secureString_www_git -gitHubAccessToken $secureString_www_github_password }
Run-SecureCmd -sARTUri $sARTUri -cmd $cmd -arg @{P4_Path = $P4_Path; p4_ip = $p4_ip; P4_Work_Space_Folder = $P4_Work_Space_Folder }
if ($P4_Path.GetType().Name -eq "String") {
    #analytics directory
    $projectPath = Convert-P4LocationToWinLocation -P4Location $P4_Path -P4_Work_Space_Folder c:\p4
}

$logger.debug("Changing directory to path <$($projectPath)>")
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
    msbuild 

    #Looking for the dll
    $logger.info("Looking for the runner")
    Start-Sleep -Seconds 10
    $dllPath = $false
    $dllName = $projectName + ".dll"
    for($i = 0; $i -lt $buildInfo.Count; $i++)
    {
        
        $dllList = Get-ChildItem -Path '.\' -Recurse -ErrorAction SilentlyContinue -Filter $dllName
        $dllPath = $dllList[0].FullName
        
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


#Get results
$logger.info("Looking for the results file")
$reportFilePath = Get-ChildItem -Path '.\' -Recurse -ErrorAction SilentlyContinue -Filter *.trx | Sort-Object -Property LastWriteTime -Descending
$logger.info("Report file found in the path: <$($reportFilePath[0].FullName)>")

#Extracting the content from the last File storaged inside a variable named $text
$logger.info("Creating MVT report")
[xml]$xmlReport = Get-Content -Path $reportFilePath[0].FullName
$xmlData = $xmlReport.TestRun.Results.UnitTestResult

#Creating MVT Report
#$reportTable = @()        
foreach($result in $xmlData){
    if($tpInfo -eq $null -or $tpInfo[$result.testName] -eq '' -or $tpInfo[$result.testName] -eq $null)
    {
        $id = $result.testName
    }
    else
    {
        $id = $tpInfo[$result.testName]
    }
    $description = 'Test Name: <' + $result.testName + '> Duration ' + [string]$result.duration
    if ($result.outcome.Contains("Passed")) {
        $resultTC = "Pass"
    }
    else {
        $resultTC = "Fail"
    }
    $logger.debug("TC: <$($result.testName)> Result: <$($result.outcome)>")
    $reportTable += @(ReportObject -id $id -description $description -result $resultTC)
}

$mvtReport = Join-Path -Path $projectPath -ChildPath 'mvtReport.csv'
$logger.info("Mvt Report in path: <$($mvtReport)>")
$reportTable | Export-Csv -Path $mvtReport -NoTypeInformation -Encoding UTF8 -Force

#send email notification
if ($ExecutionResult -ne $null -and $ExecutionResult -ne "") {
    $ExecutionResultPath = Join-Path -Path $activeFolder -ChildPath $ExecutionResult
    if ($Email_Subject -eq $null -or $Email_Subject -eq "") {
        $Email_Subject = "Automated Execution Test Result for $vision"
    }   
    if (Test-Path -Path $ExecutionResultPath) {
        $html = [string](generateHTMLfromCSV -media ($sInstalled_Media) -startTime $startTime -endTime (Get-Date) -resultsFile ($ExecutionResult) -clientConfig $((Get-WmiObject -Class Win32_OperatingSystem).Name) -clientName ("$env:COMPUTERNAME"))
        try {
            Send-MailMessage -From "MVT@aspentech.com" -To $Email_List -Subject $Email_Subject -Body $html -SmtpServer smtp.aspentech.local -BodyAsHtml -ErrorAction Stop -Attachments @($ExecutionResultPath)
        }
        catch {
            Send-ErrorToMVTAdmin -vision $vision -blueprint $blueprint -task $task1 -log "Unable to send out email"
        }           
    }    
}

#project finish!
Set-NextProject -sARTServerUri $sARTUri -vision $vision -project $projectId 