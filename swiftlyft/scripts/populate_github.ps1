# Requires: GitHub CLI (gh) v2.30+ with Projects (v2) support
# Usage:
#   $env:GH_TOKEN = "<your-token>"  # token must have repo and project access
#   ./scripts/populate_github.ps1 -Repo "IIEWFL/insy7315-final-project-submission-swiftlyft" -Org "IIEWFL" -ProjectName "SwiftLyft Tasks"

param(
  [Parameter(Mandatory = $true)] [string] $Repo,
  [Parameter(Mandatory = $false)] [string] $Org,
  [Parameter(Mandatory = $false)] [string] $ProjectName,
  [switch] $SkipProject
)

$ErrorActionPreference = 'Stop'

function Ensure-GhCliInstalled {
  if (Get-Command gh -ErrorAction SilentlyContinue) { return }
  Write-Host "GitHub CLI not found. Attempting install via winget..."
  try {
    winget install --id GitHub.cli -e --source winget --silent | Out-Null
  } catch {
    throw "GitHub CLI not installed and automatic install failed. Please install gh from https://cli.github.com and re-run."
  }
}

function Create-IssuesOnly {
  param([string] $Repo)
  $defs = New-IssueDefinitions
  foreach ($def in $defs) {
    gh issue create -R $Repo -t $def.Title -b $def.Body -l $def.Labels | Out-Null
    Write-Host ("Created: {0}" -f $def.Title)
  }
}

function Ensure-GhAuth {
  if (-not $env:GH_TOKEN) { throw "GH_TOKEN env var not set. Set your token: `$env:GH_TOKEN='***' and rerun." }
  $status = gh auth status 2>$null
  if ($LASTEXITCODE -ne 0) {
    Write-Host "Authenticating gh with provided token..."
    $env:GITHUB_TOKEN = $env:GH_TOKEN
    $env:GH_TOKEN = $env:GITHUB_TOKEN
    $env:GH_HOST = "github.com"
    # Non-interactive login
    $secure = ConvertTo-SecureString $env:GITHUB_TOKEN -AsPlainText -Force
    $tmp = New-TemporaryFile
    try {
      [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
      ) | Out-File -FilePath $tmp -Encoding ascii
      # PowerShell does not support input redirection with '<'; pipe token instead
      Get-Content -Raw $tmp | gh auth login --with-token | Out-Null
    } finally { Remove-Item $tmp -ErrorAction SilentlyContinue }
  }
}

function Ensure-Labels {
  param([string] $Repo)
  $labels = @(
    @{ name='bug'; color='d73a4a'; description='Something is not working' },
    @{ name='enhancement'; color='a2eeef'; description='New feature or request' },
    @{ name='documentation'; color='0075ca'; description='Improvements or additions to documentation' },
    @{ name='chore'; color='cfd3d7'; description='Maintenance or refactor tasks' },
    @{ name='ui'; color='fbca04'; description='User interface/UX' },
    @{ name='backend'; color='5319e7'; description='Server, API, DB' },
    @{ name='mobile'; color='0e8a16'; description='Flutter/Dart mobile app' },
    @{ name='performance'; color='ff7f50'; description='Performance improvements' },
    @{ name='security'; color='b60205'; description='Security related' },
    @{ name='tests'; color='1d76db'; description='Unit/Integration/E2E tests' },
    @{ name='a11y'; color='a295d6'; description='Accessibility' },
    @{ name='good first issue'; color='7057ff'; description='Good for newcomers' },
    @{ name='high priority'; color='b60205'; description='Urgent priority' },
    @{ name='medium priority'; color='fbca04'; description='Normal priority' },
    @{ name='low priority'; color='c2e0c6'; description='Low priority' }
  )

  foreach ($l in $labels) {
    try {
      gh api --silent -X POST "repos/$Repo/labels" -f name="$($l.name)" -f color="$($l.color)" -f description="$($l.description)" 2>$null
    } catch {
      # If label exists, update to ensure color/description are current
      gh api --silent -X PATCH "repos/$Repo/labels/$([uri]::EscapeDataString($l.name))" -f new_name="$($l.name)" -f color="$($l.color)" -f description="$($l.description)" 2>$null
    }
  }
}

