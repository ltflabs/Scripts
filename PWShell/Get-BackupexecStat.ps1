  Param
    (
        [Parameter(Mandatory=$False)]
        [int]$ComputerID,
        [Parameter(Mandatory=$False)]
        [string]$Datapath = "C:\Users\Administrator\Desktop\New folder\Zog",
        [Parameter(Mandatory=$False)]
        $DMLFile = "$env:windir\temp\DML.txt",
        [Parameter(Mandatory=$False)]
        $ltp_LogErrors = "$env:windir\temp\ltspErrors.txt"

    )




function Get-BackupInfo{


param(

        [Parameter(Mandatory=$False)]
        [string]$xmlDocName,
        #[int]$End
        [Parameter(Mandatory=$False)]
        $DMLFile

)




#Get Contents of XMLDoc

$XMLContents = New-Object System.Xml.XmlDocument
$XMLContents.Load($xmlDocName)

#Get Last End Time Value
[int]$JobEnd = (($XMLContents.GetElementsByTagName("end_time")).Count - 1)

$BackupStats = New-Object PSObject -Property @{
        'Server' = $XMLContents.GetElementsByTagName("server")[0].InnerXml;
        'JobName' = $XMLContents.GetElementsByTagName("name")[0].InnerXml;
        'StartTime' = ((($XMLContents.GetElementsByTagName("start_time")[0].InnerXml).Replace("Job started:",'')).Replace("at",'')).ToString();
        'Description' = $XMLContents.GetElementsByTagName("description")[0].InnerXml;
        'BackType' = $XMLContents.GetElementsByTagName("job_backup_type")[0].InnerXml;
        'EndTime' = ((($XMLContents.GetElementsByTagName("end_time")[$JobEnd].InnerXml).Replace('Job ended:','')).Replace("at",'')).ToString();
        'Status' = ($XMLContents.GetElementsByTagName("engine_completion_status")[0].InnerXml).Replace('Job completion status:','');
        'ErrorMesg' = if(!$XMLContents.GetElementsByTagName("errorDescription")[0].InnerXml){''}else{$XMLContents.GetElementsByTagName("errorDescription")[0].InnerXml};
}

#build Insert
$Server = $BackupStats.Server;
$Name = $BackupStats.JobName.ToString();
$StartTime = [datetime]::Parse($BackupStats.StartTime).ToString("yyyy-MM-dd HH:mm:ss").Trim();
$BackupType = $BackupStats.BackType;
$EndTime = [datetime]::Parse($BackupStats.EndTime).ToString("yyyy-MM-dd HH:mm:ss").Trim();
$Status = $BackupStats.Status;
$BKErrorMesg = $BackupStats.ErrorMesg;

$DML = "INSERT INTO `script_ltps_backupexecaudit` (`ComputerID`,`Server`,`JobName`,`StartTime`,`BackupType`,`EndTime`,`Status`,`ErrorMessage`,`LastCheck`) Values (" + "'$ComputerID'" + "," + "'$Server'" + "," + "'$Name'" + "," + "'$StartTime'" + "," + "'$BackupType'" + "," + "'$EndTime'" + "," + "'$Status'" + "," + "'$BKErrorMesg'" + ", NOW()" + "); `r`n";


Out-File -FilePath $DMLFile -InputObject $DML -Append



}

Try{

    $Files = Get-ChildItem -Path $Datapath  -Recurse -ErrorAction SilentlyContinue| ?{<#$_.CreationTime -gt (Get-Date).AddDays(-1) -and #>$_.Extension -eq '.xml'}

   #Remove Previous File
    if(Test-Path -Path $DMLFile){
        Remove-Item -Path $DMLFile
        }

        #Read Backupexec Data file Contents for XML Files

        
        #Set Transaction Array for LogFile
        $Transaction = @("START TRANSACTION;","COMMIT;")
        
        #Start Transaction
        Out-File -FilePath $DMLFile -InputObject $Transaction[0] -Append

           foreach($File in $Files){
            
                    
                    Get-BackupInfo -xmlDocName $File.FullName  -DMLFile $DMLFile

           }

        #End Transaction
        Out-File -FilePath $DMLFile -InputObject $Transaction[1] -Append

    }
Catch{
        $ErrorMesg = (Get-date).ToString("yyyy-MM-dd HH:mm:ss") + " ErrorState: " + $Error[0] + $Error[0].ScriptStackTrace
        write-host $ErrorMesg
        Out-File -FilePath $ltp_LogErrors -InputObject $ErrorMesg -Append

     }
Finally{
        
        $FinallyMessage = (Get-date).ToString("yyyy-MM-dd HH:mm:ss") + "------------ Completed Backup Inventory---------- " 
        Out-File -FilePath $ltp_LogErrors -InputObject $FinallyMessage -Append
}