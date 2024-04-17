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
#$P4_Project_Path = (Load-Setting -sARTServerUri $sARTUri -vision $vision  -project $blueprint -task $task1 -key P4_Project_Support) #Testcase you want to sync up. Support P4 and GIT https://aspentech-alm.visualstudio.com/AspenTech/_git/k6
#$projectPath = Load-Setting -sARTServerUri $sARTUri -vision $vision -project $blueprint -task $task1 -key "Project path" # Relative folder of the project 
#$projectName = Load-Setting -sARTServerUri $sARTUri -vision $vision -project $blueprint -task $task1 -key "Neme of the project" # Name of the project in UFT

#inputs Debug
$projectPath = 'C:\Users\administrator\Desktop\Git\MtellCore-UFT'
$projectName = 'Mtell Automation'

#Move to project path
cd $projectPath

$pathLeanft = 'C:\Program Files (x86)\Micro Focus\UFT Developer\bin\leanft.bat'

$logger.info("Start Leanft Services")
for($i = 0 

& $pathLeanft start  > .\.uftServiceStart.txt
Start-Sleep -Seconds 2
& $pathLeanft info  > .\.uftServiceStatus.txt



