$sARTUri = 'http://HQQAEBLADE710.qae.aspentech.com:3000'
#$sARTUri = 'http://hqqaeblade710:3000'
$sARTServerUri = $sARTUri
$DebugPreference = "Continue"
$DebugPreference = 'SilentlyContinue'
#while ($true) {
#    try {
#        iex ((New-Object System.Net.WebClient).DownloadString("$sARTUri/api/ps/ARTLibrary.ps1"))
#        iex ((New-Object System.Net.WebClient).DownloadString("$sARTUri/api/ps/CommonHeader.ps1"))
#        iex ((New-Object System.Net.WebClient).DownloadString("$sARTUri/api/ps/Library.ps1"))
#        break            
#    }
#    catch {
#        
#    }
#}


$pathLogs = "C:\Users\administrator\Desktop\DanielTest\MvtUftLogs.txt"
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

#MVTfolder 
$mvtPath = '.\.mvt\'

#UFT Service variables
$pathLeanft = 'C:\Program Files (x86)\Micro Focus\UFT Developer\bin\leanft.bat'
$pathLeanStart = Join-Path -Path $mvtPath -ChildPath '.\.uftServiceStart.txt'
$pathLeanStatus = Join-Path -Path $mvtPath -ChildPath '.\.uftServiceStatus.txt'

#Packages Information
$packagesPath = '.\packagesMvt'
$frames = @{
    "Microsoft.VisualStudio.TestPlatform.TestFramework" = 'MSTest.TestFramework';
    "Microsoft.VisualStudio.TestPlatform.TestFramework.Extensions" = 'MSTest.TestFramework';
    "Microsoft.VisualStudio.QualityTools.UnitTestFramework" = 'VS.QualityTools.UnitTestFramework';
}

#Build Solution
$buildFile = Join-Path -Path $mvtPath -ChildPath '.\.buildInformation.txt'

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
#$P4_Path = Load-Setting -sARTServerUri $sARTServerUri -vision $vision -project $blueprint -task $task1 -key P4_Path #The P4/GIT project you want to sync up to local VM. Example: ['https://aspentech-alm.visualstudio.com/AspenTech/_git/MES_MVT|branchName']
#$projectName = Load-Setting -sARTServerUri $sARTServerUri -vision $vision -project $blueprint -task $task1 -key Project Name #Name of the project in Visual Studio
#$testplanPath = Load-Setting -sARTServerUri $sARTServerUri -vision $vision -project $blueprint -task $task1 -key Test Plan path #Path to the testplan csv, the file must have the columns Id (Id in ADO), Description, Function Name (Name in project)
#Check Screen Resolution
#$width = Load-Setting -sARTServerUri $sARTUri -vision $vision -project $blueprint -task $task1 -key "width" -LoadOnce #The width of the screen. If you don't want to set the resolution, leave it to be blank example: 1920
#$height = Load-Setting -sARTServerUri $sARTUri -vision $vision -project $blueprint -task $task1 -key "height" -LoadOnce #The height of the screen. If you don't want to set the resolution, leave it to be blank: example: 1080
#$domain = Load-Setting -sARTServerUri $sARTUri -vision $vision -project $blueprint -task $task1 -key "domain" -LoadOnce # The domain of the user account you use to login ex: machine name or corp. 
#$userName = Load-Setting -sARTServerUri $sARTUri -vision $vision -project $blueprint -task $task1 -key "userName" -LoadOnce # the username of the current box. If you don't want to set the resolution, leave it to be blank: example: administrator
#$password = Load-Setting -sARTServerUri $sARTUri -vision $vision -project $blueprint -task $task1 -key "password" -LoadOnce # the password of the current box. If you don't want to set the resolution, leave it to be blank: example: Aspen100
#$ip = Get-IPAddressV2 -MachineName $env:COMPUTERNAME
#Email report
#$Email_List = Load-Setting -sARTServerUri $sARTServerUri -vision $vision -project $blueprint -task $task1 -key Email_List -LoadOnce #The recepient of your MVT execution result in json format. Example: ["weiwei.wu@aspentech.com","albert.lee@aspentech.com"]
#$Email_Subject = Load-Setting -sARTServerUri $sARTServerUri -vision $vision -project $blueprint -task $task1 -key Email_Subject -LoadOnce #The subject of your email. If you does not provide anything, the default value will be "Automated MVT Email Result

