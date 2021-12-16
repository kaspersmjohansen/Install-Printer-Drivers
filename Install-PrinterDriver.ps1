Param(
    [Parameter(Mandatory = $true)]
    [array]$PrtSrvName # Multiple print servers separated by , "srvprn01.domain.local","srvprn02.domain.local"
)

# Modify current Point and Print and Package Point and Print restrictions
$PointPrintkey = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers\PointAndPrint"
$PackagePointPrintKey = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers\PackagePointAndPrint\ListofServers"

$PointPrintSrvList = $PrtSrvName -join ";"
If (Test-Path -Path $PointPrintkey)
{
    New-ItemProperty $PointPrintkey  -Name "Restricted" -Value "1" -PropertyType DWORD -Force -Verbose
    New-ItemProperty $PointPrintkey -Name "TrustedServers" -Value "1" -PropertyType DWORD -Force -Verbose
    New-ItemProperty $PointPrintkey -Name "ServerList" -Value $PointPrintSrvList -PropertyType STRING  -Force -Verbose
    New-ItemProperty $PointPrintkey -Name "InForest" -Value "0" -PropertyType DWORD -Force -Verbose
    New-ItemProperty $PointPrintkey -Name "NoWarningNoElevationOnInstall" -Value "1" -PropertyType DWORD -Force -Verbose
    New-ItemProperty $PointPrintkey -Name "UpdatePromptSettings" -Value "2" -PropertyType DWORD -Force -Verbose
}
    else
    {
        New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\" -Name "Printers" -Verbose
        New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers" -Name "PointAndPrint" -Verbose
        New-ItemProperty $PointPrintkey -Name "Restricted" -Value "1" -PropertyType DWORD -Force -Verbose
        New-ItemProperty $PointPrintkey -Name "TrustedServers" -Value "1" -PropertyType DWORD -Force -Verbose
        New-ItemProperty $PointPrintkey -Name "ServerList" -Value $PointPrintSrvList -PropertyType STRING  -Force -Verbose
        New-ItemProperty $PointPrintkey -Name "InForest" -Value "0" -PropertyType DWORD -Force -Verbose
        New-ItemProperty $PointPrintkey -Name "NoWarningNoElevationOnInstall" -Value "1" -PropertyType DWORD -Force -Verbose
        New-ItemProperty $PointPrintkey -Name "UpdatePromptSettings" -Value "2" -PropertyType DWORD -Force -Verbose
    }

            # Enable Package Point and Print restrictions
            If (Test-Path -Path $PackagePointPrintKey)
            {
                ForEach ($PrtSrv in $PrtSrvName)
                {
                    New-ItemProperty $PackagePointPrintKey -Name $PrtSrv -Value $PrtSrv -PropertyType STRING
                }
            }
                else
                {
                    New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\" -Name "Printers" -Verbose
                    New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers" -Name "PackagePointAndPrint" -Verbose
                    New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers\PackagePointAndPrint" -Name "ListofServers" -Verbose

                        ForEach ($PrtSrv in $PrtSrvName)
                        {
                            New-ItemProperty $PackagePointPrintKey -Name $PrtSrv -Value $PrtSrv -PropertyType STRING
                        }    
                }

ForEach ($PrtSrv in $PrtSrvName)
{
    $Drivers = (Get-Printer -ComputerName $PrtSrv | Where-Object {$_.PortName -ne "PORTPROMPT:"}).DriverName | Sort-Object -Unique
    
    ForEach ($Driver in $Drivers)
    {
        $UniquePrt = Get-Printer -ComputerName $PrtSrv | where {$_.DriverName -eq $driver} | Sort-Object DriverName -Unique
        ForEach ($Prt in $UniquePrt)
        {
            $PrtSrvName = $Prt.ComputerName
            $ShareName = $Prt.Name
            $PortName = $Prt.PortName
            Write-Output "Connecting to $ShareName on $PrtSrvName on $PortName"
            Add-Printer -ConnectionName "\\$PrtSrvName\$ShareName" -Verbose   
        }      
    }
}

Get-Printer | where {$_.Type -eq "Connection"} | Remove-Printer  