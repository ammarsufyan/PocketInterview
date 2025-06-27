# Git Branch Merge Instructions

## Step 1: Switch to the supabase branch
```bash
git checkout supabase
```

## Step 2: Pull the latest changes from ammar/cv-extractor
```bash
git pull origin ammar/cv-extractor
```

## Alternative: Merge the branch instead of pull
```bash
git merge ammar/cv-extractor
```

## Step 3: Resolve any merge conflicts (if they occur)
If there are conflicts, Git will show you which files have conflicts. Edit those files to resolve the conflicts, then:

```bash
git add .
git commit -m "Merge ammar/cv-extractor into supabase branch"
```

## Step 4: Push the merged changes
```bash
git push origin supabase
```

## If you want to see what changes would be merged first:
```bash
git diff supabase..ammar/cv-extractor
```

## To see the commit history of the cv-extractor branch:
```bash
git log ammar/cv-extractor --oneline
```