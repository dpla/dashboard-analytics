---
name: deploy-analytics-dashboard
description: >
  Deploys a pull request to the live analytics-dashboard.dp.la site (dpla/dashboard-analytics repo).
  ALWAYS use this skill — never run deploy steps manually — whenever the user mentions deploying,
  shipping, pushing, merging+deploying, or releasing changes for the analytics dashboard. Trigger
  phrases include: "deploy PR 201", "ship this to analytics dashboard", "push PR X to production",
  "deploy to analytics-dashboard.dp.la", "kick off a deployment", "merge the PR and deploy",
  "deploy the analytics dashboard", or simply "deploy" in the context of the dashboard-analytics repo,
  even without a PR number. IMPORTANT: The ECR image must be built before the PR is merged —
  never merge first. This skill enforces the correct order.
---

## Overview

This skill deploys a PR from `dpla/dashboard-analytics` to `https://analytics-dashboard.dp.la` using a
4-step pipeline: ECR image build → squash merge → CodePipeline → verification.

**Total typical duration: 10–12 minutes.**

The PR number comes from the args passed to this skill, or from context if the user mentioned one in the conversation. If neither is available, ask for it before proceeding.

---

## Step 1: Look up the PR branch

```bash
gh pr view <PR_NUMBER> --repo dpla/dashboard-analytics --json headRefName,state,title
```

Confirm the PR is open. If it's already merged or closed, stop and tell the user.

Print: `📋 PR #<N>: "<title>" on branch <branch>`

**Pre-flight: verify the branch contains all of main's commits.**

The PR branch may have been created via cherry-pick rather than branching from current main, meaning it could be missing commits already merged to main. Check:

```bash
git fetch origin && git log --oneline origin/main ^origin/<branch> | head -10
```

If this prints any commits, the branch is **missing** those commits from main. Stop and warn:
> "⚠️ Branch `<branch>` is missing N commits that are already on main (e.g. `<title>`). If deployed as-is, those changes will be absent from the image. Rebase the branch onto main before proceeding."

Only proceed once the branch contains all of main's commits (i.e. the above command prints nothing, or the only difference is the PR's own new commits).

Print: `✅ Branch is up to date with main`

---

## Step 2: Trigger the Build ECR GitHub Action

The ECR image **must** be built before CodePipeline runs — CodePipeline uses the `:latest` ECR tag, so if the image isn't fresh, it will deploy stale code.

```bash
gh workflow run 40080852 --ref <branch> --repo dpla/dashboard-analytics
```

Then find the run ID that was just created (it takes a few seconds to appear):

```bash
sleep 5 && gh run list --workflow=40080852 --repo dpla/dashboard-analytics --limit 1 --json databaseId,status --jq '.[0].databaseId'
```

Watch it until completion:

```bash
gh run watch <RUN_ID> --repo dpla/dashboard-analytics
```

Print progress as steps complete. If the run fails, stop and report the failure — do not proceed to merge.

Print: `✅ ECR image built successfully`

---

## Step 3: Squash merge and delete branch

```bash
gh pr merge <PR_NUMBER> --squash --delete-branch --repo dpla/dashboard-analytics
```

This deletes the remote branch. Also clean up the local branch (squash merges require force-delete since the commit SHA differs):

```bash
cd /Users/dominic/Documents/GitHub/dashboard-analytics
git fetch origin --prune
git checkout main
git branch -D <branch>
```

Print: `✅ PR #<N> squash merged, branch deleted (remote + local)`

---

## Step 4: Start CodePipeline

The pipeline should auto-trigger within ~60 seconds of the merge via the GitHub webhook. Note the current time, wait 60 seconds, then check if a new execution appeared:

```bash
aws codepipeline list-pipeline-executions \
  --pipeline-name analytics-dashboard-pipeline --max-results 1 \
  --query 'pipelineExecutionSummaries[0].{id:pipelineExecutionId,status:status,startTime:startTime}' \
  --output json
```

If the most recent execution's `startTime` is after the merge (i.e. it started within the last ~90 seconds), the webhook fired — use that execution ID. If not, start it manually:

