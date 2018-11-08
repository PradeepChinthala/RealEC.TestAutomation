Param(
	[Parameter(Position=0)]	
	[string]$parentDestination
)

$csprojSearchPattern ="(<TestProjectType>UnitTest</TestProjectType>)|(<TestProjectType>CodedUITest</TestProjectType>)"

function RemoveItems([string]$dir){
    if (Test-Path -Path $dir -ErrorAction SilentlyContinue){
        Try {
            Get-ChildItem -Path $dir -Recurse -Force|
                Where-Object {-not($_.psiscontainer)}|
                Remove-Item -Force
            Remove-Item -Recurse -Force $dir
            Write-Host "Directory is removed " $dir 
            }
            Catch{
                write-host "Cannot delete directory: " $dir
            }
    }
    else{
        write-host "Directory does not exist: " $dir
    }
}

function AddReportCreator([string]$dir){
    $destinationFolder = Join-Path $dir -ChildPath "ReportCreator"
    New-Item -ItemType Directory -Force -Path $destinationFolder
    $sourceDir = Join-Path "ReportCreator" -ChildPath "bin\Debug\*.*"
    Copy-Item -Path $sourceDir -Destination $destinationFolder -Recurse -Force
    $sourceDir = Join-Path "ReportCreator" -ChildPath "bin\Debug\Transformations\*"
    Copy-Item -Path $sourceDir -Destination $destinationFolder -Recurse -Force
    write-host "Report Creator is added"
}

function AddResultPublisher([string]$dir){
    $destinationFolder = Join-Path $dir -ChildPath "ResultPublisher"
    New-Item -ItemType Directory -Force -Path $destinationFolder
    $sourceDir = Join-Path "ResultPublisher" -ChildPath "bin\Debug\*"
    Copy-Item -Path $sourceDir -Destination $destinationFolder -Recurse -Force
    write-host "Result Publisher is added"
}

function VerifyUnitTestProjFiles([string]$dir) {    
    $matchFile = Get-ChildItem -Path $dir | where {$_.Extension -eq ".csproj"}| Select-String -pattern $csprojSearchPattern | group path | select -ExpandProperty name
    if($matchFile -ne $null) {
        return $true
    }
    return $false
}
function GetDestinationFolder([string]$dir){
    $projectFileName = Get-ChildItem -Path $dir | where {$_.Extension -eq ".csproj"}| Select-String -pattern $csprojSearchPattern | group path | select -ExpandProperty name
    $projectFileName = (Get-Item $projectFileName).BaseName
    return $projectFileName
}
function CopyTestDirs {    
    $testDirs = Get-ChildItem | Where {VerifyUnitTestProjFiles $_.Name}
    foreach($dir in $testDirs){
        $destinationFolder = GetDestinationFolder $dir
        $destinationFolder = Join-Path $parentDestination -ChildPath $destinationFolder
        write-host "Destination dir" $destinationFolder
        RemoveItems $destinationFolder
        New-Item -ItemType Directory -Force -Path $destinationFolder
        $sourceDir = Join-Path $dir -ChildPath "bin\Debug\*"
        Copy-Item -Path $sourceDir -Destination $destinationFolder -Recurse -Force
        AddResultPublisher $destinationFolder
        AddReportCreator $destinationFolder
        write-host "Destination folder is created and all files are copied in"
        write-host "Set ReadOnly attribute to false"
        Get-ChildItem $sourceDir -Recurse | Where-Object{$_.GetType().ToString() -eq "System.IO.FileInfo"}| Set-ItemProperty -Name IsReadOnly -Value $false
        write-host "Copy testsettings files"
        Get-ChildItem | Where {$_.Name -Match "\.testsettings"}|Select -ExpandProperty FullName | Copy-Item -Destination $destinationFolder -Force
    }    
}
Try {    	
    CopyTestDirs    
    write-host "Copy Done!";
}
Catch {
    write-host $_.Exception.Message;
	exit -1;
}
