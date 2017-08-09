<#
    .SYNOPSIS
    This module is design to hold common funtions needed to add Win Feature Sets
    
    .DESCRIPTION
    Long description
    
    .EXAMPLE
    An example
()
#>


function Get-WinFeatureStatus {
    <#
    .SYNOPSIS
    Short description

    .EXAMPLE
    An example
    #>
    
    # Parameters used by this function
    param(
        [Parameter(Mandatory = $false)]
        [string]$featureName
    )

    try {

        $validateFeatureName = if (!(Get-WindowsFeature -Name $featureName)) {
            $null
            #Write-Verbose "Feature Name Not Valid"
            Write-Error -Message "Feature Not Valid"
        }
        else {
            1
        }

        if ($validateFeatureName -ne $null) {

            $featurestatus = if (((Get-WindowsFeature -Name $featureName).Installed) -eq $true) {
                return 1
            }
            else {return 0}

        }

        return $featurestatus
    }
    catch {
        $line = $_.InvocationInfo.ScriptLineNumber
        $ErrorMesg = (Get-date).ToString("yyyy-MM-dd HH:mm:ss") + " Error: Line(" + $line + ")" + $Error[0]
        Out-File -FilePath $cwaErrLogFile -InputObject $ErrorMesg -Append
    }
}

function Get-RebootNeeded {
    <#
    .SYNOPSIS
    Short description

    .EXAMPLE
    An example
    #>

    #Check all reboot locations
    try {
        if (Get-ChildItem "HKLM:\Software\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending" -EA Ignore) {
            return 1
        }
        elseif (Get-Item "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired" -EA Ignore) {
            return 1
        }
        elseif (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager" -Name PendingFileRenameOperations -EA Ignore) {
            return 1
        }
        else {
            return 0
        }
    }
    catch {
        $line = $_.InvocationInfo.ScriptLineNumber
        $ErrorMesg = (Get-date).ToString("yyyy-MM-dd HH:mm:ss") + " Error: Line(" + $line + ")" + $Error[0]
        Out-File -FilePath $cwaErrLogFile -InputObject $ErrorMesg -Append
    }  
}

function Add-WinDesktopExperience {
    <#
    .SYNOPSIS
    Short description

    .EXAMPLE
    An example
    #>

    # Parameters used by this function
    Param(
        $ComputerName = $env:COMPUTERNAME
    )

    $VerbosePreference = "Continue"

    try {
        $prereqcheck = (Get-WinFeatureStatus -featureName "InkAndHandwritingServices")
        $deInstalled = Get-WinFeatureStatus -featureName "Desktop-Experience"
        if ($deInstalled -eq 0 -and $prereqcheck -eq 1) {
            Install-WindowsFeature Desktop-Experience
        }
        elseif ($deInstalled -eq 1) {
            Write-Verbose "Desktop-Experience is already installed"
        }
        elseif ($deInstalled -eq 0 -and $prereqcheck -eq 0) {
            Write-Verbose "Can not add feature. Prerequisite checks were not met. Please reference *more info here for prereqs"
        }
        else {
            Write-Verbose "Was not able to dermine if the feature was installed or not. This maybe an environmental issue. Exiting Script..."
        }

        $Rebootcheck = Get-RebootNeeded
        if ($Rebootcheck -eq 1) {
            Write-Verbose "Reboot Needed. Restarting Server"
            Restart-Computer -ComputerName $ComputerName -Force -Delay 10
        }
        else {
            Write-Verbose "No reboot Needed"
        }

    }
    catch {
        $line = $_.InvocationInfo.ScriptLineNumber
        $ErrorMesg = (Get-date).ToString("yyyy-MM-dd HH:mm:ss") + " Error: Line(" + $line + ")" + $Error[0]
        Out-File -FilePath $cwaErrLogFile -InputObject $ErrorMesg -Append
    }  
}

function Invoke-CleanWinsxs {

    try {
        #Check for Update Clean Option in Registry
        $sageSet = 0045

        #Turn everything off to clean specific win updates
        $subKeys = (Get-ChildItem Registry::"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches").Name
        Foreach ($key in $subKeys) {
            if ((Get-ItemProperty Registry::$key -Name "StateFlags*")) {
                Set-ItemProperty -Path $key.PSPath -Name 'StateFlags*' -Value 0 
            }

            #check for custom key and turn that on
            if ((Get-ItemProperty Registry::"$key\Update Cleanup")) {
                Set-ItemProperty -Path $key.PSPath -Name "StateFlags$sageSet" -Value 2
            }
            else {
                New-ItemProperty -Path "$key\Update Cleanup" -Name StateFlags$sageSet -Value 2 -PropertyType DWord
            }
        }            
      
        #now that this is created we can run the clean manager
        $logStart = (Get-date).ToString("yyyy-MM-dd HH:mm:ss") + "Starting CleanManager"
        Write-Verbose $logStart
        Start-Process -FilePath 'C:\Windows\System32\Cleanmgr.exe' -ArgumentList "/sagerun:$sageSet" -WindowStyle Hidden -Wait
        $logEnd = (Get-date).ToString("yyyy-MM-dd HH:mm:ss") + "Completed CleanManager"
        Write-Verbose $logEnd

        #now turn everything back off... just in case
        Foreach ($regKey in $subKeys) {
            Set-ItemProperty -Path $key.PSPath -Name 'StateFlags*' -Value 0
        }
    }
    catch {
        $line = $_.InvocationInfo.ScriptLineNumber
        $ErrorMesg = (Get-date).ToString("yyyy-MM-dd HH:mm:ss") + " Error: Line(" + $line + ")" + $Error[0]
        Out-File -FilePath $cwaErrLogFile -InputObject $ErrorMesg -Append

    }

}