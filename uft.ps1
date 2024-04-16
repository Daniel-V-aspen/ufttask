$pathLogs = ".\MvtUftLogs.txt"
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
$logger.start()

$sARTUri = 'http://mvf1:3000'
$taskName = "uft_runner"
$DebugPreference = "Continue"


#$sARTUri = 'http://hqqaeblade710.qae.aspentech.com:3000'
# $vision = "Mtell Deployment No31 in US East"
# $blueprint = "Mtell Deployment No31 in US East_Deployment_Automated"
# $task1 = "Web_Certificate"


while ($true) {
    try {
        iex ((New-Object System.Net.WebClient).DownloadString("$sARTUri/api/ps/MediaInstallation@MediaInstallationLibrary.ps1"))
        iex ((New-Object System.Net.WebClient).DownloadString("$sARTUri/api/ps/Library.ps1"))
        iex ((New-Object System.Net.WebClient).DownloadString("$sARTUri/api/ps/CommonHeader.ps1"))
        Write-Host "`nART Libraries were imported"
        break
    }
    catch {
        Write-Host "`nCould NOT import the ART Libraries"
    }
}

#I should find a different way to build the solution. Nuget and MSBuild tool kit must work. 

#inputs MVT
$P4_Project_Path = (Load-Setting -sARTServerUri $sARTUri -vision $vision  -project $blueprint -task $task1 -key P4_Project_Support) #Testcase you want to sync up. Support P4 and GIT https://aspentech-alm.visualstudio.com/AspenTech/_git/k6
$projectPath = Load-Setting -sARTServerUri $sARTUri -vision $vision -project $blueprint -task $task1 -key "Project path" # Relative folder of the project 
$projectName = Load-Setting -sARTServerUri $sARTUri -vision $vision -project $blueprint -task $task1 -key "Neme of the project" # Name of the project in UFT

#inputs Debug
#$projectPath = 'C:\Users\administrator\Desktop\Git\MtellCore-UFT'
#$projectName = 'Mtell Automation'

#folders
$dirUtFramework = 'C:\Program Files (x86)\Microsoft Visual Studio\2019\Enterprise\Common7\IDE\PublicAssemblies'
$dirUftDotnet = 'C:\Program Files (x86)\Micro Focus\UFT Developer\SDK\DotNet'
$dirUftBin = 'C:\Program Files (x86)\Micro Focus\UFT Developer\bin\'

#build information
$buildFile = '.\buildInformation.txt'
$mvtReport = '.\mvtReport.csv'

#Clone Repo
$cmd = { Sync-FromP4 -P4_User wuwei -P4_Server hqperforce2.corp.aspentech.com:1666 -P4_Location_List @($P4_Path) -P4_PASSWORD $secureString_wwwPass -P4_Work_Space_Folder c:\p4 -P4_Work_Space_Name ART -gitAccessToken $secureString_www_git -gitHubAccessToken $secureString_www_github_password }
Run-SecureCmd -sARTUri $sARTUri -cmd $cmd -arg @{P4_Path = $P4_Path; p4_ip = $p4_ip; P4_Work_Space_Folder = $P4_Work_Space_Folder }
if ($P4_Path.GetType().Name -eq "String") {
    #analytics directory
    $sAnalytics_directory = Convert-P4LocationToWinLocation -P4Location $P4_Path -P4_Work_Space_Folder c:\p4
    $sAnalytics_Invoker = Join-Path -Path $sAnalytics_directory -ChildPath $FileName
    if ((Test-Path -Path $sAnalytics_Invoker) -ne $true) {
        $sAnalytics_Invoker = Convert-P4LocationToWinLocation -P4Location $FileName -P4_Work_Space_Folder c:\p4
    }
}
else {
    $sAnalytics_Invoker = Convert-P4LocationToWinLocation -P4Location $FileName -P4_Work_Space_Folder c:\p4
}
$sAnalytics_Invoker = Join-Path -Path $sAnalytics_directory -ChildPath $FileName
$activeFolder = Split-Path -Path $sAnalytics_Invoker -Parent
Set-Location -Path $activeFolder
$transcriptPath = Join-Path -Path $activeFolder -ChildPath "$task1.log"
Start-Transcript -Path $transcriptPath -Force

