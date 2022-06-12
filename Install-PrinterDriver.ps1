#Requires -RunAsAdministrator
<#

.NAME
    Install-PrinterDriver

.SYNOPSIS
    Install printer drivers from a print server.

.DESCRIPTION
    Install printer drivers from one or more print servers in the network.

    This script is meant to be used on a golden image or on a computer where the end user will not be able to install printer drivers.
    The script goes through the specified print server and installs all available drivers on the golden image.

    As a prerequisite this script configures the Point and Print restrictions and the Package Point and Print restrictions via registry values.

.PARAMETER PrtSrvName
    The name of the print server containing the drivers needed.
    Multiple print server names should be separated by a comma.

.EXAMPLES
   Install the drivers from a single print server 
            Install-PrinterDriver -PrtSrvName srvprn01.domain.local
    
    Install the drivers from two print servers
            Install-PrinterDriver -PrtSrvName "srvprn01.domain.local","srvprn02.domain.local"

.NOTES

    Author:             Kasper Johansen
    Website:            https://virtualwarlock.net
    Last modified Date: 12-06-2022

#>

Param(
    [Parameter(Mandatory = $true)]
    [array]$PrtSrvName
)

# Modify current Point and Print and Package Point and Print restrictions
$PointPrintkey = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers\PointAndPrint"
$PackagePointPrintKey = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers\PackagePointAndPrint\ListofServers"

$PointPrintSrvList = $PrtSrvName -join ";"
If (Test-Path -Path $PointPrintkey)
{
    New-ItemProperty $PointPrintkey -Name "Restricted" -Value "1" -PropertyType DWORD -Force -Verbose
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