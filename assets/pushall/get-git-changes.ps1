#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Comprehensive git changes analysis for workflow automation

.DESCRIPTION
    Captures complete git status, diff, and branch information for the pushall workflow.
    Saves structured data to JSON file and creates individual .diff files for each changed file
    in a dedicated analysis directory for easy parsing in subsequent workflow steps.

.PARAMETER OutputDir
    Directory to save the git changes output (default: .tmp/git-changes-analysis)
#>

param(
    [string]$OutputDir = ".tmp/git-changes-analysis"
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

# Remove old analysis directory if it exists
if (Test-Path $OutputDir) {
    Remove-Item $OutputDir -Recurse -Force
}

# Create fresh output directory
New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null

$OutputPath = Join-Path $OutputDir "git-changes-analysis.json"

try {
    Clear-Host

    Write-Host "Analyzing git changes..." -ForegroundColor Cyan
    
    # Get all git information in one batch
    $status = git status --porcelain 2>$null
    $diffStat = git --no-pager diff --stat 2>$null
    $diffNameOnly = git --no-pager diff --name-only 2>$null
    $currentBranch = git branch --show-current 2>$null
    $upstream = git rev-parse --abbrev-ref '@{upstream}' 2>$null
    $unpushedCommits = git log --oneline '@{upstream}..HEAD' 2>$null
    
    # Check for remote changes (fetch first, then compare)
    Write-Host "Checking for remote changes..." -ForegroundColor Yellow
    git fetch 2>$null
    $remoteCommits = git log --oneline 'HEAD..@{upstream}' 2>$null
    $hasRemoteChanges = -not [string]::IsNullOrWhiteSpace($remoteCommits)
    
    # Parse status into structured data first
    $statusLines = @($status | Where-Object { $_ })
    
    # Generate individual diff files for each changed file (staged and unstaged)
    $diffFiles = @()
    $unstagedChangedFiles = @($diffNameOnly | Where-Object { $_ })
    $stagedChangedFiles = @(git --no-pager diff --cached --name-only 2>$null | Where-Object { $_ })
    $allChangedFiles = @($unstagedChangedFiles + $stagedChangedFiles | Sort-Object -Unique)

    foreach ($file in $allChangedFiles) {
        $safeName = $file -replace '[\\/:*?"<>|]', '-'
        # Write unstaged diff if present
        $unstagedDiff = git --no-pager diff -- $file 2>$null
        if ($unstagedDiff) {
            $unstagedDiffFileName = "$safeName.unstaged.diff"
            $unstagedDiffFilePath = Join-Path $OutputDir $unstagedDiffFileName
            $unstagedDiff | Out-File -FilePath $unstagedDiffFilePath -Encoding UTF8
            $diffFiles += [PSCustomObject]@{
                originalFile = $file
                diffFile = $unstagedDiffFileName
                diffPath = $unstagedDiffFilePath
                staged = $false
            }
        }
        # Write staged diff if present
        $stagedDiff = git --no-pager diff --cached -- $file 2>$null
        if ($stagedDiff) {
            $stagedDiffFileName = "$safeName.staged.diff"
            $stagedDiffFilePath = Join-Path $OutputDir $stagedDiffFileName
            $stagedDiff | Out-File -FilePath $stagedDiffFilePath -Encoding UTF8
            $diffFiles += [PSCustomObject]@{
                originalFile = $file
                diffFile = $stagedDiffFileName
                diffPath = $stagedDiffFilePath
                staged = $true
            }
        }
    }
    
    # Parse individual file changes for better commit message crafting
    $fileChanges = @()
    foreach ($line in $statusLines) {
        if ($line -match '^(.)(.) (.+)$') {
            $indexStatus = $matches[1]
            $workTreeStatus = $matches[2]
            $fileName = $matches[3]
            
            $changeType = switch -Regex ("$indexStatus$workTreeStatus") {
                '^M.' { "Modified" }
                '^A.' { "Added" }
                '^D.' { "Deleted" }
                '^R.' { "Renamed" }
                '^C.' { "Copied" }
                '^.M' { "Modified (unstaged)" }
                '^.D' { "Deleted (unstaged)" }
                '^\?\?' { "Untracked" }
                default { "Changed" }
            }
            
            $fileChanges += [PSCustomObject]@{
                file = $fileName
                status = "$indexStatus$workTreeStatus"
                changeType = $changeType
                isStaged = $indexStatus -ne ' ' -and $indexStatus -ne '?'
            }
        }
    }
    $modifiedFiles = @($statusLines | Where-Object { $_ -match "^.M" })
    $untrackedFiles = @($statusLines | Where-Object { $_ -match "^\?\?" })
    $addedFiles = @($statusLines | Where-Object { $_ -match "^A" })
    $deletedFiles = @($statusLines | Where-Object { $_ -match "^.D" })
    $renamedFiles = @($statusLines | Where-Object { $_ -match "^R" })
    $stagedFiles = @($statusLines | Where-Object { $_ -match "^[AM]" })
    
    # Create comprehensive JSON structure
    $gitData = [PSCustomObject]@{
        timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
        branch = [PSCustomObject]@{
            current = $currentBranch
            upstream = if ($upstream) { $upstream } else { $null }
            hasUnpushedCommits = -not [string]::IsNullOrWhiteSpace($unpushedCommits)
            unpushedCommits = @($unpushedCommits | Where-Object { $_ })
            hasRemoteChanges = $hasRemoteChanges
            remoteCommits = @($remoteCommits | Where-Object { $_ })
        }
        status = [PSCustomObject]@{
            raw = $status
            summary = [PSCustomObject]@{
                totalFiles = $statusLines.Count
                modified = $modifiedFiles.Count
                untracked = $untrackedFiles.Count
                added = $addedFiles.Count
                deleted = $deletedFiles.Count
                renamed = $renamedFiles.Count
                staged = $stagedFiles.Count
                hasChanges = $statusLines.Count -gt 0
            }
            files = [PSCustomObject]@{
                modified = @($modifiedFiles | ForEach-Object { $_.Substring(3) })
                untracked = @($untrackedFiles | ForEach-Object { $_.Substring(3) })
                added = @($addedFiles | ForEach-Object { $_.Substring(3) })
                deleted = @($deletedFiles | ForEach-Object { $_.Substring(3) })
                renamed = @($renamedFiles | ForEach-Object { $_.Substring(3) })
                staged = @($stagedFiles | ForEach-Object { $_.Substring(3) })
            }
        }
        diff = [PSCustomObject]@{
            stats = $diffStat
            filesChanged = @($diffNameOnly | Where-Object { $_ })
            diffFiles = $diffFiles
            hasChanges = $allChangedFiles.Count -gt 0
        }
        changes = [PSCustomObject]@{
            fileDetails = $fileChanges
        }
    }
    
    # Analyze changes for commit message crafting
    $changesByType = @{}
    $changesByDirectory = @{}
    
    foreach ($change in $fileChanges) {
        # Group by change type
        if (-not $changesByType.ContainsKey($change.changeType)) {
            $changesByType[$change.changeType] = @()
        }
        $changesByType[$change.changeType] += $change.file
        
        # Group by directory
        $dir = Split-Path $change.file -Parent
        if ([string]::IsNullOrEmpty($dir)) { $dir = "root" }
        if (-not $changesByDirectory.ContainsKey($dir)) {
            $changesByDirectory[$dir] = @()
        }
        $changesByDirectory[$dir] += $change
    }
    
    # Convert to JSON and save (excluding problematic hashtables)
    $jsonOutput = $gitData | ConvertTo-Json -Depth 10 -Compress:$false
    $jsonOutput | Out-File -FilePath $OutputPath -Encoding UTF8
    
    Write-Host "✅ Git analysis saved to: $OutputPath" -ForegroundColor Green
    Write-Host "📊 Summary:" -ForegroundColor Yellow
    Write-Host "   • Branch: $($gitData.branch.current)" -ForegroundColor Cyan
    if ($gitData.branch.upstream) {
        Write-Host "   • Upstream: $($gitData.branch.upstream)" -ForegroundColor Cyan
    }
    Write-Host "   • Total files changed: $($gitData.status.summary.totalFiles)" -ForegroundColor Cyan
    Write-Host "   • Modified: $($gitData.status.summary.modified)" -ForegroundColor Cyan
    Write-Host "   • Untracked: $($gitData.status.summary.untracked)" -ForegroundColor Cyan
    Write-Host "   • Staged: $($gitData.status.summary.staged)" -ForegroundColor Cyan
    
    if ($gitData.branch.hasUnpushedCommits) {
        Write-Host "   • Unpushed commits: $($gitData.branch.unpushedCommits.Count)" -ForegroundColor Yellow
    }
    
    if ($gitData.branch.hasRemoteChanges) {
        Write-Host "   • Remote commits available: $($gitData.branch.remoteCommits.Count)" -ForegroundColor Yellow
    } else {
        Write-Host "   • No remote changes detected" -ForegroundColor Green
    }
    
    # Show change analysis for commit message crafting
    if ($gitData.changes.fileDetails.Count -gt 0) {
        Write-Host "🔍 Changes by type:" -ForegroundColor Yellow
        foreach ($type in $changesByType.Keys) {
            $count = $changesByType[$type].Count
            Write-Host "   • $type`: $count files" -ForegroundColor Cyan
        }
        
        Write-Host "📁 Changes by directory:" -ForegroundColor Yellow
        foreach ($dir in $changesByDirectory.Keys | Sort-Object) {
            $count = $changesByDirectory[$dir].Count
            Write-Host "   • $dir`: $count files" -ForegroundColor Cyan
        }
    }
    
    exit 0

} catch {
    Write-Host "❌ Error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
