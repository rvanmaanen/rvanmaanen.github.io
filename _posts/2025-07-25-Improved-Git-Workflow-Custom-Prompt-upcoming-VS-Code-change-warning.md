---
layout: "post"
title: "Improved Git Workflow Custom Prompt & Upcoming VS Code change warning"
tags: ["Visual Studio Code", "VS Code", "GitHub Copilot", "Copilot Chat", "Git", "Workflow", "Custom Prompts", "Terminal", "Automation", "Developer Tools", "Configuration", "Updates", "Version Control"]
description: "Updates to my Git workflow custom prompt and important changes coming to VS Code terminal auto-approval"
excerpt_separator: "<!--excerpt_end-->"
permalink: "improved-git-workflow-custom-prompt-upcoming-vscode-change-warning.html"
---

Following up on [my previous post]({{ "/automating-my-git-workflow-vscode-copilot-chat-terminal-auto-approval.html" | relative_url }}) about automating Git workflows with VS Code and Copilot Chat, I've made some improvements to my custom prompt and discovered an important upcoming change in VS Code that affects the terminal auto-approval feature.<!--excerpt_end-->

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

If you want to use this, make sure you at least have the GitHub MCP server configured. Also, I haven't tested this outside my own environment, so please mention any bugs to me and I'll try to fix them for everyone!

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

### Comparison Table

| What | Before | After |
|------|--------|-------|
| **Branch Handling** | Any branch (risky) | Main branch protection |
| **Change Analysis** | Simple `git --no-pager diff` | PowerShell script with JSON output and structured metadata |
| **Pull Request Integration** | No PR functionality | PR creation, updates, and Copilot reviews |
| **User Experience** | Single 10-second delay with basic output | Multiple confirmation points with enhanced UI |
| **Automation** | Required manual intervention | Intelligent defaults for unattended operation |
| **Terminal UI** | Simple text-based output | Responsive, colored design with progress bars |
| **Script Architecture** | Single Python script | Two specialized PowerShell scripts working together |
| **Workflow Complexity** | 4 simple steps | 14 detailed steps |
| **Conflict Resolution** | Basic instructions | Enhanced guidance |

### Details

#### 1. **Branch Protection**

- **Old:** Worked on any branch (dangerous on main)
- **New:** Automatically detects main branch and shows 10-second delay asking to create feature branch with suggested name, or lets user abort to choose different approach

#### 2. **Improved Change Analysis**

- **Old:** Basic `git --no-pager diff` output analyzed by AI
- **New:** Dedicated PowerShell script creates comprehensive analysis in `.tmp/git-changes-analysis/` with JSON metadata file containing status summary, branch info, unpushed commits, remote changes detection, and individual `.diff` files for each changed file with exact file paths

#### 3. **Pull Request Integration**

- **Old:** No PR functionality
- **New:** Full GitHub MCP integration with dedicated tools for creating PRs, updating existing ones, checking reviews, and requesting Copilot code reviews through structured API calls

#### 4. **Better User Experience**

- **Old:** Single 10-second delay with basic terminal output
- **New:** Multiple confirmation points using enhanced PowerShell script with responsive UI, colored output, progress bars, and interactive controls (SPACE to abort, ENTER to continue immediately)

#### 5. **Intelligent Defaults for Unattended Operation**

- **Old:** Required manual confirmation at every step, blocking automation
- **New:** Smart defaults allow completely unattended operation - automatically creates feature branches from main, proceeds with commits when on correct branch, handles remote changes detection, all without user intervention when confident about changes

#### 6. **Enhanced Terminal UI**

- **Old:** Simple text-based output with basic messaging
- **New:** Responsive terminal design with dynamic window resizing, colored headers, bordered message boxes, progress bars with percentages, and real-time countdown timers that adapt to terminal width

#### 7. **Better Script Architecture**

- **Old:** Single Python delay script (`pushall.10-second-delay.py`)
- **New:** Two specialized PowerShell scripts: `get-git-changes.ps1` for comprehensive git analysis with structured JSON output, and `pushall-delay.ps1` for flexible user confirmations with message files and customizable delays

#### 8. **Enhanced Workflow Complexity**

- **Old:** Simple 4-step workflow with basic instructions
- **New:** Comprehensive 14-step workflow with CRITICAL instruction blocks, explicit command usage guidelines separating Git/PowerShell from GitHub MCP operations, structured commit message generation from JSON analysis, and built-in error handling

#### 9. **Improved Conflict Resolution**

- **Old:** Basic instructions for handling conflicts
- **New:** Enhanced guidance with automatic remote changes detection during fetch operations, structured conflict resolution steps, and clear separation between local Git operations and GitHub API calls

### VS Code Terminal Allow List

The following should be enough in your allowList to automatically have the prompt perform anything it needs to do. Except authorize the MCP actions, but you can do things like 'Always allow in this workspace' for that if you want.

```json
"github.copilot.chat.agent.terminal.allowList": {
  "git": true,
  "pwsh": true
}
```

### To be clear, the usage has not changed

You still just call /pushall and things (should) work:

<div class="image-gallery">
  <div class="image-item full-width">
    <img src="{{ "/assets/auto-approve-terminal-commands/slashcommand.png" | relative_url }}" alt="Custom Prompts in VS Code">
    <div class="image-caption">Starting with /pushall command</div>
  </div>
</div>

## Upcoming VS Code Changes

⚠️ **Important Breaking Change Alert!** ⚠️

Microsoft has merged two significant changes to the terminal auto-approval feature that will affect your current configuration. They're described next.
However, I want to highlight it seems they plan to change it even more by changing the name from `github.copilot.chat.agent.terminal.autoApprove` to `chat.agent.terminal.allowList` and `chat.agent.terminal.denyList` so you even might need to use these settings by the time the new version gets released.

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
