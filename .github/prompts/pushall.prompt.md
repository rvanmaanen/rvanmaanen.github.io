---
mode: 'agent'
description: 'Step-by-step git workflow for committing, rebasing, and pushing changes with branch protection, comprehensive change analysis, and optional PR creation'
model: Claude Sonnet 4
---

**🚨 CRITICAL PROMPT SCOPE**: All instructions, restrictions, and requirements in this prompt file ONLY apply when this specific prompt is being actively executed via the `/pushall` command or equivalent prompt invocation. These rules do NOT apply when editing, reviewing, or working with this file outside of prompt execution context. When working with this file in any other capacity (editing, debugging, documentation, etc.), treat it as a normal markdown file and ignore all workflow-specific instructions.

**CRITICAL**: STRICTLY follow each step in this script and NEVER skip any steps or instructions unless explicitly mentioned.
**CRITICAL**: When instructed to use the `./.github/prompts/pushall-delay.ps1` script, ALWAYS do so and do exactly as instructed.
**CRITICAL**: Exclusivly use the GitHub MCP tools for GitHub related actions, such as listing and creating pull and updating pull requests requests. Or listing and requesting code reviews. **Never** use `gh`
**CRITICAL**: ALL powershell scripts should be executed with the 'pwsh' command in front. So never `@"test" | Out-File`, always `pwsh @"text" | Out-File`. And never `./.github/prompts/script.ps1`, always `pwsh ./.github/prompts/script.ps1`
**CRITICAL**: Remember escaping in PowerShell happens with a backtick instead of a backslash.

# Step-by-Step Git Commit, Rebase, Conflict Resolution, and Push Workflow

1. **Check current branch and analyze changes:**

    ```pwsh
    ./.github/prompts/get-git-changes.ps1
    ```

    This script captures comprehensive git changes analysis, including git status, individual diff files, and branch information, saving it to `.tmp/git-changes-analysis/` directory. The main analysis data is in `git-changes-analysis.json` and individual `.diff` files are created for each changed file.
    
    **CRITICAL**: After the script completes, verify that the analysis file was created successfully:
    
    ```pwsh
    Test-Path ".tmp/git-changes-analysis/git-changes-analysis.json"
    ```
    
    If the file doesn't exist, inform the user that the script failed and ask them to check for errors before continuing.
    
    **After successful verification, analyze the changes:**
    
    - Review the `summary` object to understand the scope of changes (totalFiles, new, modified, deleted, renamed)
    - Check the `files` object for categorized file lists (new, modified, deleted, renamed arrays)  
    - **CRITICAL**: Use exact `diffPath` values from `diff.diffFiles[]` array in the JSON - do NOT assume filename formats
    - **For modified files**: Examine the individual `.diff` files using the paths from JSON for detailed understanding of what changed
    - **For new files**: Read the new file contents directly, because there are no diff available since they're new
    - **For deleted files**: No content to review since they've been removed
    - Check the `branch` information for context, including `hasUnpushedCommits` and `unpushedCommits`
    - Review `changes.fileDetails` for per-file change analysis with change types and git status codes
    - Check `diff.stats` and `diff.filesChanged` for overall diff statistics

    **How to locate diff files (only available for modified files):**

    ```
    # Read the JSON to get exact diff file paths
    $analysis = Get-Content ".tmp/git-changes-analysis/git-changes-analysis.json" | ConvertFrom-Json
    # Use the exact paths from $analysis.diff.diffFiles[].diffPath for modified files only
    # Example paths: ".tmp/git-changes-analysis/.github-copilot-instructions.md.diff"
    #                ".tmp/git-changes-analysis/.github-prompts-pushall.prompt.md.diff"
    ```

    **File analysis by change type:**
    - **New files**: Listed in `files.new[]` - review actual file contents for understanding
    - **Modified files**: Listed in `files.modified[]` - diff files available showing changes
    - **Deleted files**: Listed in `files.deleted[]` - no content available (files removed)
    - **Renamed files**: Listed in `files.renamed[]` - diff files show rename and any content changes

    **Also gather branch information for decision making:**
    
    Read the `branch.current` field from `.tmp/git-changes-analysis/git-changes-analysis.json` to determine current branch.
    
    **CRITICAL**: Store this branch name as a variable that will be referenced throughout this workflow. When you see `[BRANCHNAME]` in subsequent steps, substitute it with the actual branch name you read from the JSON file.
    
