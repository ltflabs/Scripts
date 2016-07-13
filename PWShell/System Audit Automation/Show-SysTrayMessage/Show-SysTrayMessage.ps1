  Param(
            [Parameter(Mandatory=$False)]
            [string]$Iconfilepath,
            [Parameter(Mandatory=$False)]
            [string]$BallonType = 'Info',
            [Parameter(Mandatory=$False)]
            [string]$BallonTitle,
            [Parameter(Mandatory=$False)]
            [string]$BallonText 
        
        )
        



function Set-BallonProperties{


    Param(

            [string]$Iconfile,
            [string]$BallonTitle,
            [string]$BallonType,
            [string]$BallonText

            )

                $NotifyIcon.Icon = $Iconfile
                $NotifyIcon.BalloonTipTitle = $BallonTitle
                $NotifyIcon.BalloonTipText = $BallonText
                $NotifyIcon.Visible = $true
                $NotifyIcon.ShowBalloonTip(10000)
                
                
}






#[void][System.Reflection.Assembly]::LoadFile('C:\Windows\Microsoft.NET\Framework64\v4.0.30319\System.Windows.Forms.dll')
[void][System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms.dll')
$NotifyIcon = New-Object System.Windows.Forms.NotifyIcon



$Messege = Set-BallonProperties -Iconfile $Iconfilepath -BallonType $BallonType -BallonText $BallonText
$Messege
$NotifyIcon.Icon = $null;

#EndScript