#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Comprehensive git changes analysis for workflow automation

.DESCRIPTION
    Analyzes local git working directory and staging area changes, as well as performs
    network operations to check remote branch status, fetch remote origin URLs, and compare
    local vs remote SHA hashes. Saves structured data to JSON file and creates individual
    .diff files for each changed file.

.PARAMETER OutputDir
    Directory to save the git changes output (default: .tmp/git-changes-analysis)

.PARAMETER CompareRemoteWithMain
    Switch to compare current remote branch with main branch instead of analyzing local changes.
    When enabled, analyzes changes between the current remote branch and remote main branch.

.PARAMETER CompareLocalWithMain
    Switch to compare local uncommitted changes against main branch instead of just remote branches.
    This is useful for scenarios where you want to analyze uncommitted changes in the context of main branch differences.
    Cannot be used together with CompareRemoteWithMain.
#>

param(
    [string]$OutputDir = ".tmp/git-changes-analysis",
    [switch]$CompareRemoteWithMain,
    [switch]$CompareLocalWithMain
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

# Validate parameter combinations
if ($CompareRemoteWithMain -and $CompareLocalWithMain) {
    throw "CompareRemoteWithMain and CompareLocalWithMain cannot be used together. Choose one comparison mode."
}

# Suppress progress bars for cleaner output
$ProgressPreference = 'SilentlyContinue'

try {
    Write-Host "Analyzing git changes..." -ForegroundColor Cyan
    
    # Remove old analysis directory if it exists
    if (Test-Path $OutputDir) {
        Remove-Item $OutputDir -Recurse -Force | Out-Null
    }
    
    # Create fresh output directory
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
    $OutputPath = Join-Path $OutputDir "git-changes-analysis.json"
    
    # Get current branch
    $currentBranch = git branch --show-current 2>$null
    if (-not $currentBranch) {
        throw "Not in a git repository or unable to determine current branch"
    }
    
    # Check remote branch status using git ls-remote (minimal network operation)
    $remoteBranch = @{
        exists     = $false
        hasUpdates = $false
        localSha   = $null
        remoteSha  = $null
        origin     = $null
        branchName = $currentBranch
    }
    
    $remoteMain = @{
        exists     = $true  # main always exists in remote for this repo
        hasUpdates = $false
        localSha   = $null
        remoteSha  = $null
        origin     = $null
        branchName = "main"
    }
    
    try {
        # Get the remote origin URL
        $remoteOrigin = git remote get-url origin 2>$null
        if ($remoteOrigin) {
            $remoteBranch.origin = $remoteOrigin
            $remoteMain.origin = $remoteOrigin
            
            # Get local commit SHA for current branch
            $localSha = git rev-parse HEAD 2>$null
            if ($localSha) {
                $remoteBranch.localSha = $localSha
                
                # Check remote branch using ls-remote (doesn't pull anything)
                $lsRemoteOutput = git ls-remote origin "refs/heads/$currentBranch" 2>$null
                if ($lsRemoteOutput -and $lsRemoteOutput.Trim()) {
                    # Remote branch exists
                    $remoteBranch.exists = $true
                    $remoteSha = ($lsRemoteOutput -split '\s+')[0]
                    $remoteBranch.remoteSha = $remoteSha
                    
                    # Check if remote has different commits (updates we don't have)
                    if ($remoteSha -ne $localSha) {
                        $remoteBranch.hasUpdates = $true
                    }
                }
                
                # Check remote main branch status (without fetching)
                $lsRemoteMainOutput = git ls-remote origin "refs/heads/main" 2>$null
                if ($lsRemoteMainOutput -and $lsRemoteMainOutput.Trim()) {
                    $remoteMainSha = ($lsRemoteMainOutput -split '\s+')[0]
                    $remoteMain.remoteSha = $remoteMainSha
                    
                    # Get our local main branch SHA (merge-base with main)
                    $localMainSha = git rev-parse main 2>$null
                    if ($localMainSha) {
                        $remoteMain.localSha = $localMainSha
                        
                        # Check if remote main has moved ahead of our local main
                        if ($remoteMainSha -ne $localMainSha) {
                            $remoteMain.hasUpdates = $true
                        }
                    }
                    else {
                        # If we don't have main locally, we definitely need to sync
                        $remoteMain.hasUpdates = $true
                    }
                }
            }
        }
    }
    catch {
        Write-Warning "Could not check remote branch status: $($_.Exception.Message)"
    }
    
    # Determine analysis mode
    if ($CompareRemoteWithMain) {
        Write-Host "🌐 Comparing current remote branch with main..." -ForegroundColor Magenta
        
        # For main comparison, we need to compare current remote branch vs remote main
        if (-not $remoteBranch.exists) {
            Write-Host "⚠️  Current branch has no remote - cannot compare with main" -ForegroundColor Yellow
            $statusLines = @()  # No changes to analyze
        }
        elseif ($currentBranch -eq "main") {
            Write-Host "ℹ️  Currently on main branch - no comparison needed" -ForegroundColor Blue
            $statusLines = @()  # No changes to analyze
        }
        else {
            # Get diff between current remote branch and remote main
            Write-Host "📊 Fetching changes between current remote branch and main..." -ForegroundColor Cyan
            
            # We need to fetch to get the remote refs for comparison
            try {
                git fetch origin $currentBranch --quiet 2>$null
                git fetch origin main --quiet 2>$null
                $currentRemoteRef = "origin/$currentBranch"
                $mainRemoteRef = "origin/main"
                
                # Get list of changed files between remote branch and remote main
                $branchToMainChanges = git diff --name-status $mainRemoteRef $currentRemoteRef 2>$null
                $statusLines = $branchToMainChanges
            }
            catch {
                Write-Warning "Could not fetch remote branches for comparison: $($_.Exception.Message)"
                $statusLines = @()
            }
        }
    }
    elseif ($CompareLocalWithMain) {
        Write-Host "🔍 Comparing local uncommitted changes against main branch..." -ForegroundColor Magenta
        
        if ($currentBranch -eq "main") {
            Write-Host "ℹ️  Currently on main branch - analyzing uncommitted changes only" -ForegroundColor Blue
            # For main branch, just analyze local uncommitted changes
            $statusLines = git status --porcelain 2>$null
        }
        else {
            Write-Host "📊 Analyzing uncommitted changes in context of main branch differences..." -ForegroundColor Cyan
            
            # Get diff between current local branch and main, including uncommitted changes
            try {
                # First get changes between current branch and main (committed changes)
                $branchToMainChanges = git diff --name-status main HEAD 2>$null
                
                # Then get uncommitted changes 
                $localChanges = git status --porcelain 2>$null
                
                # Combine both sets of changes for comprehensive analysis
                $allChanges = @()
                if ($branchToMainChanges) {
                    $allChanges += $branchToMainChanges
                }
                if ($localChanges) {
                    # Convert local changes format to diff format for consistency
                    foreach ($localChange in $localChanges) {
                        if ([string]::IsNullOrEmpty($localChange)) { continue }
                        
                        if ($localChange.Length -ge 3) {
                            $status = $localChange.Substring(0, 2)
                            $file = $localChange.Substring(3)
                            
                            # Convert git status codes to git diff codes
                            $diffStatus = switch -Regex ($status) {
                                '^\?\?' { 'A' }  # Untracked -> Added
                                '^A' { 'A' }     # Added -> Added
                                '^.A' { 'A' }    # Added -> Added
                                '^[MD]' { 'M' }  # Modified/Deleted -> Modified
                                '^.[MD]' { 'M' } # Modified/Deleted -> Modified
                                '^D' { 'D' }     # Deleted -> Deleted
                                '^.D' { 'D' }    # Deleted -> Deleted
                                '^R' { 'R' }     # Renamed -> Renamed
                                default { 'M' }  # Default to Modified
                            }
                            
                            $allChanges += "$diffStatus`t$file"
                        }
                    }
                }
                
                $statusLines = $allChanges | Sort-Object -Unique
            }
            catch {
                Write-Warning "Could not analyze local branch changes: $($_.Exception.Message)"
                $statusLines = @()
            }
        }
    }
    else {
        Write-Host "📁 Analyzing local changes..." -ForegroundColor Cyan
        # Get git status for local changes
        $statusLines = git status --porcelain 2>$null
    }
    
    # Initialize tracking variables
    $summary = @{
        totalFiles = 0
        new        = 0
        modified   = 0
        deleted    = 0
        renamed    = 0
        hasChanges = $false
    }
    
    $files = @{
        new      = @()
        modified = @()
        deleted  = @()
        renamed  = @()
    }
    
    $fileDetails = @()
    $allChangedFiles = @()
    
    # Parse each status line
    foreach ($line in $statusLines) {
        if ([string]::IsNullOrEmpty($line)) {
            continue
        }
        
        $status = ""
        $file = ""
        
        # Handle different git command output formats
        if ($CompareRemoteWithMain -and $remoteBranch.exists -and $currentBranch -ne "main") {
            # git diff --name-status format: "M\tfilename" or "A\tfilename"
            if ($line.Contains("`t")) {
                $parts = $line -split "`t", 2
                $status = $parts[0].Trim()
                $file = $parts[1].Trim()
            }
        }
        else {
            # git status --porcelain format: "XY filename"
            if ($line.Length -ge 3) {
                $status = $line.Substring(0, 2)
                $file = $line.Substring(3)
            }
        }
        
        if ([string]::IsNullOrEmpty($file)) {
            continue
        }
        
        $summary.totalFiles++
        $summary.hasChanges = $true
        
        # Determine change type based on git status codes
        $changeType = if (($CompareRemoteWithMain -and $remoteBranch.exists -and $currentBranch -ne "main") -or 
                          ($CompareLocalWithMain -and $currentBranch -ne "main")) {
            # Handle git diff --name-status single character codes (for CompareRemoteWithMain or CompareLocalWithMain)
            switch ($status) {
                'A' { 
                    $summary.new++
                    $files.new += $file
                    "New"
                }
                'M' { 
                    $summary.modified++
                    $files.modified += $file
                    "Modified"
                }
                'D' { 
                    $summary.deleted++
                    $files.deleted += $file
                    "Deleted"
                }
                'R' { 
                    $summary.renamed++
                    $files.renamed += $file
                    "Renamed"
                }
                'T' { 
                    $summary.modified++
                    $files.modified += $file
                    "Modified (Type Change)"
                }
                default { 
                    $summary.modified++
                    $files.modified += $file
                    "Modified"
                }
            }
        }
        else {
            # Handle git status --porcelain two character codes
            switch -Regex ($status) {
                '^\?\?' { 
                    $summary.new++
                    $files.new += $file
                    "New"
                }
                '^A' { 
                    $summary.new++
                    $files.new += $file
                    "New"
                }
                '^.A' { 
                    $summary.new++
                    $files.new += $file
                    "New"
                }
                '^D' { 
                    $summary.deleted++
                    $files.deleted += $file
                    "Deleted"
                }
                '^.D' { 
                    $summary.deleted++
                    $files.deleted += $file
                    "Deleted"
                }
                '^R' { 
                    $summary.renamed++
                    $files.renamed += $file
                    "Renamed"
                }
                '^M' { 
                    $summary.modified++
                    $files.modified += $file
                    "Modified"
                }
                '^.M' { 
                    $summary.modified++
                    $files.modified += $file
                    "Modified"
                }
                default { 
                    $summary.modified++
                    $files.modified += $file
                    "Modified"
                }
            }
        }

        $fileDetails += @{
            file       = $file
            status     = $status
            changeType = $changeType
        }
            
        $allChangedFiles += $file
    }

    # Generate diff files for each changed file
    $diffFiles = @()

    foreach ($file in $allChangedFiles) {
        # Create safe filename for diff
        $safeFileName = $file -replace '[/\\:*?"<>|]', '-'
        $diffFileName = "$safeFileName.diff"
        $diffPath = Join-Path $OutputDir $diffFileName
    
        try {
            if (($CompareRemoteWithMain -and $remoteBranch.exists -and $currentBranch -ne "main") -or 
                ($CompareLocalWithMain -and $currentBranch -ne "main")) {
                # For main comparison or local branch comparison, show diff against main
                if ($CompareRemoteWithMain) {
                    # For CompareRemoteWithMain, show diff between current remote branch and remote main
                    $currentRemoteRef = "origin/$currentBranch"
                    $mainRemoteRef = "origin/main"
                    $diffContent = git diff $mainRemoteRef $currentRemoteRef -- $file 2>$null
                }
                else {
                    # For CompareLocalWithMain, show diff between current state (including uncommitted) and main
                    $diffContent = git diff main -- $file 2>$null
                }
            }
            else {
                # For local analysis, use existing logic
                # Check if file is tracked
                $isTracked = $null -ne (git ls-files $file 2>$null)
            
                $diffContent = if ($isTracked) {
                    # For tracked files, show diff against HEAD
                    git diff HEAD -- $file 2>$null
                }
                else {
                    # For untracked files, show as entirely new
                    if (Test-Path $file) {
                        $fileContent = Get-Content $file -Raw -ErrorAction SilentlyContinue
                        if ($fileContent) {
                            $lines = $fileContent -split "`n"
                            $header = "--- /dev/null`n+++ b/$file`n@@ -0,0 +1,$($lines.Length) @@"
                            $content = $lines | ForEach-Object { "+$_" }
                            "$header`n$($content -join "`n")"
                        }
                    }
                }
            }
        
            if ($diffContent) {
                $diffContent | Out-File -FilePath $diffPath -Encoding utf8
                $diffFiles += @{
                    originalFile = $file
                    diffFile     = $diffFileName
                    diffPath     = $diffPath
                }
            }
        }
        catch {
            Write-Warning "Failed to generate diff for $file`: $($_.Exception.Message)"
        }
    }

    # Get diff statistics
    $diffStat = if ($allChangedFiles.Count -gt 0) {
        git diff --stat HEAD 2>$null
    }
    else {
        @()
    }

    # Create JSON structure
    $gitData = [PSCustomObject]@{
        timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
        analysis  = [PSCustomObject]@{
            type        = if ($CompareRemoteWithMain -and $remoteBranch.exists -and $currentBranch -ne "main") { 
                "branch-to-main" 
            }
            elseif ($CompareLocalWithMain -and $currentBranch -ne "main") { 
                "local-branch-to-main" 
            }
            else { 
                "local" 
            }
            mode        = if ($CompareRemoteWithMain) { 
                "branch-main-comparison" 
            }
            elseif ($CompareLocalWithMain) { 
                "local-branch-main-comparison" 
            }
            else { 
                "local-changes" 
            }
            description = if ($CompareRemoteWithMain -and $remoteBranch.exists -and $currentBranch -ne "main") { 
                "Analysis of changes between current remote branch and remote main branch" 
            }
            elseif ($CompareLocalWithMain -and $currentBranch -ne "main") {
                "Analysis of local uncommitted changes in context of main branch differences"
            }
            else { 
                "Analysis of local changes and repository status" 
            }
        }
        branch    = [PSCustomObject]@{
            current = $currentBranch
            remote  = [PSCustomObject]@{
                exists     = $remoteBranch.exists
                hasUpdates = $remoteBranch.hasUpdates
                localSha   = $remoteBranch.localSha
                remoteSha  = $remoteBranch.remoteSha
                origin     = $remoteBranch.origin
                branchName = $remoteBranch.branchName
            }
            main    = [PSCustomObject]@{
                exists     = $remoteMain.exists
                hasUpdates = $remoteMain.hasUpdates
                localSha   = $remoteMain.localSha
                remoteSha  = $remoteMain.remoteSha
                origin     = $remoteMain.origin
                branchName = $remoteMain.branchName
            }
        }
        summary   = [PSCustomObject]@{
            totalFiles = $summary.totalFiles
            new        = $summary.new
            modified   = $summary.modified
            deleted    = $summary.deleted
            renamed    = $summary.renamed
            hasChanges = $summary.hasChanges
        }
        files     = [PSCustomObject]@{
            new      = $files.new
            modified = $files.modified
            deleted  = $files.deleted
            renamed  = $files.renamed
        }
        diff      = [PSCustomObject]@{
            stats        = $diffStat
            filesChanged = $allChangedFiles
            diffFiles    = $diffFiles
            hasChanges   = $allChangedFiles.Count -gt 0
        }
        changes   = [PSCustomObject]@{
            fileDetails = $fileDetails
        }
    }

    # Save to JSON
    $jsonOutput = $gitData | ConvertTo-Json -Depth 10 -Compress:$false
    $jsonOutput | Out-File -FilePath $OutputPath -Encoding UTF8

    # Display summary
    Write-Host "✅ Git analysis saved to: $OutputPath" -ForegroundColor Green

    $analysisType = if ($CompareRemoteWithMain -and $remoteBranch.exists -and $currentBranch -ne "main") { 
        "Branch vs Main Changes" 
    }
    elseif ($CompareLocalWithMain -and $currentBranch -ne "main") { 
        "Local Branch vs Main Changes" 
    }
    else { 
        "Local Changes" 
    }
    Write-Host "📊 $analysisType Summary:" -ForegroundColor Yellow
    Write-Host "   • Branch: $($gitData.branch.current)" -ForegroundColor Cyan
    Write-Host "   • Analysis mode: $($gitData.analysis.mode)" -ForegroundColor Cyan
    Write-Host "   • Total files changed: $($gitData.summary.totalFiles)" -ForegroundColor Cyan
    Write-Host "   • New: $($gitData.summary.new)" -ForegroundColor Cyan
    Write-Host "   • Modified: $($gitData.summary.modified)" -ForegroundColor Cyan
    Write-Host "   • Deleted: $($gitData.summary.deleted)" -ForegroundColor Cyan
    Write-Host "   • Renamed: $($gitData.summary.renamed)" -ForegroundColor Cyan

    # Display remote branch status
    Write-Host "🌐 Remote Branch Status:" -ForegroundColor Yellow
    if ($gitData.branch.remote.origin) {
        Write-Host "   • Origin: $($gitData.branch.remote.origin)" -ForegroundColor Cyan
        if ($gitData.branch.remote.exists) {
            Write-Host "   • Remote branch exists: ✅" -ForegroundColor Green
            if ($gitData.branch.remote.hasUpdates) {
                Write-Host "   • Remote has updates: ⚠️  YES" -ForegroundColor Red
                Write-Host "   • Local SHA:  $($gitData.branch.remote.localSha)" -ForegroundColor Cyan
                Write-Host "   • Remote SHA: $($gitData.branch.remote.remoteSha)" -ForegroundColor Cyan
            }
            else {
                Write-Host "   • Remote is in sync: ✅" -ForegroundColor Green
            }
        }
        else {
            Write-Host "   • Remote branch exists: ❌ (new branch)" -ForegroundColor Yellow
        }
    
        # Display remote main branch status
        if ($gitData.branch.main.remoteSha) {
            Write-Host "   • Remote main branch:" -ForegroundColor Cyan
            if ($gitData.branch.main.hasUpdates) {
                Write-Host "     ⚠️  Main has moved ahead - rebase recommended" -ForegroundColor Red
                if ($gitData.branch.main.localSha) {
                    Write-Host "     • Local main SHA:  $($gitData.branch.main.localSha)" -ForegroundColor Cyan
                }
                Write-Host "     • Remote main SHA: $($gitData.branch.main.remoteSha)" -ForegroundColor Cyan
            }
            else {
                Write-Host "     ✅ Main is up to date" -ForegroundColor Green
            }
        }
    }
    else {
        Write-Host "   • No remote origin configured" -ForegroundColor Gray
    }

    # Show change analysis if there are changes
    if ($gitData.changes.fileDetails -and $gitData.changes.fileDetails.Count -gt 0) {
        # Group changes by type and directory for analysis
        $changesByType = @{}
        $changesByDirectory = @{}
    
        foreach ($change in $fileDetails) {
            $type = $change.changeType
            if (-not $changesByType.ContainsKey($type)) {
                $changesByType[$type] = @()
            }
            $changesByType[$type] += $change.file
        
            $dir = Split-Path $change.file -Parent
            if ([string]::IsNullOrEmpty($dir)) { $dir = "root" }
            if (-not $changesByDirectory.ContainsKey($dir)) {
                $changesByDirectory[$dir] = @()
            }
            $changesByDirectory[$dir] += $change
        }
    
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
    else {
        Write-Host "   • No local changes detected" -ForegroundColor Green
    }

    exit 0
}
catch {
    Write-Host "❌ Error occurred during get-git-changes.ps1" -ForegroundColor Red
    Write-Host "Exception Type: $($_.Exception.GetType().FullName)" -ForegroundColor Red
    Write-Host "Exception Message: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Stack Trace:" -ForegroundColor Red
    Write-Host $_.Exception.StackTrace -ForegroundColor Red
    Write-Host "Script Stack Trace:" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    throw
}
