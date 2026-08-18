# Helper script to set up each sprint for screenshot
# This will guide you through setting up and taking screenshots for all 4 sprints

param(
  [Parameter(Mandatory = $false)] [int] $SprintNumber = 0
)

$Repo = "IIEWFL/insy7315-final-project-submission-swiftlyft"
$Org = "IIEWFL"
$ProjectName = "SwiftLyft Tasks"

Write-Host @"

╔════════════════════════════════════════════════════════════════╗
║  Sprint Screenshot Setup for GitHub Project Board            ║
╚════════════════════════════════════════════════════════════════╝

"@ -ForegroundColor Cyan

if ($SprintNumber -eq 0) {
  Write-Host "Available options:" -ForegroundColor Yellow
  Write-Host "  1. Sprint 1 - Initial state (15 Backlog, 10 Ready, 5 In Progress, 2 In Review, 0 Done)"
  Write-Host "  2. Sprint 2 - Early progress (8 Backlog, 7 Ready, 8 In Progress, 5 In Review, 4 Done)"
  Write-Host "  3. Sprint 3 - Mid progress (5 Backlog, 4 Ready, 6 In Progress, 8 In Review, 9 Done)"
  Write-Host "  4. Sprint 4 - Nearly complete (2 Backlog, 2 Ready, 3 In Progress, 5 In Review, 20 Done)"
  Write-Host ""
  Write-Host "To set up a sprint, run:" -ForegroundColor Green
  Write-Host "  ./scripts/setup_sprint_for_screenshot.ps1 -SprintNumber 1" -ForegroundColor White
  Write-Host ""
  Write-Host "Or use the simulate_sprints script directly:" -ForegroundColor Green
  Write-Host "  ./scripts/simulate_sprints.ps1 -Repo `"$Repo`" -Org `"$Org`" -ProjectName `"$ProjectName`" -SprintNumber 1" -ForegroundColor White
  exit 0
}

Write-Host "Setting up Sprint $SprintNumber..." -ForegroundColor Cyan
Write-Host ""

# Run the simulate sprints script
& ./scripts/simulate_sprints.ps1 -Repo $Repo -Org $Org -ProjectName $ProjectName -SprintNumber $SprintNumber

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║  ✓ Sprint $SprintNumber is ready!                              ║" -ForegroundColor Green
Write-Host "║                                                                ║" -ForegroundColor Green
Write-Host "║  📸 Take a screenshot of your board now:                       ║" -ForegroundColor Green
Write-Host "║     https://github.com/orgs/$Org/projects/19                    ║" -ForegroundColor White
Write-Host "║                                                                ║" -ForegroundColor Green
Write-Host "║  Then run this script again with the next sprint number.      ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""