```bash
aws codepipeline start-pipeline-execution --name analytics-dashboard-pipeline
```

Save the `pipelineExecutionId` from whichever source provided it.

Print: `🚀 CodePipeline started (execution: <id>)`

---

## Step 5: Monitor the pipeline

Poll every 15 seconds until the pipeline succeeds or fails.

Start the Bash call with `while true` directly (no preceding variable assignment)
so it matches the `Bash(while true*)` permission pattern. Embed the execution ID
inline. Use `pipeline_status` (not `status` — that's a reserved variable in zsh):

```bash
while true; do
  pipeline_status=$(aws codepipeline get-pipeline-execution \
    --pipeline-name analytics-dashboard-pipeline \
    --pipeline-execution-id "<EXECUTION_ID>" \
    --query 'pipelineExecution.status' --output text)
  stages=$(aws codepipeline get-pipeline-state \
    --name analytics-dashboard-pipeline \
    --query 'stageStates[*].{stage:stageName,status:latestExecution.status}' \
    --output json)
  src=$(echo "$stages" | python3 -c "import sys,json; s=json.load(sys.stdin); print(next((x['status'] for x in s if x['stage']=='Source'), '—'))" 2>/dev/null || echo "—")
  bld=$(echo "$stages" | python3 -c "import sys,json; s=json.load(sys.stdin); print(next((x['status'] for x in s if x['stage']=='Build'), '—'))" 2>/dev/null || echo "—")
  prd=$(echo "$stages" | python3 -c "import sys,json; s=json.load(sys.stdin); print(next((x['status'] for x in s if x['stage']=='Production'), '—'))" 2>/dev/null || echo "—")
  ts=$(date '+%H:%M:%S')
  if [ "$pipeline_status" = "Succeeded" ]; then
    echo "✅ [$ts] Source: $src | Build: $bld | Production: $prd"; break
  elif [ "$pipeline_status" = "Failed" ] || [ "$pipeline_status" = "Stopped" ]; then
    echo "❌ [$ts] Pipeline $pipeline_status — Source: $src | Build: $bld | Production: $prd"; break
  else
    echo "⏳ [$ts] Source: $src | Build: $bld | Production: $prd"
  fi
  sleep 15
done
```

Print a status line each poll showing all three stage statuses:
```
⏳ [15:32:10] Source: Succeeded | Build: InProgress | Production: —
⏳ [15:34:25] Source: Succeeded | Build: Succeeded  | Production: InProgress
✅ [15:39:47] Source: Succeeded | Build: Succeeded  | Production: Succeeded
```

The three stages are: **Source** (~10s), **Build/CodeBuild** (~2 min), **Production/CodeDeploy blue-green** (~5–8 min).

If the pipeline fails at any stage, print the stage name and stop. Don't attempt a retry automatically.

---

## Step 6: Verify the site

```bash
curl -o /dev/null -s -w "%{http_code}" -A "Mozilla/5.0" https://analytics-dashboard.dp.la
```

- `200` or `302` → success (302 is a redirect to the login page, which is normal)
- Anything else → warn the user

Print: `✅ Site is live — https://analytics-dashboard.dp.la returned <status>`

---

## Summary

At the end, print a clean summary:

```
🎉 Deployment complete!
   PR:       #<N> — <title>
   Branch:   <branch> (deleted)
   Pipeline: <execution-id>
   Status:   ✅ All stages passed
   Site:     https://analytics-dashboard.dp.la (HTTP <status>)
   Duration: ~<X> minutes
```

---

## Key infrastructure reference

| Resource | Value |
|---|---|
| Repo | `dpla/dashboard-analytics` |
| Build ECR workflow ID | `40080852` |
| CodePipeline | `analytics-dashboard-pipeline` |
| ECS cluster/service | `analytics-dashboard` / `analytics-dashboard` |
| ECR repo | `283408157088.dkr.ecr.us-east-1.amazonaws.com/analytics-dashboard` |
| Site URL | `https://analytics-dashboard.dp.la` |
| AWS region | `us-east-1` |
