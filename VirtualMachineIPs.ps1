<#PSScriptInfo

.VERSION 1.0

.AUTHOR ruchh@microsoft.com

.COMPANYNAME Microsoft

.RELEASENOTES

<#  
.SYNOPSIS  
  This script takes a SubscriptionID and prints the VM list which have public IPs assigned at the current time. Another list will be printed for Virtual Machines without Public Ips and Not Assigned Status.
  Please note : If the machine is turned off then there is no Public IP assigned hence it will show Not Assigned.
  
.DESCRIPTION  
  This script takes a SubscriptionID and prints the VM list which have public IPs assigned at the current time.
  Please Install Az Module before running the script. Can be found here : https://docs.microsoft.com/en-us/powershell/azure/install-az-ps?view=azps-2.1.0 

.PARAMETER SubscriptionID
    The subscriptionID of the Azure Subscription that contains the resources you want to analyze

.EXAMPLE
   Please Install Az Module before running the script. Can be found here : https://docs.microsoft.com/en-us/powershell/azure/install-az-ps?view=azps-2.1.0 
  .\VirtualMachineIPs.ps1 -Subscription "XXXX-XXXX-XXXX-XXXX"

.NOTES
   AUTHOR: Rupanter Chhabra - Azure CXP
   LASTEDIT: May 24, 2019

.LINK
    This script posted to and discussed at the following locations:

#>
param(
    [Parameter(Mandatory = $True)]
    [string]$SubscriptionID
)
Connect-AzAccount
Set-AzContext -SubscriptionID $SubscriptionID
$ResourceGroupNames = ''
$VMlist = @()
$VMlistW = @()

Write-Host "Getting the details, please wait.." -ForegroundColor Yellow

$ResourceGroupNames = Get-AzResourceGroup
Foreach ($ResourceGroup in $ResourceGroupNames) {
    $VirtualMachines = @()
    $RGName = $ResourceGroup.ResourceGroupName
    $VirtualMachines += Get-AzVM -ResourceGroupName $RGName
    Foreach ($VirtualMachine in $VirtualMachines) {
        $VMhash = @{ }
        $publicIpAddress = ''
        $nic = ''
        $publicIpName = ''
        $publicIpAddress = ''
        $VMName = $VirtualMachine.Name
        $vm = Get-AzVm -ResourceGroupName $RGName -Name $VMName
        $nic = $vm.NetworkProfile.NetworkInterfaces[0].Id.Split('/') | select -Last 1
        if ($nic) {
            $IpConfig = Get-AzNetworkInterface -ResourceGroupName $RGName -Name $nic
            if ($IpConfig.IpConfigurations.PublicIpAddress) {
                $publicIpName = ($IpConfig).IpConfigurations.PublicIpAddress.Id.Split('/') | select -Last 1
            }
            else {
                $publicIpName = ''
            }
        }
        if ($publicIpName) {
            $publicIpAddress = (Get-AzPublicIpAddress -ResourceGroupName $RGName -Name $publicIpName).IpAddress
            $VMHash = New-Object PSObject -property @{VMname = $VMname; IpAddress = $PublicIpAddress; ResourceGroupName = $RGname }
        }
        if (('Not Assigned', '') -cnotcontains $publicIpAddress ) {
            $VMlist += $VMHash
        }
        else {
            $VMlistW += $VMhash
        }
    }
}

Write-Host "List of VMs with Public IPs:" -ForegroundColor Cyan
$VMlist

Write-Host "List of VMs without Public IPs or are turned off:" -ForegroundColor Cyan
$VMlistW