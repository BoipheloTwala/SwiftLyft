# Script to simulate 4 sprints by moving issues through project board columns
# Usage: ./scripts/simulate_sprints.ps1 -Repo "IIEWFL/insy7315-final-project-submission-swiftlyft" -Org "IIEWFL" -ProjectName "SwiftLyft Tasks" -SprintNumber 1-4

param(
  [Parameter(Mandatory = $true)] [string] $Repo,
  [Parameter(Mandatory = $true)] [string] $Org,
  [Parameter(Mandatory = $true)] [string] $ProjectName,
  [Parameter(Mandatory = $true)] [ValidateRange(1,4)] [int] $SprintNumber
)

$ErrorActionPreference = 'Stop'

function Get-ProjectMeta {
  param([string] $Org, [string] $ProjectName)

  $q = @'
query($org:String!,$title:String!){
  organization(login:$org){
    projectsV2(first:100, query:$title){ nodes { id title } }
  }
}
'@
  $resp = gh api graphql -F org=$Org -F title=$ProjectName -f query="$q" | ConvertFrom-Json
  $projects = $resp.data.organization.projectsV2.nodes
  $project = $projects | Where-Object { $_.title -eq $ProjectName } | Select-Object -First 1
  if (-not $project) { throw "Project '$ProjectName' not found under owner '$Org'." }

  $projectId = $project.id

  $q2 = @'
query($id:ID!){
  node(id:$id){
    ... on ProjectV2{
      fields(first:50){
        nodes{
          ... on ProjectV2Field{
            id
            name
          }
          ... on ProjectV2SingleSelectField{
            id
            name
            options{
              id
              name
            }
          }
        }
      }
    }
  }
}
'@
  $resp2 = gh api graphql -F id=$projectId -f query="$q2" | ConvertFrom-Json
  $fields = $resp2.data.node.fields.nodes
  $statusField = $fields | Where-Object { $_.name -eq 'Status' } | Select-Object -First 1
  if (-not $statusField) { throw "Status field not found on project '$ProjectName'." }

  $statusOptions = @{}
  if ($statusField.options) {
    foreach ($opt in $statusField.options) { $statusOptions[$opt.name] = $opt.id }
  }

  return @{ ProjectId = $projectId; StatusFieldId = $statusField.id; StatusOptions = $statusOptions }
}

function Get-ProjectItems {
  param([string] $Org, [string] $ProjectName, [string] $ProjectId)

  $q = @'
query($id:ID!){
  node(id:$id){
    ... on ProjectV2{
      items(first:100){
        nodes{
          id
          fieldValues(first:20){
            nodes{
              ... on ProjectV2ItemFieldSingleSelectValue{
                field{
                  ... on ProjectV2Field{
                    id
                    name
                  }
                }
                name
              }
            }
          }
          content{
            ... on Issue{
              id
              number
              title
              url
            }
          }
        }
      }
    }
  }
}
'@
  $resp = gh api graphql -F id=$ProjectId -f query="$q" | ConvertFrom-Json
  return $resp.data.node.items.nodes
}

function Update-ItemStatus {
  param([string] $ProjectId, [string] $ItemId, [string] $StatusFieldId, [string] $OptionId)
  
  $updQ = @'
mutation($project:ID!, $item:ID!, $field:ID!, $opt: String!){
  updateProjectV2ItemFieldValue(input:{projectId:$project, itemId:$item, fieldId:$field, value:{singleSelectOptionId:$opt}}){ clientMutationId }
}
'@
  gh api graphql -f query="$updQ" -F project=$ProjectId -F item=$ItemId -F field=$StatusFieldId -F opt=$OptionId | Out-Null
}

function Set-SprintState {
  param(
    [string] $ProjectId,
    [string] $StatusFieldId,
    [hashtable] $StatusOptions,
    [array] $Items,
    [int] $SprintNumber
  )

  Write-Host "`n=== Setting up Sprint $SprintNumber ===" -ForegroundColor Cyan

  # Define sprint distributions
  $sprintDistributions = @{
    1 = @{ Backlog = 15; Ready = 10; 'In progress' = 5; 'In review' = 2; Done = 0 }
    2 = @{ Backlog = 8; Ready = 7; 'In progress' = 8; 'In review' = 5; Done = 4 }
    3 = @{ Backlog = 5; Ready = 4; 'In progress' = 6; 'In review' = 8; Done = 9 }
    4 = @{ Backlog = 2; Ready = 2; 'In progress' = 3; 'In review' = 5; Done = 20 }
  }

  $target = $sprintDistributions[$SprintNumber]
  
  # Shuffle items randomly for distribution
  $shuffled = $Items | Get-Random -Count $Items.Count
  
  $statusCounts = @{ 
    'Backlog' = 0
    'Ready' = 0
    'In progress' = 0
    'In review' = 0
    'Done' = 0
  }
  
  # Build distribution list
  $distribution = @()
  foreach ($status in @('Backlog', 'Ready', 'In progress', 'In review', 'Done')) {
    for ($i = 0; $i -lt $target[$status]; $i++) {
      $distribution += $status
    }
  }
  
  # Shuffle the distribution
  $distribution = $distribution | Get-Random -Count $distribution.Count
  
  $index = 0
  foreach ($item in $shuffled) {
    # Determine target status based on distribution
    if ($index -lt $distribution.Count) {
      $targetStatus = $distribution[$index]
    } else {
      # If we have more items than planned, put extras in Done
      $targetStatus = 'Done'
    }
    
    $statusCounts[$targetStatus]++
    
    # Get current status from field values
    $currentStatus = $null
    foreach ($fieldValue in $item.fieldValues.nodes) {
      if ($fieldValue.field.id -eq $StatusFieldId) {
        $currentStatus = $fieldValue.name
        break
      }
    }
    
    # Update if different
    if ($currentStatus -ne $targetStatus) {
      $optionId = $StatusOptions[$targetStatus]
      if ($optionId) {
        Update-ItemStatus -ProjectId $ProjectId -ItemId $item.id -StatusFieldId $StatusFieldId -OptionId $optionId
        $issueTitle = if ($item.content) { $item.content.title } else { "Unknown" }
        Write-Host "  Moved: $issueTitle -> $targetStatus" -ForegroundColor Gray
      } else {
        Write-Host "  Warning: Status option '$targetStatus' not found for: $($item.content.title)" -ForegroundColor Yellow
      }
    }
    
    $index++
  }
  
  Write-Host "`nSprint $SprintNumber distribution:" -ForegroundColor Green
  foreach ($status in $target.Keys) {
    Write-Host "  $status : $($statusCounts[$status])" -ForegroundColor Yellow
  }
  Write-Host "`n✓ Sprint $SprintNumber ready! Take a screenshot now.`n" -ForegroundColor Green
}

# Main
$meta = Get-ProjectMeta -Org $Org -ProjectName $ProjectName
$items = Get-ProjectItems -Org $Org -ProjectName $ProjectName -ProjectId $meta.ProjectId

Set-SprintState -ProjectId $meta.ProjectId -StatusFieldId $meta.StatusFieldId -StatusOptions $meta.StatusOptions -Items $items -SprintNumber $SprintNumber

Write-Host "All done! Your board is now configured for Sprint $SprintNumber." -ForegroundColor Cyan
