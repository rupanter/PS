<#PSScriptInfo

.VERSION 1.0

.AUTHOR ruchh@microsoft.com

.COMPANYNAME Microsoft

.RELEASENOTES

<#  
.SYNOPSIS  
  This script takes a SubscriptionID and prints the VM list which have public IPs assigned at the current time.
  
.DESCRIPTION  
  This script takes a SubscriptionID and prints the VM list which have public IPs assigned at the current time.

.PARAMETER SubscriptionId
    The subscriptionID of the Azure Subscription that contains the resources you want to analyze

.EXAMPLE
  .\VMswithPublicIp.ps1 -Subscription "XXXX-XXXX-XXXX-XXXX"

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

$ResourceGroupNames = Get-AzResourceGroup
Foreach ($ResourceGroup in $ResourceGroupNames) {
    $VirtualMachines = @()
    $RGName = $ResourceGroup.ResourceGroupName
    $VirtualMachines += Get-AzVM -ResourceGroupName $RGName
    Foreach ($VirtualMachine in $VirtualMachines) {
        $VMhash = @{}
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
            $VMHash.add($Vmname, $PublicIpAddress)
        }
        if (('Not Assigned', '') -cnotcontains $publicIpAddress ) {
            $VMlist += $VMHash
        }
        else {
            $VMlistW += $VMhash
        }
    }
}

Write-Output "List of VMs with Public IPs"
$VMlist

Write-Output "List of VMs without Public IPs or are turned off"
$VMlistW