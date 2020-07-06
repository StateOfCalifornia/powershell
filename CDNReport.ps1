<#-------------------------------------------------------------------------#
   AUTHOR      : Sara Ahmad (CDT) |  sara.ahmad@state.ca.gov
   REVISED     : 2020 June 27
   TESTED      : 2020 June 27
-------------------------------------------------------------------------#
  NOTE: You may run into an error "You cannot run this script on the current
        system." See this link for more information:
        https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_execution_policies?view=powershell-6 S
#>


[CmdletBinding()]
param (
    $STORAGE_ACCOUNT_KEY,
    $STORAGE_ACCOUNT_NAME,
    $SUBSCRIPTION

)
Install-Module -Name Az.Cdn -force
Install-Module -Name Az.Storage -force -AllowClobber

$TotalCDNProfiles = Get-AzCdnProfile
$AzureResource = @()
foreach($CDNProfile in $TotalCDNProfiles)
{  
    Write-Host $CDNProfile.Name -foregroundcolor "yellow" 
    $CDNEndPoints = Get-AzCdnEndpoint -ProfileName $CDNProfile.Name -ResourceGroupName $CDNProfile.ResourceGroupName
foreach ($CDNEndPoint in $CDNEndPoints)
{
    Write-Host $CDNEndPoint.HostName -foregroundcolor "red"
    Write-Host $CDNEndPoint.ResourceState  -foregroundcolor "blue"
    $CustomDomain = Get-AzCdnCustomDomain -EndpointName $CDNEndPoint.Name -ProfileName $CDNProfile.Name -ResourceGroupName $CDNProfile.ResourceGroupName
    $CustomDomainName =  $CustomDomain.HostName  -join ";;"
    Write-Host $CustomDomain.HostName -foregroundcolor "DarkGray"
    $OutputItem = New-Object Object
    $OutputItem | Add-Member NoteProperty -Name  CDNProfileName  -Value  $CDNProfile.Name
    $OutputItem | Add-Member NoteProperty -Name  CDNEndPoint  -Value  $CDNEndPoint.HostName
    $OutputItem | Add-Member NoteProperty -Name  CustomDomain  -Value  $CustomDomainName
   # $OutputItem | Add-Member NoteProperty -Name  ResourceState  -Value  $CDNEndPoint.ResourceState 

    $AzureResource+=$OutputItem
}
}


$Header = @"
<style>
#CreationDate {
        font-family: Arial;
        color: black;
        font-size: 12px;
    }
    h1 {
        font-family: Arial;
        color: black;
        font-size: 28px;
        text-align: center;
    }
TABLE {border-width: 1px; border-style: solid; border-color: black; border-collapse: collapse; margin-left:auto;margin-right:auto}
TH {border-width: 1px; padding: 3px; border-style: solid; border-color: black; background-color: #6495ED;}
TD {border-width: 1px; padding: 3px; border-style: solid; border-color: black;}
</style>
"@

$Title = "<h1>CDN Supported Azure Sites</h1>"

$FileName = "AzureReportCDN.html"
$FileNamev1 = "AzureReportCDN.csv"

$AzureResource| Select * | Export-Csv -Path ".\$FileNamev1" -NoTypeInformation -Force

Import-Csv ".\$FileNamev1" | ConvertTo-Html -Body "$Title" -Head $Header  -PostContent "<p id='CreationDate'>Creation Date: $(Get-Date)</p>" | Out-File $FileName

$StorageContext = New-AzStorageContext -StorageAccountName $STORAGE_ACCOUNT_NAME -StorageAccountKey $STORAGE_ACCOUNT_KEY

#$Container = Get-AzureStorageContainer -Name 'bootdiagnostics-vmansible-9d853815-ac86-42c5-a6d4-b7f05810c59f' -Context $StorageContext
Set-AzStorageBlobContent -Container "powershellreports" -File ".\$FileName" -Properties @{"ContentType" = "text/html"} -Context $StorageContext -Force
Set-AzStorageBlobContent -Container "powershellreports" -File ".\$FileNamev1" -Context $StorageContext -Force
