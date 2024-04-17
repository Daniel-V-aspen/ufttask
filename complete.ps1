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

$reportTable = @()
function ReportObject($id, $description, $result)
{
    $obj = New-Object PSObject
    $obj|Add-Member -MemberType NoteProperty -Name "Id" -Value $id
    $obj|Add-Member -MemberType NoteProperty -Name "Description" -Value $description
    $obj|Add-Member -MemberType NoteProperty -Name "Result" -Value $result
    return $obj
}

$pathUTest = "C:\Users\administrator\Desktop\Git\MtellCore-UFT\VS.QualityTools.UnitTestFramework.15.0.27323.2\lib\Microsoft.VisualStudio.QualityTools.UnitTestFramework.dll"

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

#Move to project path
cd $projectPath


$logger.info("Looking for the .csproj file")
$pathLstCsproj = Get-ChildItem -Path .\ -Recurse -Filter *.csproj
$pathCsproj = $pathLstCsproj[0].FullName
$logger.debug("CSPROJ found, path: <$($pathCsproj)>")

[xml]$csprojInfo = Get-Content $pathCsproj

$logger.info("Starting process to replace the references")
$findRequirements = $false
$refFound = 0
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
                $logger.debug("Adding hitpath: $($references[$refKey])")
                $csprojInfo.Project.ItemGroup[$i].Reference[$ref].HintPath = $references[$refKey]
                $csprojInfo.Project.ItemGroup[$i].Reference[$ref].SpecificVersion = $false
            }
        }
    }
}
$logger.info("Saving changes in the .csparoj <$($pathCsproj)>")
$csprojInfo.Save($pathCsproj)

if(-not($findRequirements))
{
    $reportTable += @(ReportObject -id "References" -description "Unable to find the references" -result "Fail")
}

if($refFound -ne $references.Count)
{
    $reportTable += @(ReportObject -id "Number of references found" -description "Unable to find all the references, References found: <$($refFound), expected references $($references.Count)>" -result "Fail")
}
