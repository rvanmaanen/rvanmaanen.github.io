#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Comprehensive git changes analysis for workflow automation

.DESCRIPTION
    Captures complete git status, diff, and branch information for the pushall workflow.
    Saves structured data to JSON file and creates unified .diff files showing what the 
    final commit would look like if all current changes (staged, unstaged, and untracked) 
    were staged and committed together. Uses git's simulation capabilities for accurate 
    "what-if" analysis.

.PARAMETER OutputDir
    Directory to save the git changes output (default: .tmp/git-changes-analysis)
#>

param(
    [string]$OutputDir = ".tmp/git-changes-analysis"
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

# Suppress progress bars for cleaner output
$ProgressPreference = 'SilentlyContinue'

# Remove old analysis directory if it exists
if (Test-Path $OutputDir) {
    Write-Host "Removing old output before continuing..."
    Remove-Item $OutputDir -Recurse -Force | Out-Null
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
    
    # Parse git status output
    $statusLines = git status --porcelain
    $summary = @{
        totalFiles = 0
        new = 0
        modified = 0
        deleted = 0
        renamed = 0
        hasChanges = $false
    }
    
    $files = @{
        new = @()
        modified = @()
        deleted = @()
        renamed = @()
    }
    
    $fileDetails = @()
    $allChangedFiles = @()
    
    foreach ($line in $statusLines) {
        if ($line.Length -ge 3) {
            $status = $line.Substring(0, 2)
            $file = $line.Substring(3)
            
            $summary.totalFiles++
            $summary.hasChanges = $true
            
            # Determine final change type (what will happen when committed/pushed)
            $changeType = "Modified" # default
            
            switch -Regex ($status) {
                '^\?\?' { 
                    $changeType = "New"
                    $summary.new++
                    $files.new += $file
                }
                '^A.' { 
                    $changeType = "New"
                    $summary.new++
                    $files.new += $file
                }
                '^.A' { 
                    $changeType = "New"
                    $summary.new++
                    $files.new += $file
                }
                '^D.' { 
                    $changeType = "Deleted"
                    $summary.deleted++
                    $files.deleted += $file
                }
                '^.D' { 
                    $changeType = "Deleted"
                    $summary.deleted++
                    $files.deleted += $file
                }
                '^R.' { 
                    $changeType = "Renamed"
                    $summary.renamed++
                    $files.renamed += $file
                }
                default { 
                    $changeType = "Modified"
                    $summary.modified++
                    $files.modified += $file
                }
            }
            
            $fileDetails += @{
                file = $file
                status = $status
                changeType = $changeType
            }
            
            $allChangedFiles += $file
        }
    }

    # Generate diff files for each changed file
    $diffFiles = @()
    
    foreach ($file in $allChangedFiles) {
        # Create safe filename for diff
        $safeFileName = $file -replace '[/\\:*?"<>|]', '-'
        $diffFileName = "$safeFileName.diff"
        $diffPath = Join-Path $outputDir $diffFileName
        
        try {
            # Check if file is tracked or untracked
            $isTracked = $true
            try {
                git ls-files --error-unmatch $file 2>$null | Out-Null
            } catch {
                $isTracked = $false
            }
            
            if ($isTracked) {
                # For tracked files, use git diff HEAD
                $diffContent = git diff HEAD -- $file
            } else {
                # For untracked files, show as new file
                try {
                    $diffContent = git diff --no-index /dev/null $file 2>$null
                } catch {
                    # Fallback: create manual diff for untracked file
                    $fileContent = Get-Content $file -Raw -ErrorAction SilentlyContinue
                    $diffContent = "@@ -0,0 +1,$((($fileContent -split "`n").Length)) @@`n"
                    $diffContent += ($fileContent -split "`n" | ForEach-Object { "+$_" }) -join "`n"
                }
            }
            
            if ($diffContent) {
                $diffContent | Out-File -FilePath $diffPath -Encoding utf8
                $diffFiles += @{
                    originalFile = $file
                    diffFile = $diffFileName
                    diffPath = $diffPath
                }
            }
        } catch {
            Write-Warning "Failed to generate diff for $file`: $($_.Exception.Message)"
        }
    }
    
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
        summary = [PSCustomObject]@{
            totalFiles = $summary.totalFiles
            new = $summary.new
            modified = $summary.modified
            deleted = $summary.deleted
            renamed = $summary.renamed
            hasChanges = $summary.hasChanges
        }
        files = [PSCustomObject]@{
            new = $files.new
            modified = $files.modified
            deleted = $files.deleted
            renamed = $files.renamed
        }
        diff = [PSCustomObject]@{
            stats = $diffStat
            filesChanged = $allChangedFiles
            diffFiles = $diffFiles
            hasChanges = $allChangedFiles.Count -gt 0
        }
        changes = [PSCustomObject]@{
            fileDetails = $fileDetails
        }
    }
    
    # Analyze changes for commit message crafting
    $changesByType = @{}
    $changesByDirectory = @{}
    
    # Process each file change exactly once
    foreach ($change in $fileDetails) {
        $type = $change.changeType
        
        # Initialize array if needed
        if (-not $changesByType.ContainsKey($type)) {
            $changesByType[$type] = @()
        }
        
        # Add file to this change type
        $changesByType[$type] += $change.file
        
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
    Write-Host "   • Total files changed: $($gitData.summary.totalFiles)" -ForegroundColor Cyan
    Write-Host "   • New: $($gitData.summary.new)" -ForegroundColor Cyan
    Write-Host "   • Modified: $($gitData.summary.modified)" -ForegroundColor Cyan
    Write-Host "   • Deleted: $($gitData.summary.deleted)" -ForegroundColor Cyan
    Write-Host "   • Renamed: $($gitData.summary.renamed)" -ForegroundColor Cyan
    
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
        foreach ($type in ($changesByType.Keys | Sort-Object)) {
            $count = $changesByType[$type].Count
            Write-Host "   • $type`: $count file$(if ($count -ne 1) { 's' })" -ForegroundColor Cyan
        }
        
        Write-Host "📁 Changes by directory:" -ForegroundColor Yellow
        foreach ($dir in ($changesByDirectory.Keys | Sort-Object)) {
            $count = $changesByDirectory[$dir].Count
            Write-Host "   • $dir`: $count file$(if ($count -ne 1) { 's' })" -ForegroundColor Cyan
        }
    }
    
    exit 0

} catch {
    Write-Host "❌ Error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