2. **Branch decision point:** Based on the current branch information gathered in step 1, determine next steps.
    
    - **If on main branch:** Go to step 3 (Handle main branch protection)
    - **If on any other branch:** Go to step 4 (Confirm branch)

3. **Handle main branch protection:** You are on the main branch and need to handle branch protection.

    **First, create a proper branch name based on the changes analyzed in step 1:**
    - Analyze the changes to create a descriptive branch name (e.g., "feature/update-documentation", "fix/powershell-scripts", "enhancement/ui-improvements")
    - Use kebab-case format with appropriate prefix (feature/, fix/, enhancement/, etc.)
    - Keep the name concise but descriptive of the main changes

    Use the delay script to ask if the user wants to move changes to a new branch:

    ```pwsh
    ./.github/prompts/pushall-delay.ps1 -Warning "You are on the main branch. If you do nothing, I will create a branch for your changes with name:" -Message "[INSERT THE BRANCH NAME YOU CREATED]" -Delay 10
    ```

    - **Exit code 0 (user did not abort):** Create a new branch with the name you determined and move changes there. Store this new branch name as your `[BRANCHNAME]` variable for all subsequent steps. Then go to step 5 (Prepare commit message).
    - **Exit code 1 (user aborted):** Ask the user how they want to handle the branch situation and help them create or switch to the appropriate branch.

    **CRITICAL: Only if user aborted (exit code 1), after helping them with branch operations, always read the current branch name and validate the result:**
    
    ```pwsh
    git branch --show-current
    ```
    
    Verify this command succeeded and store the returned branch name as your `[BRANCHNAME]` variable for all subsequent steps. Then go to step 5 (Prepare commit message).

4. **Confirm branch:** You are not on the main branch. Confirm the user wants to continue on the current branch.

    ```pwsh
    ./.github/prompts/pushall-delay.ps1 -Warning "If you do nothing, your changes will be pushed on branch:" -Message "[BRANCHNAME]" -Delay 10
    ```

    - **Exit code 0 (user did not abort):** Continue to step 5 (Prepare commit message)
    - **Exit code 1 (user aborted):** Ask the user what's wrong and help the user fix the issue! This might include switching to a different branch.

    **CRITICAL: Only if user aborted (exit code 1), after helping them fix the issue, always read the current branch name and validate the result:**
    
    ```pwsh
    git branch --show-current
    ```
    
    Verify this command succeeded and store the returned branch name as your `[BRANCHNAME]` variable for all subsequent steps. Then go to step 5 (Prepare commit message).

5. **Prepare commit message:** Based on the changes analysis from step 1, prepare a structured commit message with bullet points that explains WHY you're making these changes.

    **Instructions:**

    **CRITICAL MINDSET SHIFT**: Focus on the PURPOSE and INTENT behind the changes, not just what was changed. Analyze how the changes impact the broader codebase and project goals.

    **CRITICAL CODEBASE IMPACT ANALYSIS**: Before writing the commit message, perform these analyses:
    
    1. **Dependency Analysis**: 
       - For modified files: Check what other files import, reference, or depend on the changed code
       - For new files: Identify what existing code will use or integrate with these new components
       - For deleted files: Verify what code previously depended on the removed functionality
    
    2. **Cross-Component Impact**:
       - Analyze how changes in one component affect related components (UI, API, database, configuration, etc.)
       - Check if changes require updates to documentation, tests, or deployment processes
       - Identify if changes affect user-facing features, developer workflows, or system behavior
    
    3. **Broader Context Understanding**:
       - Understand the project's architecture and how your changes fit within it
       - Consider the impact on maintainability, performance, security, or scalability
       - Think about whether changes improve functionality, fix issues, or enhance development experience

    **Commit Message Structure:**
    ```
    [Brief descriptive title - max 50 characters]

    Summary: [Brief explanation of what this commit does and why - max 50 words, prefer less]

    Implementation:
    • [Specific technical changes made to the codebase]
    • [Key files modified and how they were changed]
    • [Architecture or design patterns introduced or modified]
    ```

    **Context Requirements:**
    - Consider impact on user experience, development workflow, system performance, or project maintainability
    - Think about how changes affect the overall system architecture and component interactions
    - Focus on the value delivered to end users or developers working with the codebase

    **Example approach:**
    - Instead of: "Updated 3 files in the filtering system"
    - Think: "Why am I updating the filtering system? How does this affect other components? What's the broader impact?"
    - Focus on: "Enhanced system reliability by improving component interaction patterns"

    **CRITICAL**: After creating the structured commit message, write it directly to `.tmp/git-changes-analysis/commit-message.txt` file using this exact command format:
    
    ```pwsh
    pwsh -Command '@"
[Your actual commit message content here]
"@ | Out-File -FilePath ".tmp/git-changes-analysis/commit-message.txt" -Encoding utf8'
    ```
    
    Replace `[Your actual commit message content here]` with the commit message you prepared.

    **Example STRUCTURED commit message:**

    ```
    Improve developer workflow automation reliability

    Summary: Enhanced git workflow automation with better change analysis and structured commit generation to reduce developer friction and improve process reliability.

    Implementation:
    • Enhanced pushall.prompt.md with comprehensive change analysis and branch protection
    • Improved get-git-changes.ps1 with unified diff generation and file categorization
    • Added structured commit message templates and PowerShell command standardization
    ```

