# dashboard-analytics

Rails 7.0.4 / Ruby 3.1.2 app deployed on AWS ECS Fargate (blue/green via CodeDeploy).

## Before every commit

Run the `simplify` skill on all changed files before committing. Review its suggestions with judgment — apply fixes that make sense, but don't follow them blindly. Then commit.

## Deployment

See the `deploy-analytics-dashboard` skill for the full 4-step deployment process.

**Short version:**
1. Run the "Build ECR" GitHub Action on the branch (`gh workflow run 40080852 --ref <branch> --repo dpla/dashboard-analytics`)
2. Squash merge the PR and delete the branch (`gh pr merge <number> --squash --delete-branch --repo dpla/dashboard-analytics`), then start CodePipeline (`aws codepipeline start-pipeline-execution --name analytics-dashboard-pipeline`)
3. Monitor until green traffic reaches 100%
4. Verify with `curl -o /dev/null -s -w "%{http_code}" https://analytics-dashboard.dp.la`

## Key facts

- ECR image tag used by CodePipeline: `latest`
- ECS service: `analytics-dashboard` in cluster `analytics-dashboard`
- CodeDeploy app: `AppECS-analytics-dashboard-analytics-dashboard`
- Secret ARN: `arn:aws:secretsmanager:us-east-1:283408157088:secret:terraform-20240821214923751700000001-7CZ7Cq`
  - Do NOT include `|AWSCURRENT` suffix in task definition `valueFrom` — newer Fargate rejects it
- IAM role `ecs-task-execution-role` has inline policy `analytics-dashboard-secrets` granting `secretsmanager:GetSecretValue`