function New-IssueDefinitions {
  # Returns an array of hashtables with Title, Body, Labels
  return @(
    @{ Title='Auth: Implement secure login flow'; Labels='mobile,backend,security,high priority'; Body='Implement and harden login: input validation, error UX, token storage, and API integration.' },
    @{ Title='Auth: Password reset screen + email flow'; Labels='mobile,backend'; Body='Add UI and API for password reset; handle success and failure states.' },
    @{ Title='Auth: Social login stubs (Google/Apple)'; Labels='mobile,enhancement'; Body='Create stubs and feature flags for social providers to be wired later.' },
    @{ Title='Onboarding: Welcome and permissions prompts'; Labels='mobile,ui'; Body='Guide users through location/notifications permissions with clear copy.' },
    @{ Title='Map: Show current location with accuracy ring'; Labels='mobile,ui'; Body='Render map with device location and accuracy visualization.' },
    @{ Title='Map: Pickup and dropoff pin interactions'; Labels='mobile,ui'; Body='Allow pin drag, address search, and confirmation sheet.' },
    @{ Title='Rides: Request ride API integration'; Labels='backend,mobile,high priority'; Body='POST ride requests; optimistic UI; handle network retries.' },
    @{ Title='Rides: Driver assignment polling + push'; Labels='backend,mobile,performance'; Body='Implement efficient polling then migrate to push notifications.' },
    @{ Title='Payments: Add Stripe test mode plumbing'; Labels='backend,security'; Body='Backend endpoints and client tokens for test transactions.' },
    @{ Title='Profile: Edit profile and avatar upload'; Labels='mobile,backend,enhancement'; Body='Screen for editing name, email; avatar upload with progress.' },
    @{ Title='Settings: Dark mode + theme system'; Labels='mobile,ui,enhancement'; Body='App-wide theming with dark/light and dynamic color.' },
    @{ Title='Localization: Scaffold i18n with EN base'; Labels='mobile,documentation'; Body='Set up localization pipeline and keys extraction.' },
    @{ Title='State: Standardize provider/bloc architecture'; Labels='mobile,chore'; Body='Adopt consistent state management and folder structure.' },
    @{ Title='Errors: Centralized error handling + toasts'; Labels='mobile,chore'; Body='Global handler for network and app errors with user-friendly messages.' },
    @{ Title='Logging: Add structured logs'; Labels='backend,chore'; Body='Adopt structured logging with correlation IDs.' },
    @{ Title='Analytics: Screen + ride events'; Labels='mobile,enhancement'; Body='Track key funnel events with privacy guardrails.' },
    @{ Title='CI: Set up GitHub Actions build for Flutter'; Labels='tests,chore'; Body='Build, test, and lint on PRs with caching.' },
    @{ Title='Testing: Unit tests for login + rides'; Labels='tests'; Body='Cover auth reducer/services and ride request logic.' },
    @{ Title='E2E: Golden tests for critical screens'; Labels='tests,mobile'; Body='Add golden tests for Login, Map, Ride Summary.' },
    @{ Title='Performance: Image and list virtualization'; Labels='performance,mobile'; Body='Ensure images cached; large lists recycled/virtualized.' },
    @{ Title='Performance: Startup time budget < 2s'; Labels='performance,mobile,high priority'; Body='Profile and reduce cold start time below target.' },
    @{ Title='Security: Secure storage for tokens'; Labels='security,mobile,high priority'; Body='Use platform secure storage; periodic token rotation.' },
    @{ Title='Security: Secrets scan and pre-commit hooks'; Labels='security,chore'; Body='Add secret scanning and pre-commit lint hooks.' },
    @{ Title='Accessibility: Contrast, labels, focus order'; Labels='a11y,ui'; Body='Fix contrast, ensure semantics, and correct focus traversal.' },
    @{ Title='UX: Empty states for rides and payments'; Labels='ui,enhancement'; Body='Design and implement friendly empty states.' },
    @{ Title='UX: Offline mode with limited actions'; Labels='enhancement,mobile'; Body='Detect offline; queue actions; message users.' },
    @{ Title='Networking: Retry/backoff wrapper'; Labels='backend,mobile,chore'; Body='Centralized retry with exponential backoff and circuit breaker.' },
    @{ Title='Data: Input validation and schema types'; Labels='backend,chore'; Body='Introduce schema validation (e.g., JSON schema) for APIs.' },
    @{ Title='Docs: Contributor guide and PR template'; Labels='documentation,chore,good first issue'; Body='Add CONTRIBUTING.md, PR template, coding standards.' },
    @{ Title='Linting: Apply strict analysis options'; Labels='chore,tests'; Body='Tighten lints and fix violations across modules.' },
    @{ Title='Crash reporting: Integrate Sentry/Crashlytics'; Labels='enhancement,security'; Body='Capture crashes with PII safeguards and release tags.' },
    @{ Title='Telemetry: Privacy review + data map'; Labels='documentation,security'; Body='Document collected events and retention with opt-out.' }
  )
}

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

