# PowerShell migration script that handles OneDrive locks

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "LAB MIGRATION TO PILLAR DIRECTORIES" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Load mapping
$mappingFile = ".migration\lab-mapping.json"
$mappings = Get-Content $mappingFile | ConvertFrom-Json

$successful = 0
$failed = 0
$skipped = 0

foreach ($mapping in $mappings) {
    $labName = $mapping.lab_name
    $originalPath = $mapping.original_path
    $pillar = $mapping.primary_pillar
    
    $source = $originalPath -replace '\\', '/'
    $destination = "$pillar/$labName"
    
    if (-not (Test-Path $source)) {
        Write-Host "⊘ Skip: $labName (source not found)" -ForegroundColor Yellow
        $skipped++
        continue
    }
    
    if (Test-Path $destination) {
        Write-Host "⊘ Skip: $labName (already exists)" -ForegroundColor Yellow
        $skipped++
        continue
    }
    
    try {
        # Use git mv
        $result = git mv $source $destination 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ Moved: $labName → $pillar/" -ForegroundColor Green
            $successful++
        } else {
            Write-Host "✗ Failed: $labName - $result" -ForegroundColor Red
            $failed++
        }
    } catch {
        Write-Host "✗ Error: $labName - $_" -ForegroundColor Red
        $failed++
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "MIGRATION COMPLETE" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Successful: $successful" -ForegroundColor Green
Write-Host "Failed: $failed" -ForegroundColor Red
Write-Host "Skipped: $skipped" -ForegroundColor Yellow
Write-Host ""
Write-Host "Next steps:"
Write-Host "1. Run: git status"
Write-Host "2. Commit: git commit -m 'Reorganize portfolio by AWS Well-Architected pillars'"
