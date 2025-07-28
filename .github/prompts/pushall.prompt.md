---
mode: "agent"
description: "Step-by-step git workflow for committing, rebasing, and pushing changes with branch protection, comprehensive change analysis, and optional PR creation"
model: "Claude Sonnet 4"
---

**🚨 ABSOLUTE CRITICAL REQUIREMENT**: Execute EXACTLY these steps in EXACT order specified by the checkpoints. Do NOT improvise, optimize, skip, merge or deviate in ANY other way from the workflow. It does not matter if you use a lot of tokens!

**🚨 CRITICAL PROMPT SCOPE**: All instructions, restrictions, and requirements in this prompt file ONLY apply when this specific prompt is being actively executed via the `/pushall` command or equivalent prompt invocation. These rules do NOT apply when editing, reviewing, or working with this file outside of prompt execution context. When working with this file in any other capacity (editing, debugging, documentation, etc.), treat it as a normal markdown file and ignore all workflow-specific instructions.

**CRITICAL**: Except for any variable replacement you might need to do, execute the provided code/script blocks exactly as-is! They are not examples, they are your instructions.
**CRITICAL**: Exclusivly use the GitHub MCP tools for GitHub related actions, such as listing and creating pull and updating pull requests requests. Or listing and requesting code reviews. **Never** use `gh`
**CRITICAL**: ALL powershell scripts should be executed with the 'pwsh' command in front. So never `@"test" | Out-File`, always `pwsh @"text" | Out-File`. And never `pwsh ./.github/prompts/script.ps1`, always `pwsh ./.github/prompts/script.ps1`. In short, do NOT remove the `pwsh` part from code blocks.
**CRITICAL**: Remember escaping in PowerShell happens with a backtick instead of a backslash.
**CRITICAL**: If you need to make a choice and the current workflow steps do not provide a clear answer or instruction, ALWAYS ask the user what to do instead of making assumptions or guessing.

**CRITICAL STEP VALIDATION REQUIREMENTS**: After each step, you must:
- Confirm the step completed successfully and you followed all instructions. If not, go back and do what you missed.
- State which step you're moving to next  
- Verify all required outputs exist before proceeding
- Use the checkpoint format: "✅ Step [X] completed successfully. Moving to Step [Y]."

**CRITICAL VARIABLE TRACKING**: Throughout this workflow, maintain these variables:
- `[BRANCHNAME]`: Current branch name (from step 1 analysis)
- Update this section when variables change

**CRITICAL ERROR HANDLING**: If any step fails:
- STOP immediately
- Report the exact error
- Ask user how to proceed
- Do NOT continue to next step

# Step-by-Step Git Commit, Rebase, Conflict Resolution, and Push Workflow

0. **Make a checklist for all critical instructions**
   This file contains a lot of critical instructions. Make a checklist for yourself and give me the summary BEFORE continueing with step 1.

   **CRITICAL**: Use this checklist internally to validate you did everything correct.

1. **Check current branch and analyze changes:**

    ```pwsh
    pwsh ./.github/prompts/get-git-changes.ps1
    ```

    This script captures comprehensive git changes analysis, including git status, individual diff files, and branch information, saving it to `.tmp/git-changes-analysis/` directory. The main analysis data is in `git-changes-analysis.json` and individual `.diff` files are created for each changed file.
    
    After the script completes, check if the file exists:
    
    ```pwsh
    pwsh -Command 'if (-not (Test-Path ".tmp/git-changes-analysis/git-changes-analysis.json")) { throw "Analysis file was not created. Script may have failed." }'
    ```
    
    **After successful verification, analyze the changes:**
    
    - Review the `summary` object to understand the scope of changes (totalFiles, new, modified, deleted, renamed)
    - Check the `files` object for categorized file lists (new, modified, deleted, renamed arrays)  
    - Use exact `diffPath` values from `diff.diffFiles[]` array in the JSON - do NOT assume filename formats
    - **New files**: Listed in `files.new[]` - Read the new file contents directly, because there are no diff available since they're new
    - **Modified files**: Listed in `files.modified[]` - Examine the individual `.diff` files using the paths from JSON for detailed understanding of what changed
    - **Deleted files**: Listed in `files.deleted[]` -  No content to review since they've been removed
    - **Renamed files**: Listed in `files.renamed[]` - Diff files show rename and any content changes. Follow the modified files instructions for these.  
    - Check `branch.current` for the current branch name
    - Check `branch.remote.exists` to know if the branch already exists in the remote server
    - Check `branch.remote.hasUpdates` to know if the remote branch has updates we need to pull in
    - Check `branch.main.hasUpdates` to know if remote main has updates we need to rebase against
    - Review `changes.fileDetails` for per-file change analysis with change types and git status codes
    - Check `diff.stats` and `diff.filesChanged` for overall diff statistics
    - If any of the properties are missing or appear invalid, let the user know and do NOT continue!

    **CRITICAL**: Store `branch.current` as a variable that will be referenced throughout this workflow. When you see `[BRANCHNAME]` in subsequent steps, substitute it with the actual branch name you read from the JSON file.
    
    **CHECKPOINT**: After completing analysis, state: "✅ Step 1 completed successfully. Current branch: [BRANCHNAME]. Moving to Step 2."
    