#inputs Debug ------------------------------------------------------------------------------------ Change this
$projectPath = 'C:\Users\administrator\Desktop\DanielTest\AspenHYSYS'
$projectName = 'AspenHYSYS'
$testplanPath = 'testplan.txt' #Id, Function name

#Clone Repo
#$cmd = { Sync-FromP4 -P4_User wuwei -P4_Server hqperforce2.corp.aspentech.com:1666 -P4_Location_List @($P4_Path) -P4_PASSWORD $secureString_wwwPass -P4_Work_Space_Folder c:\p4 -P4_Work_Space_Name ART -gitAccessToken $secureString_www_git -gitHubAccessToken $secureString_www_github_password }
#Run-SecureCmd -sARTUri $sARTUri -cmd $cmd -arg @{P4_Path = $P4_Path; p4_ip = $p4_ip; P4_Work_Space_Folder = $P4_Work_Space_Folder }
#if ($P4_Path.GetType().Name -eq "String") {
#    #analytics directory
#    $projectPath = Convert-P4LocationToWinLocation -P4Location $P4_Path -P4_Work_Space_Folder c:\p4
#}

function Build-Project
{
    #Build Solution
    if($reportTable.Length -eq 0)
    {
        $logger.info("Build information in: <$(Join-Path -Path $projectPath -ChildPath $buildFile)>")
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
                $elements = $buildInfo[$i].Split('>')
                $dllPath = $elements[$elements.Count - 1].Substring(1)
                return $dllPath
            }
        }
        $logger.error('Error Building the project')
        return $false
    }
}

$logger.debug("Changing directory to path <$($projectPath)>")
cd $projectPath
mkdir $mvtPath

#Install Choco
$logger.info("Installing prerequisites")
$logger.debug("Installing Choco")
try
{
    choco --version
}
catch
{
    $logger.info("Installing Chocolatey")
    Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
}

$logger.info('Installing Node')
&choco install nodejs --version=16.19.0 -f -y

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

#Build Solution
$dllPath = Build-Project

if(-not $dllPath)
{
    $logger.error('Problems building the solution')

    #Get Framework
    $logger.info("Looking for the .csproj file")
    $pathLstCsproj = Get-ChildItem -Path .\ -Recurse -Filter *.csproj
    $pathCsproj = $pathLstCsproj[0].FullName
    $logger.debug("CSPROJ found, path: <$($pathCsproj)>")
    [xml]$csprojInfo = Get-Content $pathCsproj

    $findFramework = $false
    $frameworks2Install = [System.Collections.ArrayList]@()
    $logger.info('Looking for the framework')
    for($i = 0; $i -lt $csprojInfo.Project.ItemGroup.Count; $i++)
    {
        if($csprojInfo.Project.ItemGroup[$i].Reference.Count -gt 0)
        {
            $findFramework = $true
            for($ref = 0; $ref -lt $csprojInfo.Project.ItemGroup[$i].Reference.Count; $ref++)
            {
                $refKey = $csprojInfo.Project.ItemGroup[$i].Reference[$ref].Include.split(',')[0]
                if($frames[$refKey] -ne $null)
                {
                    $logger.debug("Framework: $($refKey) found")
                    $logger.debug("Adding Framework into the list: $($frames[$refKey])")
                    [void]$frameworks2Install.Add($frames[$refKey])
                }
            }
        }
    }
    $frameworks2Install = $frameworks2Install | Sort-Object -Unique

    $logger.info("Installing Nuget")
    choco install nuget.commandline -f -y

    $logger.debug("Installing Unit Test Package")
    mkdir $packagesPath
    cd $packagesPath

    foreach($package in $frameworks2Install)
    {
        NuGet Install VS.QualityTools.UnitTestFramework
    }
    NuGet Install VS.QualityTools.UnitTestFramework
    $pathLstUtest = Get-ChildItem -Path '.\' -Recurse -ErrorAction SilentlyContinue -Filter *QualityTools.UnitTestFramework.dll | Where-Object Mode -Match 'a' | Sort-Object -Property LastWriteTime -Descending
    $pathUTest = $pathLstUtest[0].FullName
    cd ..


}


if($dllPath)
{
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
}




