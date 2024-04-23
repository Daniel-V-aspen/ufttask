#getresults
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


#inputs Debug
$projectPath = 'C:\Users\administrator\Desktop\Git\MtellCore-UFT'
$projectName = 'Mtell Automation'
$testplanPath = 'testplan.txt'


$dllPath = 'C:\Users\administrator\Desktop\Git\MtellCore-UFT\Mtell Automation\bin\Debug\Mtell Automation.dll'

#Move to project path
cd $projectPath

#Get list of test cases
$testplanFullPath = Join-Path -Path $projectPath -ChildPath $testplanPath
Test-Path -Path $testplanFullPath
$testPlanInfo = Import-Csv -Path $testplanFullPath

$tpInfo = @{}
$tc2Run = ''
foreach($testcase in $testPlanInfo)
{
    $tpInfo[$testcase.name] = $testcase.id
    $tc2Run += $testcase.name + ','
}
#Get results
$logger.info("Looking for the results file")
$reportFilePath = Get-ChildItem -Path '.\' -Recurse -ErrorAction SilentlyContinue -Filter *.trx | Sort-Object -Property LastWriteTime -Descending
$logger.info("Report file found in the path: <$($reportFilePath[0].FullName)>")


#Extracting the content from the last File storaged inside a variable named $text
$logger.info("Creating MVT report")
[xml]$xmlReport = Get-Content -Path $reportFilePath[0].FullName
$xmlData = $xmlReport.TestRun.Results


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
foreach($result in $xmlData){
    $id = $tpInfo[$result.UnitTestResult.testName]
    $description = 'Test Name: ' + $result.UnitTestResult.testName + 'Duration ' + [string]$result.UnitTestResult.duration
    if ($result.UnitTestResult.outcome.Contains("Passed")) {
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