#Move to project path
Join-Path -Path $activeFolder -ChildPath $projectPath
$logger.info("Moving into path $($projectPath)")
cd $projectPath

#Validating Dlls
$logger.info("Checking prerequisites")
$logger.debug("Checking Unit Test Framework: <$($dirUtFramework)>")
if(-not(Test-Path -Path $dirUtFramework))
{
    $logger.error("Unit Test Framework path not found: <$($dirUtFramework)>")
    Start-Sleep -Seconds 10
}
$logger.debug("Checking UFT dotnet dlls: <$($dirUftDotnet)>")
if(-not(Test-Path -Path $dirUftDotnet))
{
    $logger.error("Dotnet dlls path not found: <$($dirUftDotnet)>")
    Start-Sleep -Seconds 10
}
$logger.debug("Checking UFT bins dlls: <$($dirUftBin)>")
if(-not(Test-Path -Path $dirUftBin))
{
    $logger.error("UFT bins dlls path not found: <$($dirUftBin)>")
    Start-Sleep -Seconds 10
}

#Validate Dotnet, Here should be the option to use Nuget, or MSBuild tool kit, use chocolatey mvt task
try
{
    dotnet --version
}
catch
{
    $logger.error("Dotnet not installed in this VM")
}

#Build Solution
$logger.info("Build information in: <$($projectPath)\$buildFile>")
dotnet build > $buildFile 

#Looking for the dll
$logger.info("Looking for the dll")
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
}
$logger.info("dll in path <$($dllPath)>")
if (-not(Test-Path -Path $dllPath))
{
    $logger.error("Dll path not found, path: <$($dllPath)>")
}

# Execute the automation, Before this I need to be sure that the service is running
$logger.info('Excecuting UFT')
vstest.console.exe $dllPath


#Get results
$logger.info("Looking for the results file")
$reportFilePath = Get-ChildItem -Path '.\' -Recurse -ErrorAction SilentlyContinue -Filter *.xml | Sort-Object -Property LastWriteTime -Descending
$logger.info("Report file found in the path: <$($reportFilePath[0].FullName)>")


#Extracting the content from the last File storaged inside a variable named $text
$logger.info("Creating MVT report")
[xml]$xmlReport = Get-Content -Path $reportFilePath[0].FullName
$xmlData = $xmlReport.Results.ReportNode.ReportNode.ReportNode.ReportNode.ReportNode.Data


#Define a function to create the Result Object as a Matrix
function ReportObject($id, $description, $result)
{
    $obj = New-Object PSObject
    $obj|Add-Member -MemberType NoteProperty -Name "Id" -Value $id
    $obj|Add-Member -MemberType NoteProperty -Name "Description" -Value $description
    $obj|Add-Member -MemberType NoteProperty -Name "Result" -Value $result
    return $obj
}

#Creating MVT Report
$reportTable = @()        
for($i = 0; $i -lt $xmlData.Length; $i++){
    $id = $xmlData[$i].Name.InnerText.Replace("_", "")       # This line removes the underscore of the test's name

    $description = $xmlData[0].ErrorText.InnerText
    $logger.debug("TC Name: <$($xmlData[0].Name.InnerText)>; TC Description: <$($xmlData[0].ErrorText.InnerText)>; TC Result: <$($xmlData[$i].Result)>;")

    #This clause is made to get a correct email report with MVT task
    if ($xmlData[$i].Result.Contains("Passed")) {
        $result = "Pass"
    }
    else {
        $result = "Fail"
    }

    $reportTable += @(ReportObject -id $id -description $description -result $result)
}


$logger.info("Mvt Report in path: <$($mvtReport)>")
$reportTable | Export-Csv -Path $mvtReport -NoTypeInformation -Encoding UTF8 -Force

#project finish!
#Set-NextProject -sARTServerUri $sARTUri -vision $vision -project $projectId -completion $lsCompletion