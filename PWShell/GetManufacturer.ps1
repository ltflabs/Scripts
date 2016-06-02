  Param
    (

        [Parameter(Mandatory=$false)]
        [string]$Path,
        [Parameter(Mandatory=$False)]
        $ltp_LogErrors = "$env:windir\temp\ltspErrors.txt",
        [Parameter(Mandatory=$False)]
        $DMLFile = "$env:windir\temp\DMLNetDev.txt"
    )


 function Get-manufacturer{
        
   Param
    (
        [Parameter(Mandatory=$true)]
        [string]$MAC,
        [Parameter(Mandatory=$true)]
        [string]$DeviceID
    )


    $URL = "http://www.macvendorlookup.com/api/json/$MAC"

    #Create WebRequest
    $WebRequest = [System.Net.WebRequest]::Create($URL)

    #Open DataStream and Read Response
    [System.IO.Stream]$ObjStream = $WebRequest.GetResponse().GetResponseStream();
     $ReadStream = New-Object System.IO.StreamReader($ObjStream)
        $Line = $ReadStream.ReadLine()
            if($Line -like 'Error*' -or $Line.Length -lt 12){
                $DMLUpdate = "UPDATE networkdevices SET `ManufacturerName` = 'NotFound' WHERE deviceID = " + "$DeviceID" + ";"
                }
            else{
                    #RegEx through JSON for Company   
                    $Pattern = New-Object System.Text.RegularExpressions.Regex('\,"company":(.*),"addressL1"')
                    $CompanyMatch = $Pattern.Matches($Line)
                    $Companyout =  ($CompanyMatch[0].Groups[1].Captures[0].Value).ToString().Replace('"','').Trim()
                       $DMLUpdate = "UPDATE networkdevices SET `ManufacturerName` = " + '"' + $Companyout + '"' + " WHERE deviceID = " + "$DeviceID" + ";" 
                }
             return $DMLUpdate
}



      Try{
            
            #Read NetDevices from Text List and run Get-Manufacturer function to query API
               $Devices = (Get-Content $Path).Split(',')

               $SQLStart = "START TRANSACTION;" 
               Out-File -FilePath $DMLFile -InputObject $SQLStart -Append

                       for([int]$i=0;$i -lt $Devices.Count;$i++){
                            $CurrentSet = $Devices[$i]
                                $DeviceID = $CurrentSet.Split(' ')[0]
                                $MAC = $CurrentSet.Split(' ')[1]

                        $Manufacturer = Get-manufacturer -MAC $MAC -DeviceID $DeviceID

                        #Output DML statements to a File to be read and executed by SQL
                        Out-File -FilePath $DMLFile -InputObject $Manufacturer -Append
                        }

                $SQLEnd = "COMMIT;"
                Out-File -FilePath $DMLFile -InputObject $SQLEnd -Append
         }
    Catch{
            $ErrorMesg = (Get-date).ToString("yyyy-MM-dd HH:mm:ss") + " Error: " + $Error[0]
            Out-File -FilePath $ltp_LogErrors -InputObject $ErrorMesg -Append
            

     }
    Finally{
        
            $FinallyMessage = (Get-date).ToString("yyyy-MM-dd HH:mm:ss") + "------------ Completed Networkdevice Test---------- " 
            Out-File -FilePath $ltp_LogErrors -InputObject $FinallyMessage -Append
            }

