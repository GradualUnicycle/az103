$vmName = 'az1000301-vm1'
$vmSize = 'Standard_DS2_v2'

$adminUsername = 'Student'
$adminPassword = 'Pa55w.rd1234'
$adminCreds = New-Object PSCredential $adminUsername, ($adminPassword | ConvertTo-SecureString -AsPlainText -Force)

$resourceGroup = Get-AzResourceGroup -Name 'az1000301-RG'
$location = $resourceGroup.Location

$AvailabilitySet = Get-AzAvailabilitySet -ResourceGroupName $resourceGroup.ResourceGroupName -Name 'az1000301-avset0'
$vNet = Get-azvirtualnetwork -Name az1000301-RG-vnet -ResourceGroupName $resourceGroup.ResourceGroupName
$SubnetId = (Get-AzVirtualNetworkSubnetConfig -Name 'subnet0' -VirtualNetwork $vNet).Id

$Nsg = New-AzNetworkSecurityGroup -ResourceGroupName $resourceGroup.ResourceGroupName -Location $location -Name "$vmName.nsg"
$PiP = New-AzPublicIpAddress -Name "$vmName-ip" -ResourceGroupName $resourceGroup.ResourceGroupName -Location $location -AllocationMethod Dynamic
$Nic = New-AzNetworkInterface -Name "$($vmName)$(Get-Random)" -ResourceGroupName $resourceGroup.ResourceGroupName -Location $location -SubnetId $SubnetId -PublicIpAddressId $PiP.Id -NetworkSecurityGroupId $nsg.Id

$osDiskType = (Get-AzDisk -ResourceGroupName $resourceGroup.ResourceGroupName)[0].Sku.Name

$publisherName = 'MicrosoftWindowsServer'
$offerName = 'WindowsServer'
$skuName = '2016-Datacenter'

$VMConfigParam = @{
    VMName            = $vmName
    VMSize            = $vmSize
    AvailabilitySetId = $availabilitySet.Id
}
$VMConfig = New-AzVMConfig @VMConfigParam
Add-AzVMNetworkInterface -vm $VMConfig -Id $nic.Id
Set-AzVMOperatingSystem -vm $VMConfig -Windows -ComputerName $vmName -Credential $adminCreds

$VMSourceparams = @{
    VM            = $VMConfig
    PublisherName = $publisherName
    Offer         = $offerName
    Skus          = $skuName
    Version       = 'latest'
}
Set-AzVMSourceImage @VMSourceparams

$VMOsDiskParams = @{
    VM = $VMConfig
    Name = "$($vmName)_OsDisk_1_$(Get-Random)"
    StorageAccountType = $OsDiskType 
    CreateOption = 'FromImage'

}
Set-AzVMOSDisk @VMOsDiskParams

Set-AzVMBootDiagnostic -VM $vmConfig -Disable

New-AzVM -ResourceGroupName $resourceGroup.ResourceGroupName -Location $location -VM $vmConfig