2. **Branch decision point:** Based on the current branch information gathered in step 1, determine next steps.
    
    **CHECKPOINT**: State either:
    - "✅ Step 2 completed successfully. On main branch. Moving to Step 3 to handle main branch protection steps."
    - "✅ Step 2 completed successfully. On feature branch [BRANCHNAME]. Moving to Step 6 to confirm the current branch."

3. **Handle main branch protection:** You are on the main branch and need to handle branch protection.

    First, create a proper branch name based on the changes analyzed in step 1:
    - Analyze the changes to create a descriptive branch name (e.g., "feature/update-documentation", "fix/powershell-scripts", "enhancement/ui-improvements")
    - Use kebab-case format with appropriate prefix (feature/, fix/, enhancement/, etc.)
    - Keep the name concise but descriptive of the main changes
    - Set variable: [BRANCHNAME] = your created branch name

    Then use the delay script to ask if the user wants to move changes to a new branch:

    ```pwsh
    pwsh ./.github/prompts/pushall-delay.ps1 -Warning "You are on the main branch. If you do nothing, a branch will be created for you with the name:" -Message "[BRANCHNAME]" -Delay 10
    ```

    **CHECKPOINT**: Based on exit code, state either:
    - **Exit code 0 (user did not abort):** "✅ Step 3 completed successfully. User accepted branch creation for [BRANCHNAME]. Moving to Step 4."
    - **Exit code 1 (user aborted):** "✅ Step 3 completed successfully. User aborted branch creation. Moving to Step 5."

4. **Create new branch from main:** Move changes from main to a new branch.

    First, soft reset any existing commits on main to preserve all changes as uncommitted:

    ```pwsh
    git reset --soft HEAD~$(git rev-list --count HEAD ^origin/main)
    ```
    
    Then create and switch to the new branch:

    ```pwsh
    git checkout -b [INSERT THE BRANCH NAME YOU CREATED]
    ```
    
    **CRITICAL**: Store `[INSERT THE BRANCH NAME YOU CREATED]` as your `[BRANCHNAME]` variable for all subsequent steps.

    **CHECKPOINT**: "✅ Step 4 completed successfully. Created and switched to branch [BRANCHNAME]. Moving to Step 7 (skipping steps 5 and 6)."

5. **Handle branch creation abort:** Handle the case when user aborts branch creation from main.

    Ask the user how they want to handle the branch situation and help them create or switch to the appropriate branch.

    **CRITICAL**: After helping them with branch operations, always read the current branch name and validate the result:
    
    ```pwsh
    git branch --show-current
    ```
    
    Verify this command succeeded and store the returned branch name as your `[BRANCHNAME]` variable for all subsequent steps.

    **CHECKPOINT**: "✅ Step 5 completed successfully. Issue resolved, now on branch [BRANCHNAME]. Moving to Step 7."

