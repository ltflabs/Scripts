  Param
    (
        [Parameter(Mandatory=$False)]
        [Int]$ComputerID = "1",
        [Parameter(Mandatory=$False)]
        $ltp_LogErrors = "$env:windir\temp\ltspErrors.txt",
        [Parameter(Mandatory=$False)]
        $DMLFile = "$env:windir\temp\DML.txt"
    )


Try{

    $Files = Get-ChildItem -Path 'L:\Uploads\PeopleMetrics\PMBACKUP-435' -Recurse -ErrorAction SilentlyContinue| ?{$_.CreationTime -gt (Get-Date).AddDays(-1) -and $_.Extension -eq '.xml'}

            for([int]$i=0;$i -lt $Files.Count;$i++)
            {
                $CurFile = $Files[$i]
                [xml]$BackupFile = (Get-Content $CurFile.FullName)
                [int]$JobEnd = (($BackupFile.GetElementsByTagName("end_time")).Count - 1)
                
                

                $BackupStats = New-Object -TypeName PSObject -Property @{
                        Server = $BackupFile.GetElementsByTagName("server")[0].InnerXml;
                        JobName = $BackupFile.GetElementsByTagName("name")[0].InnerXml;
                        StartTime = ((($BackupFile.GetElementsByTagName("start_time")[0].InnerXml).Replace("Job started:",'')).Replace("at",'')).ToString();
                        Description = $BackupFile.GetElementsByTagName("description")[0].InnerXml;
                        BackType = $BackupFile.GetElementsByTagName("job_backup_type")[0].InnerXml;
                        EndTime = ((($BackupFile.GetElementsByTagName("end_time")[$JobEnd].InnerXml).Replace('Job ended:','')).Replace("at",'')).ToString();
                        Status = ($BackupFile.GetElementsByTagName("engine_completion_status")[0].InnerXml).Replace('Job completion status:','');
                        ErrorMesg = if(!$BackupFile.GetElementsByTagName("errorDescription")[0].InnerXml){''}else{$BackupFile.GetElementsByTagName("errorDescription")[0].InnerXml};
                      }

                      #build Insert
                      $Server = $BackupStats.Server;
                      $Name = $BackupStats.JobName.ToString();
                      $StartTime = [datetime]::Parse($BackupStats.StartTime).ToString("yyyy-MM-dd HH:mm:ss").Trim();
                      $BackupType = $BackupStats.BackType;
                      $EndTime = [datetime]::Parse($BackupStats.EndTime).ToString("yyyy-MM-dd HH:mm:ss").Trim();
                      $Status = $BackupStats.Status;
                      $BKErrorMesg = $BackupStats.ErrorMesg;

                      $DML = "INSERT INTO `ltspbackupexec` (`ComputerID`,`Server`,`JobName`,`StartTime`,`BackupType`,`EndTime`,`Status`,`ErrorMessage`,`LastCheck`) Values (" + "'$ComputerID'" + "," + "'$Server'" + "," + "'$Name'" + "," +  "'$StartTime'" + "," + "'$BackupType'" + "," + "'$EndTime'" + "," + "'$Status'" + "," + "'$BKErrorMesg'" + ", NOW()" + "); `r`n";
                
                Out-File -FilePath $DMLFile -InputObject $DML -Append

            }

    }
Catch{
        $ErrorMesg = (Get-date).ToString("yyyy-MM-dd HH:mm:ss") + " ErrorState: " + $Error[0]
        write-host $ErrorMesg
        Out-File -FilePath $ltp_LogErrors -InputObject $ErrorMesg -Append

     }
Finally{
        
        $FinallyMessage = (Get-date).ToString("yyyy-MM-dd HH:mm:ss") + "------------ Completed Backup Inventory---------- " 
        Out-File -FilePath $ltp_LogErrors -InputObject $FinallyMessage -Append
}