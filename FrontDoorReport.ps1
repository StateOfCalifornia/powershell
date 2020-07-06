<#-------------------------------------------------------------------------#

   AUTHOR      : Sara Ahmad (CDT) |  sara.ahmad@state.ca.gov
   REVISED     : 2020 June 27
   TESTED      : 2020 June 27
-------------------------------------------------------------------------#


  NOTE: You may run into an error "You cannot run this script on the current
        system." See this link for more information:
        https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_execution_policies?view=powershell-6

#>

[CmdletBinding()]
param (
    $STORAGE_ACCOUNT_KEY,
    $STORAGE_ACCOUNT_NAME,
    $SUBSCRIPTION
)

Install-Module -Name Az.FrontDoor -force
Install-Module -Name Az.Storage -force -AllowClobber

$GetResourcesFD = Get-AzFrontDoor
$TotalCount = $GetResourcesFD.Name
$AzureResource = @()
$RCount=0;
foreach($count in $TotalCount)
{
$ResourceGroupNamev1 = $GetResourcesFD.Id
$ResourceGroupNamev2 = $ResourceGroupNamev1[$RCount].Split("/")
$contextFD = Get-AzFrontDoorFrontendEndpoint -ResourceGroupName $ResourceGroupNamev2[4] -FrontDoorName $count
$contextFDHostNames = $contextFD.HostName


foreach ($contextFDHostName in $contextFDHostNames)
{   
    $OutputItem = New-Object Object
    $OutputItem | Add-Member NoteProperty -Name  Subscription  -Value  $SUBSCRIPTION
    $OutputItem | Add-Member NoteProperty -Name  ResourceGroup  -Value  $ResourceGroupNamev2[4]
    $OutputItem | Add-Member NoteProperty -Name  FrontDoorName  -Value  $count
    $OutputItem | Add-Member HostNames   $contextFDHostName

    $AzureResource+=$OutputItem
    Write-Host $contextFDHostName
}
$RCount++;
}

$Header = @"
<style>
TABLE {border-width: 1px; border-style: solid; border-color: black; border-collapse: collapse; margin-left:auto;margin-right:auto}
TH {border-width: 1px; padding: 3px; border-style: solid; border-color: black; background-color: #6495ED;}
TD {border-width: 1px; padding: 3px; border-style: solid; border-color: black;}
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

</style>
"@

#The command below will get the title
$Title = "<h1>Azure Sites</h1>"

$FileName = "AzureReport.html"
$FileNamev1 = "AzureReportFD.csv"
$FileNamev2 = "AzureReportFD.xlsx"

$AzureResource| Select * | Export-Csv -Path ".\$FileNamev1" -NoTypeInformation -Force
<#
$csv = ".\$FileNamev1" #Location of the source file
$xlsx = ".\$FileNamev2" #Desired location of output
$delimiter = "," #Specify the delimiter used in the file

# Create a new Excel workbook with one empty sheet
$excel = New-Object -ComObject excel.application 
$workbook = $excel.Workbooks.Add(1)
$worksheet = $workbook.worksheets.Item(1)

# Build the QueryTables.Add command and reformat the data
$TxtConnector = ("TEXT;" + $csv)
$Connector = $worksheet.QueryTables.add($TxtConnector,$worksheet.Range("A1"))
$query = $worksheet.QueryTables.item($Connector.name)
$query.TextFileOtherDelimiter = $delimiter
$query.TextFileParseType  = 1
$query.TextFileColumnDataTypes = ,1 * $worksheet.Cells.Columns.Count
$query.AdjustColumnWidth = 1

# Execute & delete the import query
$query.Refresh()
$query.Delete()

# Save & close the Workbook as XLSX.
$Workbook.SaveAs($xlsx,51)
$excel.Quit()
#>

Import-Csv ".\$FileNamev1" | ConvertTo-Html -Body "$Title" -Head $Header  -PostContent "<p id='CreationDate'>Creation Date: $(Get-Date)</p>" | Out-File $FileName

$StorageContext = New-AzStorageContext -StorageAccountName $STORAGE_ACCOUNT_NAME -StorageAccountKey $STORAGE_ACCOUNT_KEY

#$Container = Get-AzureStorageContainer -Name 'bootdiagnostics-vmansible-9d853815-ac86-42c5-a6d4-b7f05810c59f' -Context $StorageContext
Set-AzStorageBlobContent -Container "powershellreports" -File ".\$FileName" -Properties @{"ContentType" = "text/html"} -Context $StorageContext -Force
Set-AzStorageBlobContent -Container "powershellreports" -File ".\$FileNamev1" -Context $StorageContext -Force