6. **Confirm branch:** You are not on the main branch. Confirm the user wants to continue on the current branch.

    ```pwsh
    pwsh ./.github/prompts/pushall-delay.ps1 -Warning "If you do nothing, your changes will be pushed on branch:" -Message "[BRANCHNAME]" -Delay 10
    ```

    **CHECKPOINT**: Based on exit code, state either:
    - **Exit code 0 (user did not abort):** "✅ Step 6 completed successfully. User confirmed working on branch [BRANCHNAME]. Moving to Step 7."
    - **Exit code 1 (user aborted):** Help the user fix the issue (switching branches, etc.), then read current branch name and validate the result:
    
    ```pwsh
    git branch --show-current
    ```
    
    Verify this command succeeded and store the returned branch name as your `[BRANCHNAME]` variable for all subsequent steps, then state: "✅ Step 6 completed successfully. Issue resolved, now on branch [BRANCHNAME]. Moving to Step 7."
    
7. **Prepare commit message:** Based on the changes analysis from step 1, prepare a structured commit message:

    **Commit Message Structure:**
    - For the summary, focus on the PURPOSE and INTENT behind the changes, not just what was changed. The implementation can be more technical.
    - Use bullet points that explains WHY you're making these changes.

    ```
    [Brief descriptive title - max 50 characters]

    Summary: [Brief explanation of what this commit does and why - max 50 words, prefer less]

    Implementation:
    • [Specific technical changes made to the codebase]
    • [Key files modified and how they were changed]
    • [Architecture or design patterns introduced or modified]
    ```

    **Example STRUCTURED commit message:**

    ```
    Improve developer workflow automation reliability

    Summary: Enhanced git workflow automation with better change analysis and structured commit generation to reduce developer friction and improve process reliability.

    Implementation:
    • Enhanced pushall.prompt.md with comprehensive change analysis and branch protection
    • Improved get-git-changes.ps1 with unified diff generation and file categorization
    • Added structured commit message templates and PowerShell command standardization
    ```

    **CRITICAL**: After creating the structured commit message, write it directly to `.tmp/git-changes-analysis/commit-message.txt` file using this exact command format:
    
    ```pwsh
    pwsh -Command '@"
[Your actual commit message content here]
"@ | Out-File -FilePath ".tmp/git-changes-analysis/commit-message.txt" -Encoding utf8'
    ```
    
    Replace `[Your actual commit message content here]` with the commit message you prepared.

    **CHECKPOINT**: "✅ Step 7 completed successfully. Commit message prepared and saved. Moving to Step 8."

8. **Get user confirmation:** Use the delay script to confirm the commit message you prepared:

    ```pwsh
    pwsh ./.github/prompts/pushall-delay.ps1 -Warning "If you do nothing, your changes will be committed and pushed on branch '[BRANCHNAME]' with message:" -Message "" -MessageFile ".tmp/git-changes-analysis/commit-message.txt" -Delay 20
    ```
    
    **CHECKPOINT**: Based on exit code, state either:
    - **Exit code 0 (user did not abort):** "✅ Step 8 completed successfully. User confirmed commit message. Moving to Step 9."
    - **Exit code 1 (user aborted):** "❌ Step 8 aborted by user. Asking what's wrong and stopping workflow."

9. **Stage all changes:**

    ```pwsh
    git add .
    ```

    **CHECKPOINT**: "✅ Step 9 completed successfully. All changes staged. Moving to Step 10."

10. **Commit with the confirmed message:**

    ```pwsh
    git commit -F ".tmp/git-changes-analysis/commit-message.txt"
    ```

    **CHECKPOINT**: "✅ Step 10 completed successfully. Changes committed with prepared message. Moving to Step 11."

