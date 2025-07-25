---
layout: "post"
title: "Improved Git Workflow Custom Prompt & Upcoming VS Code change warning"
tags: ["Visual Studio Code", "VS Code", "GitHub Copilot", "Copilot Chat", "Git", "Workflow", "Custom Prompts", "Terminal", "Automation", "Developer Tools", "Configuration", "Updates", "Version Control"]
description: "Updates to my Git workflow custom prompt and important changes coming to VS Code terminal auto-approval"
excerpt_separator: "<!--excerpt_end-->"
permalink: "improved-git-workflow-custom-prompt-upcoming-vscode-change-warning.html"
---

Following up on my previous post about automating Git workflows with VS Code and Copilot Chat, I've made some improvements to my custom prompt and discovered an important upcoming change in VS Code that affects the terminal auto-approval feature.<!--excerpt_end-->

## Index

- [What's Changed](#whats-changed)
- [Improved Custom Prompt](#improved-custom-prompt)
- [Upcoming VS Code Changes](#upcoming-vs-code-changes)
- [What You Need to Do](#what-you-need-to-do)
- [References](#references)

## What's Changed

Since my last post about automating Git workflows, two important developments have occurred:

1. **Custom Prompt Improvements:** I've refined my `/pushall` prompt based on real-world usage, adding better error handling, smarter commit message generation, enhanced safety checks, new terminal UI and switched to PowerShell for the scripts.

2. **Breaking VS Code Changes:** Microsoft has made significant changes to the terminal auto-approval configuration that will require updating your settings. These changes are already merged and will ship in VS Code v1.103 (July 2025 release, shipped in August 2025).

The good news is that the changes from Microsoft improve the functionality by consolidating the configuration and adding regex flag support. However, you'll need to update your settings to avoid any disruption to your workflow.

## Improved Custom Prompt

After using the `/pushall` command for a while, I learned what worked and what didn't. So I rewrote it. The original was 175 lines, the new one is 226 lines. Not exactly a revolution, but it handles real-world scenarios much better.

### Better Terminal Experience

Because I had the most fun creating this, let me start off by how the new terminal output looks like. Btw, it's fully responsive if you resize :)

<div class="image-gallery">
  <div class="image-item full-width">
    <img src="{{ "/assets/pushall/wide-terminal.png" | relative_url }}" alt="Enhanced terminal UI with progress bars and responsive layout. Wide view.">
    <div class="image-caption">The PowerShell scripts look nicer and handle window resizing properly.</div>
  </div>
  <div class="image-item">
    <img src="{{ "/assets/pushall/small-terminal.png" | relative_url }}" alt="Enhanced terminal UI with progress bars and responsive layout. Small view.">
    <div class="image-caption">The same terminal but then resized.</div>
  </div>
</div>

### Actual files

This rest of this post provides a high-level overview of the improvements. The complete updated files are available for download:

- [pushall.prompt.md]({{ "/assets/pushall/pushall.prompt.md" | relative_url }}) - The main workflow prompt
- [pushall-delay.ps1]({{ "/assets/pushall/pushall-delay.ps1" | relative_url }}) - Enhanced user confirmation script
- [get-git-changes.ps1]({{ "/assets/pushall/get-git-changes.ps1" | relative_url }}) - Git analysis script

### Tips

First off, a small tip. If you know what you want to do, you can just still use the prompt and just give some additional instructions:

```text
/pushall skip the approval steps, make a new branch, move my changes there, create a PR and assign to Copilot
```

Results in:

```text
I'll follow the pushall workflow instructions and skip the approval steps as requested. Let me start by checking the current branch and changes.
```

This just very quickly performs this entire workflow without any interruptions.

### What Changed

**Switched from Python to PowerShell:**

- **Old:** Single Python delay script (`pushall.10-second-delay.py`)
- **New:** Switched to PowerShell for easier reuse. There are two new scripts that work well together:
  - `pushall-delay.ps1` - Better user confirmation with more flexible messaging
  - `get-git-changes.ps1` - Analyzes Git changes and saves structured data

**Better Change Analysis:**

- **Old:** Basic `git --no-pager diff` output analyzed by AI
- **New:** Dedicated PowerShell script that creates structured analysis saved to `.tmp/git-changes-analysis/` with:
  - JSON metadata (`git-changes-analysis.json`)
  - Individual `.diff` files for each changed file
  - Branch info, unpushed commits, and remote change detection

**Rewrote the Prompt Structure:**

- **Old:** Simple 4-step workflow with basic instructions
- **New:** Comprehensive 14-step workflow with:
  - Multiple **CRITICAL** instruction blocks at the top
  - Explicit tool usage guidelines (Git vs GitHub MCP vs PowerShell)
  - Branch protection logic (detects main branch)
  - Structured commit message generation from JSON analysis
  - PR creation and management steps
  - Copilot review request functionality

### The Actual Improvements

#### 1. **Branch Protection**

- **Old:** Worked on any branch (dangerous on main)
- **New:** Detects main branch and offers to create a feature branch instead

#### 2. **Smarter Commit Messages**

- **Old:** AI analyzed diff and suggested commit message
- **New:** AI generates commit messages from structured JSON analysis

#### 3. **Pull Request Integration**

- **Old:** No PR functionality
- **New:** Creates PRs, updates existing ones, and can request Copilot reviews

#### 4. **Better User Experience**

- **Old:** Single 10-second delay with basic terminal output
- **New:** Multiple confirmation points with enhanced UI and progress feedback

#### 5. **Error Handling**

- **Old:** Basic error messages and conflict guidance
- **New:** Comprehensive error handling with detailed troubleshooting steps

### Comparison Table

| What | Before | After |
|------|--------|-------|
| **Change Analysis** | Simple `git --no-pager diff` | PowerShell script with JSON output |
| **Branch Handling** | Any branch (risky) | Main branch protection |
| **Commit Messages** | Basic AI analysis | Structured AI from JSON |
| **Conflict Resolution** | Basic instructions | Enhanced guidance |
| **User Experience** | Single Python delay script | Multiple PowerShell confirmations |
| **GitHub Integration** | None | PR creation and updates |
| **Error Handling** | Basic error messages | Comprehensive error handling |
| **Workflow Steps** | 4 simple steps | 14 detailed steps |

### VS Code Terminal Allow List

The following should be enough in your allowList to automatically have the prompt perform anything it needs to do. Except authorize the MCP actions, but you can do things like 'Always allow in this workspace' for that if you want.

```json
"github.copilot.chat.agent.terminal.allowList": {
  "git": true,
  "pwsh": true
}
```

## Upcoming VS Code Changes

⚠️ **Important Breaking Change Alert!** ⚠️

Microsoft has merged two significant changes to the terminal auto-approval feature that will affect your current configuration:

### Configuration Consolidation (PR #256725)

The biggest change is that the separate `allowList` and `denyList` settings have been **merged into a single `autoApprove` setting**. This means your current configuration will need to be updated.

**Before (current configuration):**

```json
"github.copilot.chat.agent.terminal.allowList": {
    "git": true,
    "echo": true,
    "ls": true
},
"github.copilot.chat.agent.terminal.denyList": {
    "rm": true,
    "curl": true,
    "wget": true
}
```

**After (new configuration):**

```json
"github.copilot.chat.agent.terminal.autoApprove": {
    "git": true,
    "echo": true,
    "ls": true,
    "rm": false,
    "curl": false,
    "wget": false
}
```

### Enhanced Regex Support (PR #256754)

The second improvement adds support for **regex flags and case-insensitive matching**:

- **Regex flags:** You can now use JavaScript regex flags like `i` (case-insensitive), `m` (multiline), `s` (dotall), etc.
- **Case-insensitive matching:** Perfect for PowerShell commands that might have different casing
- **Better PowerShell support:** Default configuration now includes `/^Remove-Item\\b/i` instead of just `Remove-Item`

**Examples of new regex capabilities:**

```json
"github.copilot.chat.agent.terminal.autoApprove": {
    "/^git\\s+/i": true,           // Case-insensitive git commands
    "/^Get-ChildItem\\b/i": true,  // Case-insensitive PowerShell
    "/^echo.*/s": true,            // Dotall flag for multiline
    "rm": false,                   // Simple string matching
    "/dangerous/i": false          // Case-insensitive deny pattern
}
```

## What You Need to Do

### 1. Update Your Settings Configuration

If you're using my previous Git workflow setup, you'll need to migrate your settings before the next VS Code update, which should be as easy as merging the lists, changing the configuration entry name and setting false for the commands that should not be automatically approved.

### 2. Take Advantage of New Features

With the enhanced regex support, you can now:

- **Use case-insensitive patterns** for PowerShell commands: `/^Get-ChildItem\\b/i`
- **Create more flexible git patterns**: `/^git\\s+(status|log|show|diff)\\b/i`
- **Handle command variations**: `/^(echo|print|printf)\\b/i`

Use this to simplify the configuration.

### 3. Timeline

These changes are already merged and will be included in the **July 2025 release** of VS Code (v1.103), which will be shipped in **August 2025**. Only when you update to this version will the old configuration stop working.

## References

- [Previous post: Automating my Git workflow in VS Code]({{ "/automating-my-git-workflow-vscode-copilot-chat-terminal-auto-approval.html" | relative_url }})
- [VS Code Issue #253472: Terminal auto approval - merge allow and deny list](https://github.com/microsoft/vscode/issues/253472)
- [VS Code Issue #256742: Terminal auto approval - support regex flags and case insensitive remove-item](https://github.com/microsoft/vscode/issues/256742)
- [VS Code PR #256725: Merge allow and deny lists into autoApprove](https://github.com/microsoft/vscode/pull/256725)
- [VS Code PR #256754: Support regex flags and case insensitive remove-item](https://github.com/microsoft/vscode/pull/256754)
- [VS Code v1.102 Release Notes](https://code.visualstudio.com/updates/v1_102#_terminal-auto-approval-experimental)
- [Customize Copilot with Instructions and Prompts](https://code.visualstudio.com/docs/copilot/copilot-customization)

*This article was co-written with GitHub Copilot Chat*
