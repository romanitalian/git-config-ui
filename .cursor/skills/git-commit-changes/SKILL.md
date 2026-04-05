---
name: git-commit-changes
description: Stages changes with git add and creates a commit on the current branch with an English title and body derived from git status and diff. Use when the user asks to commit, stage and commit, save changes to git, or wants a commit message from current changes.
---

# Git commit from working tree changes

## When to use

Apply when the user wants to **record current work in git** on the **current branch**: stage files and commit with a **clear, accurate message in English** (subject + optional body).

Do **not** use if the user forbids commits, asks only for a message without committing, or requires a specific team template—follow their override.

## Workflow

1. **Inspect state** (repo root):
   - `git status -sb`
   - `git diff` (unstaged)
   - `git diff --cached` (if something already staged)
   - If needed: `git diff --stat` for a quick overview

2. **Decide scope**:
   - Default: stage **all** changes the user implied (`git add -A` or explicit paths from status).
   - If the user names specific files or hunks, stage only those.

3. **Write the commit message (English only)**:
   - **Subject line**: imperative mood, ≤50 characters when possible; summarize *what* changed (e.g. `Fix profile editor validation for local repos`).
   - **Body** (optional but preferred for non-trivial diffs): blank line after subject, then bullet points or short paragraphs explaining *why* or *important details* (not a file list dump—`git show` already shows files).
   - Align with the actual diff; do not claim features not present in the staged changes.

4. **Commit**:
   - `git add …` then `git commit -m "subject" -m "body"`  
   - For a multiline body, use multiple `-m` flags (each becomes a paragraph) or a heredoc / temporary file if the environment allows.

5. **Confirm**: show the user the short hash and subject (`git log -1 --oneline`).

## Message style (default)

- Prefer **Conventional Commits** when it fits: `feat(scope): …`, `fix: …`, `refactor: …`, `chore: …`, `docs: …`.
- If scope is unclear, a plain imperative subject is fine.

## Examples

**Small fix**

- Subject: `Fix duplicate repo path check after profile reload`
- Body: `Normalize paths before comparing so Save stays consistent with Git config.`

**Feature**

- Subject: `feat(profile): add git init for non-repository folders`
- Body: `Disable Save until the work tree is a Git repo; offer Initialize when the folder is writable.`

## Safety

- Never run `git commit` **without** reviewing `git status`/`git diff` unless the user explicitly asked to commit everything blindly.
- If there are **no changes** to commit, say so and do not create an empty commit unless the user asks for `--allow-empty`.
