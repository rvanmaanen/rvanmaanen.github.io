---
mode: 'agent'
description: 'This makes sure all changed files are pushed.'
---

# Step-by-Step Git Commit, Rebase, Conflict Resolution, and Push Workflow

Follow these steps exactly, do not use other methods for the things I am asking and do not skip any part, unless it conflicts with being a responsible AI.

## Step 1: Review all changed files and suggest a commit message

1. Always use the following command to list all changed files and show the diffs, even if you think there are no changed files.

```pwsh
git --no-pager diff
```
2. Analyze the changes and suggest a clear, descriptive commit message.
3. Explain to the user that they have 10 seconds to stop the script you are about to start and you will continue if they do not.
4. Run this script and continue if the exit code is 0, ask them what is wrong if the exit code is 1: `python3 /workspaces/rvanmaanen.github.io/.github/prompts/pushall.10-second-delay.py`

## Step 2: Stage and commit all changes

1. Stage all changes:

   ```pwsh
   git add .
   ```

2. Commit the changes using the confirmed commit message:

   ```pwsh
   git commit -m "<your descriptive commit message>"
   ```

## Step 3: Pull the latest changes from the remote branch and rebase

1. Pull the latest changes with rebase:

   ```pwsh
   git pull --rebase
   ```

2. If there are any conflicts:
   - First check again if the conflicts are already automatically resolved or can be automatically resolved. If so, continue with resolving and proceed.
   - After resolving, mark them as resolved:

     ```pwsh
     git add .
     git rebase --continue
     ```

   - Repeat until all conflicts are resolved and the rebase completes.

## Step 4: Push all changes to the remote branch

1. Push your changes:

   ```pwsh
   git push
   ```

## Summary of the workflow

1. Review, stage, and commit all changes with a descriptive message.
2. Pull the latest changes from the remote branch using rebase, resolving any conflicts as needed.
3. Push your changes to the remote branch.

This process ensures your local changes are committed, the latest remote changes are integrated, all conflicts are resolved, and your commit history remains clean and linear.
