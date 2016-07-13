Param
(
  [parameter(Mandatory=$False)]
  [String[]]
  $LINK,
  [parameter(Mandatory=$False)]
  [String[]]
  $LINKURL,
  [parameter(Mandatory=$False)]
  [String[]]
  $Icon,
  [parameter(Mandatory=$False)]
  $Data_Errors = "$env:windir\temp\ltpsScriptErrors.txt"

)

Function Do-BuildDesktopIcon{

Param
(
  [parameter(Mandatory=$True)]
  [String[]]
  $LINK,
  [parameter(Mandatory=$True)]
  [String[]]
  $LINKURL,
  [parameter(Mandatory=$True)]
  [String[]]
  $Icon

)

#Build URL file with StreamWriter

[string]$WriteInfo = $Desktop + "\" + $LINK + ".url"
$Writer =  [System.IO.StreamWriter]"$WriteInfo"
    $Writer.WriteLine("[InternetShortcut]");
    $Writer.WriteLine("IconFile=" + $Icon);
    $Writer.WriteLine("IconIndex=0")
    $Writer.WriteLine("URL=" + $LINKURL);
        $Writer.Flush();

}


#Get User Desktop
#$DKTPPath = [System.Environment+SpecialFolder]::DesktopDirectory
$DKTPPath = [System.Environment+SpecialFolder]::CommonDesktopDirectory
$Desktop = [System.Environment]::GetFolderPath($DKTPPath)


#Run Function for URL ShortCutLink
Try{
        Do-BuildDesktopIcon -LINK $LINK -LINKURL $LINKURL -Icon $ICON

   }
Catch{
        $ErrorMesg = (Get-date).ToString("yyyy-MM-dd HH:mm:ss") + " Error: " + $Error[0]
        Out-File -FilePath $Data_Errors -InputObject $ErrorMesg -Append

    }