6. **Get user confirmation:** Use the delay script to confirm the commit message you prepared:

    ```pwsh
    ./.github/prompts/pushall-delay.ps1 -Warning "If you do nothing, your changes will be committed and pushed on branch '[BRANCHNAME]' with message:" -Message "" -MessageFile ".tmp/git-changes-analysis/commit-message.txt" -Delay 20
    ```
    
    **Note**: Replace `[BRANCHNAME]` in the command above with the actual branch name stored in your variable.

    - **Exit code 0 (user did not abort):** Continue with steps 7 and 8 to stage and commit
    - **Exit code 1 (user aborted):** Ask the user what's wrong and do not continue with the workflow

7. **Stage all changes:**

    ```pwsh
    git add .
    ```

8. **Commit with the confirmed message:**

    ```pwsh
    git commit -F ".tmp/git-changes-analysis/commit-message.txt"
    ```

9. **Check for remote changes and pull if needed:**

    Read the `branch.hasRemoteChanges` field from the git-changes-analysis.json file in the `.tmp/git-changes-analysis/` directory.
    
    **If hasRemoteChanges is true:**
    ```pwsh
    git pull --rebase
    ```
    
    **If hasRemoteChanges is false:**
    Skip the pull operation - no remote changes to pull. Continue to step 11 (Push changes).
    
    **If the field is missing or file is malformed:**
    Inform the user about the issue and ask if they want to attempt the pull anyway or skip it.

10. **Handle rebase interruptions:**

    **If the rebase completes successfully:** Continue to step 11 (Push changes)
    
    **If the rebase stops for any reason:**
    
    1. **Check rebase status:** Determine why the rebase stopped:
       ```pwsh
       git status
       ```
    
    2. **Handle different scenarios:**
    
       **a) Merge conflicts:**
       - Identify conflicted files (marked as "both modified" in git status)
       - Inform the user about the conflicts and ask them to resolve them:
         - Open each conflicted file in their editor
         - Look for conflict markers (`<<<<<<<`, `=======`, `>>>>>>>`)
         - Choose which version to keep or manually merge the changes
         - Remove all conflict markers and save the files
       - Wait for user confirmation that conflicts are resolved
       - Stage resolved files and continue:
         ```pwsh
         git add .
         git rebase --continue
         ```
    
       **b) Rebase paused but no issues:**
       - If git status shows "rebase in progress" but no conflicts or changes, simply continue:
         ```pwsh
         git rebase --continue
         ```
       - This happens when Git pauses for review or when commits apply cleanly but Git wants confirmation
    
       **c) Empty commits:**
       - If git specifically reports "No changes - did you forget to use 'git add'?" or "nothing to commit":
         ```pwsh
         git rebase --skip
         ```
       - This happens when a commit becomes empty during rebase (e.g., changes were already applied)
    
       **d) Other unexpected issues:**
       - For any other problems, STOP and ask the user how to proceed
       - Do NOT automatically skip commits or make assumptions
       - Common options: continue, skip (only if user confirms), or abort
    
       **e) If rebase needs to be aborted:**
       - User can choose to abort the rebase:
         ```pwsh
         git rebase --abort
         ```
       - This returns to the state before the rebase started
    
    3. **Repeat until rebase completes:** Continue handling interruptions until git rebase finishes successfully
    
    4. **Continue until rebase completes:** The rebase is complete when git no longer reports conflicts and returns to the normal prompt

