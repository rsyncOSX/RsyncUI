## 1. Work on your branch — stage and commit changes

```bash
# Stage all changes
git add .

git diff --staged | claude -p "Write a concise git commit message for this diff"
alias gcm='git diff --staged | claude -p "Write a short conventional commit message. Output only the message, nothing else."'

# Commit (GPG signed automatically based on your config)
git commit -m "your message"
```

Repeat these two commands as many times as needed while working on your branch.

## 2. Push branch to GitHub

```bash
git push origin feature/my-branch
```

## 3. Pull latest updates from GitHub (no merge commits)

```bash
git pull --rebase origin feature/my-branch
```

## 4. When happy — merge branch into main and push

```bash
# Switch to main and get latest
git checkout main
git pull --rebase origin main

# Rebase your branch onto main
git checkout feature/my-branch
git rebase main

# Switch back to main and fast-forward merge (no merge commit)
git checkout main
git merge --ff-only feature/my-branch

# Push updated main to GitHub
git push origin main
```

## 5. Cleanup — delete branch after merging

```bash
# Delete locally
git branch -d feature/my-branch

# Delete on GitHub
git push origin --delete feature/my-branch
```