function Add-Issues-And-PopulateProject {
  param([string] $Repo, [string] $Org, [string] $ProjectName)

  $meta = Get-ProjectMeta -Org $Org -ProjectName $ProjectName
  $projectId = $meta.ProjectId
  $statusFieldId = $meta.StatusFieldId
  $statusOptions = $meta.StatusOptions

  $statuses = @('Backlog','Ready','In progress','In review','Done')
  $defs = New-IssueDefinitions

  $i = 0
  foreach ($def in $defs) {
    $i++
    # Convert labels string to array for API
    $labelArray = $def.Labels -split ',' | ForEach-Object { $_.Trim() }
    
    # Try to find existing issue first
    $issueData = $null
    $allIssues = gh api "repos/$Repo/issues?state=all&per_page=100" --jq '.' | ConvertFrom-Json
    $existingIssue = $allIssues | Where-Object { $_.title -eq $def.Title } | Select-Object -First 1
    
    if ($existingIssue) {
      $issueData = $existingIssue
      Write-Host "Using existing issue #$($issueData.number): $($def.Title)" -ForegroundColor Yellow
    } else {
      # Create new issue using API with JSON body
      $tmpFile = New-TemporaryFile
      try {
        $issueJson = @{
          title = $def.Title
          body = $def.Body
          labels = $labelArray
        } | ConvertTo-Json -Compress
        $issueJson | Out-File -FilePath $tmpFile -Encoding utf8
        $issueData = gh api -X POST "repos/$Repo/issues" --input $tmpFile --jq '.' | ConvertFrom-Json
        Write-Host "Created issue #$($issueData.number): $($def.Title)" -ForegroundColor Green
      } catch {
        throw "Failed to create issue: $($def.Title). Error: $_"
      } finally {
        Remove-Item $tmpFile -ErrorAction SilentlyContinue
      }
    }
    
    if (-not $issueData -or -not $issueData.number) {
      throw "Failed to get issue data for: $($def.Title)"
    }

    # Get node_id if not already present
    if (-not $issueData.node_id) {
      $issueData = gh api "repos/$Repo/issues/$($issueData.number)" --jq '.' | ConvertFrom-Json
    }
    $issueNode = $issueData.node_id

    # Add to project via GraphQL
    $addQ = @'
mutation($project:ID!,$content:ID!){
  addProjectV2ItemById(input:{projectId:$project, contentId:$content}){ item { id } }
}
'@
    $itemId = gh api graphql -f query="$addQ" -F project=$projectId -F content=$issueNode --jq .data.addProjectV2ItemById.item.id | Out-String
    $itemId = $itemId.Trim()

    # Rotate status to populate columns
    $status = $statuses[($i - 1) % $statuses.Count]

    # Update item status field (map status label to option id)
    $optionId = $statusOptions[$status]
    if ($null -eq $optionId) { Write-Host "Warning: Status option '$status' not found; skipping field update." -ForegroundColor Yellow }
    else {
      $updQ = @'
mutation($project:ID!, $item:ID!, $field:ID!, $opt: String!){
  updateProjectV2ItemFieldValue(input:{projectId:$project, itemId:$item, fieldId:$field, value:{singleSelectOptionId:$opt}}){ clientMutationId }
}
'@
      gh api graphql -f query="$updQ" -F project=$projectId -F item=$itemId -F field=$statusFieldId -F opt=$optionId | Out-Null
    }

    Write-Host ("Created and added: {0} -> issue #{1} [{2}]" -f $def.Title, $issueNumber, $status)
  }
}

# Main
Ensure-GhCliInstalled
Ensure-GhAuth
Ensure-Labels -Repo $Repo
if ($SkipProject) {
  Write-Host "Skipping project population. Creating issues only..." -ForegroundColor Yellow
  Create-IssuesOnly -Repo $Repo
}
else {
  Add-Issues-And-PopulateProject -Repo $Repo -Org $Org -ProjectName $ProjectName
}

Write-Host "\nAll done: labels ensured, issues created, and project populated." -ForegroundColor Green


