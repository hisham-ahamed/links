# Set the source workspace
Set-AzContext -Subscription "HMC-Hub"
$SourceResourceGroup = "rg-sec-hub-weu-001"
$SourceWorkspaceName = "log-hub-weu-001"

# Only export saved queries from these categories
$Categories = ("CISCO")

$ExportedSearches = (Get-AzOperationalInsightsSavedSearch -ResourceGroupName $SourceResourceGroup -WorkspaceName $SourceWorkspaceName).Value.Properties | Where-Object { $Categories -contains $_.Category }

# Set the destination workspace
Set-AzContext -Subscription "HMC-Hub-QC"
$DestResourceGroup = "rg-sec-hub-qc-001"
$DestWorkspaceName = "log-hub-qc-001"

# Import Saved Searches as Functions
foreach ($search in $ExportedSearches) {
    # Create a function in the destination workspace
    $functionName = $search.DisplayName
    $functionQuery = $search.Query
    $function = @{
        "Content" = $functionQuery
    }
    $functionId = (New-AzResource -ResourceType Microsoft.OperationalInsights/workspaces/functions `
                                    -ResourceGroupName $DestResourceGroup `
                                    -WorkspaceName $DestWorkspaceName `
                                    -Name $functionName `
                                    -Properties $function).Properties.id
    
    # Assign the query to the function
    $savedSearch = @{
        "Properties" = @{
            "Category" = "Custom"
            "Query" = $functionId
        }
    }
    $savedSearchId = $search.Category + "|" + $search.DisplayName
    New-AzResource -ResourceType Microsoft.OperationalInsights/workspaces/savedSearches `
                   -ResourceGroupName $DestResourceGroup `
                   -WorkspaceName $DestWorkspaceName `
                   -Name $savedSearchId `
                   -Properties $savedSearch
}