11. **Push your changes:**

    ```pwsh
    git push
    ```

12. **Check for existing pull requests:**

    Use the GitHub MCP tools to check if there is already an open pull request for the current branch:
    
    ```
    List all open pull requests for this repository and check if any have the current branch as the head branch
    ```
    
    If there is an existing PR, go to step 13. If there is not, go to step 14.
    
13. **Handle existing PR:**

    - Inform the user that there's already an open PR for this branch
    - The new commits have been automatically added to the existing PR by the push operation
    - Display the existing PR information (title, number, URL)
    - Use the delay script to ask about updating the PR description:

    ```pwsh
    ./.github/prompts/pushall-delay.ps1 -Warning "The commits have been automatically added to the existing PR. If you do nothing, I will update the PR description to reflect the new changes." -Delay 10
    ```

    - **Exit code 0 (user did not abort):** 
      1. Review what is currently in the PR description using the GitHub MCP tools
      2. Analyze if the new changes impact what is described
      3. If the new changes are significant, update the description or add an extra section describing the new changes
      4. Update the pull request title if needed to reflect the expanded scope
      5. Use the GitHub MCP tools to update the pull request with the new information
      6. Then go to step 15
    - **Exit code 1 (user aborted):** Go to step 15

14. **Handle new PR:**

    - Use the delay script to ask about creating a pull request:

    ```pwsh
    ./.github/prompts/pushall-delay.ps1 -Warning "If you do nothing, I will create a pull request for the changes you just pushed." -Delay 10
    ```

    - **Exit code 0 (user did not abort):** 
      1. Create a pull request using the GitHub MCP tools with:
         - Descriptive title based on the commit message and changes
         - Detailed description of changes and their purpose
         - Head branch set to your current branch
         - Base branch set to the target branch (usually main)
      2. Display the new PR information (title, number, URL)
      3. Then go to step 15
    - **Exit code 1 (user aborted):** The workflow is complete.

15. **Request Optional Copilot review:**

    Use the GitHub MCP tools to check if Copilot has already reviewed the PR and use the appropriate warning message:
    
    **If no Copilot review exists:**
    ```pwsh
    ./.github/prompts/pushall-delay.ps1 -Warning "If you do nothing, I will request a Copilot code review for this pull request" -Delay 05
    ```
    
    **If Copilot has already reviewed:**
    ```pwsh
    ./.github/prompts/pushall-delay.ps1 -Warning "Copilot already reviewed this pull request. If you do nothing, I will request a new review." -Delay 10
    ```

    - **Exit code 0 (user did not abort):** Use the GitHub MCP tools to request automated feedback from Copilot
    - **Exit code 1 (user aborted):** Leave the PR without Copilot review request
    - The workflow is complete

## Summary of the workflow

1. Verify current branch, capture comprehensive changes analysis, analyze all changes, and gather branch information
2. Make branch decision based on current branch information
3. Handle main branch protection (if on main branch)
4. Confirm branch is correct (if not on main branch)
5. Prepare descriptive commit message based on changes analysis and write to file
6. Get user confirmation for the commit message and branch
7. Stage all changes
8. Commit changes using the prepared message file
9. Check for remote changes and pull with rebase if needed
10. Handle any rebase interruptions (conflicts, empty commits, etc.)
11. Push changes to the remote branch
12. Check for existing pull requests using GitHub MCP tools
13. Update existing PR description if one exists (optional)
14. Create new PR if none exists (optional)
15. Check Copilot review status and request review (optional)

This process ensures your local changes are committed, the latest remote changes are integrated, all conflicts are resolved, your commit history remains clean and linear, proper branch protection is respected, existing PRs are intelligently updated with new commits, and Copilot code reviews can be requested for automated feedback based on current review status.