11. **Synchronize with remote branch:** After committing, ensure your branch is synchronized with the remote branch to get the latest changes.

    Read the `branch.remote.exists` and `branch.remote.hasUpdates` fields from the git-changes-analysis.json file in the `.tmp/git-changes-analysis/` directory.
    
    **If branch.remote.exists is false OR branch.remote.hasUpdates is false:**
    Skip the remote pull operation.
    
    **If branch.remote.exists is true and branch.remote.hasUpdates is true:**

    ```pwsh
    git pull --rebase
    ```
    
    If the rebase stops for any reason, use the [Branch Rebase Instructions](#branch-rebase-instructions) section below.

    **CHECKPOINT**: "✅ Step 11 completed successfully. Remote branch synchronization complete. Moving to Step 12."
    
12. **Synchronize with main branch:** Ensure your branch maintains a clean history by rebasing onto main.

    Read the `branch.main.hasUpdates` field from the git-changes-analysis.json file in the `.tmp/git-changes-analysis/` directory.
    
    **If branch.main.hasUpdates is false:**
    Your branch is already up-to-date with main.
    
    **If branch.main.hasUpdates is true:**

    ```pwsh
    git rebase main
    ```
    
    If the rebase stops for any reason, use the [Branch Rebase Instructions](#branch-rebase-instructions) section below.

    **CHECKPOINT**: "✅ Step 12 completed successfully. Main branch synchronization complete. Moving to Step 13."

13. **Push your changes:**

    Use the `branch.remote.exists` field to determine the appropriate push command.

    **If branch.remote.exists is false (new branch):**

    ```pwsh
    git push --set-upstream origin [BRANCHNAME]
    ```
    
    **If branch.remote.exists is true (existing branch):**

    ```pwsh
    git push
    ```
    
    **CHECKPOINT**: "✅ Step 13 completed successfully. Changes pushed to remote branch [BRANCHNAME]. Moving to Step 14."
    
14. **Ask user about pull request creation/updating:**

    Use the delay script to ask the user if they want to proceed with pull request operations:

    ```pwsh
    pwsh ./.github/prompts/pushall-delay.ps1 -Warning "If you do nothing, the system will start the work for creating or updating a Pull Request." -Delay 30
    ```

    **CHECKPOINT**: Based on exit code, state either:
    - **Exit code 0 (user did not abort):** "✅ Step 14 completed successfully. User wants to proceed with PR operations. Moving to Step 15."
    - **Exit code 1 (user aborted):** "✅ Step 14 completed successfully. User aborted PR operations. Workflow is complete."

15. **Comprehensive analysis of all changes between current remote branch and remote main:**
    
    Read the `branch.remote.exists` field from `.tmp/git-changes-analysis/git-changes-analysis.json` to determine the comparison approach.
    
    **If branch.remote.exists is true (remote branch exists):**
    
    ```pwsh
    pwsh ./.github/prompts/get-git-changes.ps1 -CompareRemoteWithMain
    ```
    
    **If branch.remote.exists is false (no remote branch):**

    ```pwsh
    pwsh ./.github/prompts/get-git-changes.ps1 -CompareLocalWithMain
    ```
    
    **Investigation:**
    Both commands will generate a new analysis file containing all files changed compared to main branch.
    
    **Investigation Focus Points:**
    - **File Change Patterns**: What types of files were modified? (code, docs, config, tests, assets)
    - **Directory Impact**: Which parts of the codebase were affected? Are changes localized or widespread?
    - **Change Types**: What kinds of modifications? (new features, bug fixes, refactoring, documentation updates)
    - **Scope Assessment**: How extensive are the changes? Are they surface-level or architectural?
    
    **Deep Investigation Options:**
    For comprehensive understanding, use GitHub MCP tools to gather additional context:
    
    **Historical Context:**
    - Use `mcp_github_get_file_contents` with specific commit SHAs to see previous versions of heavily modified files
    - Understand what functionality existed before and how implementation approaches evolved
    - Determine if changes represent refactoring, new functionality, or architectural shifts
    
    **Key Questions to Answer:**
    - What is the primary purpose of this branch? (feature addition, bug fix, refactoring, etc.)
    - How many commits are involved and what time range do they span?
    - Are there any concerning patterns in the changes?
    - Do the changes affect core functionality or are they peripheral?
    - Are there dependencies between modified files that suggest architectural impact?
    
    **CRITICAL:** If the git-changes-analysis.json doesn't provide sufficient context for understanding the changes, you should investigate the broader codebase. The entire workspace should be considered available for analysis to provide complete context for the changes being made.

    **CHECKPOINT**: "✅ Step 15 completed successfully. Comprehensive change analysis complete. Moving to Step 16."

16. **Analyze recent repository activity patterns:**

    Determine development velocity, change types, active focus areas:

    Use mcp_github_list_pull_requests with state=closed, sort=updated, direction=desc:
    - Get 5-10 recent merged PRs
    - Look for PR title patterns, types of changes, review patterns
    - Identify common development workflows and conventions
    
    Use mcp_github_list_pull_requests with state=open:
    - Check currently active development areas
    - Identify potential conflicts or related work

    **CHECKPOINT**: "✅ Step 16 completed successfully. Repository activity patterns analyzed. Moving to Step 17."

17. **Understand current project priorities and pain points:**

    Identify current pain points, requested features, active problem areas:

    Use mcp_github_list_issues with state=open, sort=updated:
    - Get 5-10 recent issues
    - Categorize by type (bugs, features, improvements, questions)
    - Look for frequently mentioned components or problems
    
    Use mcp_github_list_issues with state=closed, sort=updated:
    - Get 5 recently closed issues
    - See what types of problems are being actively resolved

    **CHECKPOINT**: "✅ Step 17 completed successfully. Project priorities and pain points analyzed. Moving to Step 18."

18. **Examine recent mainline development patterns:**

    Understand release cadence, development stability, recent focus areas:

    Use mcp_github_list_commits on main branch with recent timeframe:
    - Get 20-30 recent main branch commits
    - Analyze commit message patterns and frequency
    - Look for release cycles, hot fixes, feature development patterns

    **CHECKPOINT**: "✅ Step 18 completed successfully. Mainline development patterns examined. Moving to Step 19."

19. **Gather essential repository context:**
    
    Read key documentation and configuration files from the local workspace to understand project structure and conventions:
    
    **Core project files to analyze (if they exist):**
    - README.md (project purpose, setup, key features)
    - docs/ directory contents (development guidelines, architecture documentation)
    - Configuration files (package.json, requirements.txt, _config.yml, etc.)
    - Dependency files (Gemfile, requirements.txt, package-lock.json, etc.)
    - .github/ directory structure (workflows, templates, automation)
    
    **Use standard workspace tools to gather context:**
    - Use `read_file` to examine README.md for project overview
    - Use `list_dir` to check for documentation directories (docs/, .github/)
    - Use `read_file` to review common configuration files:
      - package.json, requirements.txt, Gemfile
      - _config.yml, pyproject.toml, Cargo.toml
      - Any other relevant project configuration files
    - Use `file_search` with patterns like "*.md", "*.json", "*.yml" to discover key files
    
    **Establish understanding of:**
    - Project architecture and technology stack
    - Development conventions and patterns
    - Build and deployment processes
    - Documentation structure and guidelines

    **CHECKPOINT**: "✅ Step 19 completed successfully. Essential repository context gathered. Moving to Step 20."

20. **Analyze changes for effective PR communication:**
    
    **CRITICAL**: Focus your analysis on creating an effective PR title and description that clearly communicates WHAT was done, WHY it was necessary, and HOW it changes functionality.
    **CRITICAL**: At the end of this step you'll synthesize a title and description for the PR. Store these for yourself. Do not share the full content with the user and do not write it to a file.
    
    **Core Analysis Framework:**
    
    **1. WHAT was done (Functional Changes):**
    - What specific functionality was added, modified, or removed?
    - What user-facing or developer-facing capabilities changed?
    - What systems, components, or processes were affected?
    
    **2. WHY it was necessary (Problem & Context):**
    - What problem or need drove these changes?
    - What pain points were addressed?
    - How do these changes align with recent repository activity (from steps 16-18)?
    - What value do they provide to the project and its users?
    
    **3. HOW functionality changes (Old vs New):**
    - What was the previous behavior or state?
    - What is the new behavior or state?
    - What workflows or experiences are different now?
    - What are the key technical improvements or architectural changes?
    
    **Change Classification:**
    Categorize the primary change type:
    - **New Feature**: What new capability was added?
    - **Bug Fix**: What issue was resolved and how?
    - **Improvement**: What was enhanced and what's better now?
    - **Refactoring**: What structure was improved and why?
    - **Documentation**: What knowledge was added or updated?
    - **Configuration**: What setup or deployment changes were made?
    
    **Impact Assessment:**
    - **User Impact**: How will end users experience these changes?
    - **Developer Impact**: How will developers work differently?
    - **System Impact**: What internal processes or behaviors changed?
    - **Quality Impact**: How do these changes improve code quality, performance, or maintainability?
    
    **Key Review Focus Areas:**
    Identify what reviewers should pay special attention to:
    - Complex logic or algorithmic changes
    - API or interface modifications
    - Performance-critical sections
    - Security-related changes
    - Breaking changes or migration requirements
    
    **Prepare for PR Creation:**
    Synthesize your analysis into:
    - A clear, descriptive PR title (focused on the primary functional change)
    - A comprehensive PR description that tells the complete story: problem → solution → impact

    **CHECKPOINT**: "✅ Step 20 completed successfully. PR communication analysis complete. Moving to Step 21."

21. **Check for existing pull requests:** 
    
    Read the `branch.remote.exists` field from `.tmp/git-changes-analysis/git-changes-analysis.json` to determine if there can be existing pull requests.
    
    **If branch.remote.exists is true (remote branch exists):**
    
    - Use the GitHub MCP tools to check if there is already an open pull request for the current branch.
    
    **If branch.remote.exists is false (no remote branch):**

    - Do nothing, because there is no remote branch and there can be no pull request.
   
    **CHECKPOINT**: "✅ Step 21 completed successfully. Existing PR check complete. Moving to Step 22."

22. **Update existing PR or create new PR:**

    Use the exact PR title and description you prepared in step 20 based on your comprehensive analysis to update or create a pull request.

    **If there is an existing PR (from step 21):**
    - Update the pull request title and description.
    - Do not display the updated PR information, just share the title, the PR number and the link.

    **If there is no existing PR:**
    - Create a pull request using the GitHub MCP tools.
    - Set head branch to your current branch and base branch to main
    - Do not display the updated PR information, just share the title, the PR number and the link.

    **CHECKPOINT**: "✅ Step 22 completed successfully. PR created/updated with prepared title and description. Moving to Step 23."

23. **Request Optional Copilot review:**

    Use the GitHub MCP tools to check if Copilot has already reviewed the PR and use the appropriate warning message:
    
    **If no Copilot review exists:**

    ```pwsh
    pwsh ./.github/prompts/pushall-delay.ps1 -Warning "If you do nothing, a Copilot code review will be requested for this pull request" -Delay 5
    ```
    
    **If Copilot has already reviewed:**

    ```pwsh
    pwsh ./.github/prompts/pushall-delay.ps1 -Warning "Copilot already reviewed this pull request. If you do nothing, a new review will be requested." -Delay 10
    ```

    **CHECKPOINT**: Based on exit code, state either:
    - **Exit code 0 (user did not abort):** Use the GitHub MCP tools to request automated feedback from Copilot, then state: "✅ Step 23 completed successfully. Copilot review requested. Workflow is complete."
    - **Exit code 1 (user aborted):** "✅ Step 23 completed successfully. User skipped Copilot review. Workflow is complete."

## Branch Rebase Instructions

These are reusable instructions for rebasing onto any target branch (main, remote branch, etc.) to keep branches synchronized and minimize conflicts.

**Pre-Rebase Setup:**

- Ensure all current changes are staged and committed before starting rebase
- Note the current branch name for reference
- Identify the target branch you're rebasing onto

**Execute Rebase:**
Use the appropriate rebase command based on your situation:

- For main branch: `git rebase main`
- For remote branch updates: `git pull --rebase` (already in progress)
- For continuing interrupted rebase: `git rebase --continue`

**Handle Rebase Results:**

If the rebase completes successfully, the branch is now synchronized with the target branch. Continue with the next step in your workflow.
If the rebase stops for any reason, follow these 4 steps:

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
4. **Rebase completion:** The rebase is complete when git no longer reports conflicts and returns to the normal prompt

**Post-Rebase Validation:**
After successful rebase completion, the branch is now synchronized with the target branch and ready to continue with the workflow.
