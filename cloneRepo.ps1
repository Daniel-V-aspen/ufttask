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

#inputs MVT
$P4_Project_Path = (Load-Setting -sARTServerUri $sARTUri -vision $vision  -project $blueprint -task $task1 -key P4_Project_Support) #Testcase you want to sync up. Support P4 and GIT https://aspentech-alm.visualstudio.com/AspenTech/_git/k6
$projectPath = Load-Setting -sARTServerUri $sARTUri -vision $vision -project $blueprint -task $task1 -key "Project path" # Relative folder of the project 
$projectName = Load-Setting -sARTServerUri $sARTUri -vision $vision -project $blueprint -task $task1 -key "Neme of the project" # Name of the project in UFT

#Clone Repo
$logger.info("Cloning repo: <$($P4_Project_Path)>")
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
