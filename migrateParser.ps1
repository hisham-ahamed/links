# Get-AzContext -ListAvailable
# Set the source workspace
Set-AzContext -Subscription "HMC-Hub"
$ResourceGroup = "rg-sec-hub-weu-001"
$WorkspaceName = "log-hub-weu-001"

# Only export saved queries from these categories
$Categories = ("CISCO")

$ExportedSearches = (Get-AzOperationalInsightsSavedSearch -ResourceGroupName $ResourceGroup -WorkspaceName $WorkspaceName).Value.Properties | Where-Object { $Categories -contains $_.Category }

# Set the destination workspace
Set-AzContext -Subscription "HMC-Hub-QC"
$ResourceGroup = "rg-sec-hub-qc-001"
$WorkspaceName = "log-hub-qc-001"

# Import Saved Searches
foreach ($search in $ExportedSearches) {
    $id = $search.Category + "|" + $search.DisplayName
    New-AzOperationalInsightsSavedSearch -Force -ResourceGroupName $ResourceGroup -WorkspaceName $WorkspaceName -SavedSearchId $id -DisplayName $search.DisplayName -Category $search.Category -Query $search.Query -Version $search.Version
}

