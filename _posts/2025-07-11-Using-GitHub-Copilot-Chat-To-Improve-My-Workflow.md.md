---
layout: post
title: "Automating Git Workflows in VS Code with Copilot Chat, Custom Prompts, and Terminal Auto-Approval"
categories: vscode copilot automation git
description: Automate your entire Git workflow in Visual Studio Code using Copilot Chat, custom prompts, and the new terminal auto-approval feature
excerpt_separator: <!--excerpt_end-->
permalink: automating-git-workflows-vscode-copilot-chat-terminal-auto-approval
---

With the June 2025 ([v1.102](https://code.visualstudio.com/updates/v1_102#_terminal-auto-approval-experimental)) release of Visual Studio Code, I have streamlined my Git workflow by combining Copilot Chat's new features, custom prompts, and the experimental terminal auto-approval system. This setup allows me to automate the process of reviewing changes, generating commit messages, and pushing updates, all with minimal manual intervention and maximum safety.<!--excerpt_end-->

## Index

- [Some visuals](#some-visuals)
- [Key Features Used](#key-features-used)
- [Workflow triggered by /pushall](#workflow-triggered-by-pushall)
- [How I Set It Up](#how-i-set-it-up)
  - [Settings](#settings)
  - [Prompts](#prompts)
  - [Python Delay Script for allowing me to intervene](#python-delay-script-for-allowing-me-to-intervene)
- [Benefits](#benefits)
- [References](#references)

## Some visuals

Starting the workflow is as simple as typing `/pushall` in the Copilot Chat. In the following screenshots you'll see me start the prompt. 

<div class="image-gallery">
  <div class="image-item full-width">
    <img src="{{ "/assets/auto-approve-terminal-commands/slashcommand.png" | relative_url }}" alt="Custom Prompts in VS Code">
    <div class="image-caption">Starting with /pushall command</div>
  </div>
</div>

Then it did some git diff magic and suggested a commit message to me:

```text
I can see there are changes to a blog post file. The changes include:

- Adding a hyperlink to the Visual Studio Code v1.102 release notes
- Adding a link to the official documentation

Let me analyze these changes and suggest a commit message:

Suggested commit message: "Add links to VS Code v1.102 release notes and Copilot customization docs"

This is a clear, descriptive commit message that explains the specific improvements made to the blog post by adding helpful reference links.
```

Here are some two screenshots of the next possible scenarios, one where I abort the workflow and one where I continue with the commit and push.

<style>
.image-gallery {
  display: flex;
  flex-wrap: wrap;
  gap: 20px;
  justify-content: center;
  margin: 20px 0;
}

.image-item {
  flex: 1;
  min-width: 250px;
  max-width: 350px;
  text-align: center;
}

.image-item.full-width {
  flex: 1 1 100%;
  max-width: 500px;
}

.image-item img {
  width: 100%;
  height: auto;
  border: 1px solid #ddd;
  border-radius: 8px;
}

.image-caption {
  margin-top: 10px;
  font-size: 14px;
  color: #666;
  font-style: italic;
}

@media (max-width: 768px) {
  .image-gallery {
    flex-direction: column;
    align-items: center;
  }
  
  .image-item {
    max-width: 100%;
  }
}
</style>

<div class="image-gallery">
   <div class="image-item">
    <img src="{{ "/assets/auto-approve-terminal-commands/controlc.png" | relative_url }}" alt="Aborting the workflow">
    <div class="image-caption">Aborting with Ctrl+C</div>
  </div>
  <div class="image-item">
    <img src="{{ "/assets/auto-approve-terminal-commands/continued.png" | relative_url }}" alt="Workflow in action">
    <div class="image-caption">Workflow executing</div>
  </div>
</div>



## Key Features Used

### Terminal Auto-Approval (Experimental)

- **Auto-approve safe commands:** I configured the `github.copilot.chat.agent.terminal.allowList` in my workspace settings to automatically allow safe commands like `git status`, `git log`, `git add`, and `git commit` to run without manual approval.
- **Deny-list for safety:** Dangerous commands (e.g., `rm`, `curl`) are blocked using the `denyList` to prevent accidental or malicious execution.

### Custom Prompts and Instructions

- **Prompt files:** I created reusable `.prompt.md` files in `.github/prompts` to guide Copilot Chat through my preferred Git workflow (review, commit, rebase, push). I can then trigger these prompts with simple commands like `/pushall` in chat.
- **Instruction files:** My `.github/copilot-instructions.md` file describes some sensible defaults for Copilot to use, like using English. These are automatically included in chat requests, ensuring Copilot always follows my preferences.
- **Agent mode:** I use agent mode to let Copilot Chat execute multi-step workflows, such as staging changes, generating commit messages, rebasing, and pushing, all triggered by a single prompt.

[Look here for the offical docs](https://code.visualstudio.com/docs/copilot/copilot-customization)

## Workflow triggered by /pushall

1. **Review changes:**
   - Copilot Chat lists all changed files and diffs using `git --no-pager diff`.
2. **Generate commit message:**
   - Copilot suggests a descriptive commit message based on the changes.
3. **Stage and commit:**
   - Safe commands like `git add .` and `git commit -m "..."` are auto-approved and executed.
4. **Rebase and resolve conflicts:**
   - Copilot runs `git pull --rebase` and guides me through any conflicts, only running allowed commands.
5. **Push to remote:**
   - `git push` is executed automatically if all previous steps succeed.

## How I Set It Up

### Settings

My actual `settings.json` includes the following configuration to control which terminal commands Copilot Chat can run automatically:

```json
"github.copilot.chat.agent.terminal.allowList": {
    "git": true,
    "echo": true,
    "cd": true,
    "ls": true,
    "cat": true,
    "pwd": true,
    "dir": true,
    "Write-Host": true,
    "Set-Location": true,
    "Get-ChildItem": true,
    "Get-Content": true,
    "Get-Location": true,
    "less": true,
    "more": true,
    "python3": true
},
"github.copilot.chat.agent.terminal.denyList": {
    "rm": true,
    "rmdir": true,
    "del": true,
    "kill": true,
    "curl": true,
    "wget": true,
    "eval": true,
    "chmod": true,
    "chown": true,
    "Remove-Item": true
}
```

### Prompts

I store my Git automation prompt in `.github/prompts/pushall.prompt.md` and trigger it with `/pushall` in chat. This prompt guides Copilot Chat through the full workflow: review, commit, rebase, and push.

```markdown
---
mode: 'agent'
description: 'This makes sure all changed files are pushed.'
---

# Step-by-Step Git Commit, Rebase, Conflict Resolution, and Push Workflow

Follow these steps exactly, do not use other methods for the things I am asking and do not skip any part, unless it conflicts with being a responsible AI.

## Step 1: Review all changed files and suggest a commit message

1. Always use the following command to list all changed files and show the diffs, even if you think there are no changed files: `git --no-pager diff`
2. Analyze the changes and suggest a clear, descriptive commit message.
3. Explain to the user that they have 10 seconds to stop the script you are about to start and you will continue if they do not.
4. Run this script and continue if the exit code is 0, ask them what is wrong if the exit code is 1: `python3 /workspaces/rvanmaanen.github.io/.github/prompts/pushall.10-second-delay.py`

## Step 2: Stage and commit all changes

1. Stage all changes:

   git add .
   
2. Commit the changes using the confirmed commit message:

   git commit -m "<your descriptive commit message>"

## Step 3: Pull the latest changes from the remote branch and rebase

1. Pull the latest changes with rebase:

   git pull --rebase

2. If there are any conflicts:
   - First check again if the conflicts are already automatically resolved or can be automatically resolved. If so, continue with resolving and proceed.
   - After resolving, mark them as resolved:

     git add .
     git rebase --continue

   - Repeat until all conflicts are resolved and the rebase completes.

## Step 4: Push all changes to the remote branch

1. Push your changes:

   git push

## Summary of the workflow

1. Review, stage, and commit all changes with a descriptive message.
2. Pull the latest changes from the remote branch using rebase, resolving any conflicts as needed.
3. Push your changes to the remote branch.

This process ensures your local changes are committed, the latest remote changes are integrated, all conflicts are resolved, and your commit history remains clean and linear.
```

### Python Delay Script for allowing me to intervene

The latest Visual Studio Code release introduced a new feature that allows terminal commands to be auto-approved, which I use to streamline my Git workflow. However, I still want to ensure I have control over the final push.

To make the push workflow both automated and safe, I use a custom Python script (`.github/prompts/pushall.10-second-delay.py`) as part of my prompt. Before any changes are committed and pushed, the script gives me a 10-second window to abort or make last-minute edits (like changing the commit message). If I do nothing, the workflow continues and pushes my changes. If I press Ctrl+C, the process is aborted and nothing is pushed.

```python
import time
import sys
import signal

aborted = [False]

def handle_abort(signum, frame):
    aborted[0] = True

def main():
    print("\nYou have 10 seconds to abort this process (Ctrl+C or send SIGTERM) if you want to stop the push workflow.")
    print("If you do nothing, the workflow will continue and your changes will be committed and pushed.")
    print("If you abort, the workflow will stop and nothing will be pushed.\n")
    sys.stdout.flush()
    signal.signal(signal.SIGINT, handle_abort)
    signal.signal(signal.SIGTERM, handle_abort)
    start = time.time()
    while time.time() - start < 10:
        time.sleep(0.1)
        if aborted[0]:
            print("\nAborted by user. Exiting with code 1.")
            sys.exit(1)
    print("\nNo abort detected. Proceeding with the workflow. Exiting with code 0.")
    sys.exit(0)

if __name__ == "__main__":
    main()
```

This ensures I always have a chance to review or cancel before anything is pushed, combining automation with control.

## Benefits

- **Speed:** Routine Git operations are now a single chat command away.
- **Safety:** Only trusted commands are auto-approved; risky ones always require manual confirmation.
- **Consistency:** Custom instructions and prompts ensure every commit and push follows my standards.

## References

- [VS Code v1.102 Release Notes](https://code.visualstudio.com/updates/v1_102#_terminal-auto-approval-experimental)
- [Customize Copilot with Instructions and Prompts](https://code.visualstudio.com/docs/copilot/copilot-customization)

*This article was co-written with GitHub Copilot Chat*
