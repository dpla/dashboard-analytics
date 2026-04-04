# DPLA Analytics Dashboard

A Rails application that aggregates analytics data from multiple sources to provide usage dashboards for [DPLA](https://dp.la) hubs and their contributing institutions.

**Live site:** https://analytics-dashboard.dp.la

---

## Table of Contents

- [Overview](#overview)
- [Data Sources](#data-sources)
  - [Google Analytics 4 (GA4)](#google-analytics-4-ga4)
  - [DPLA API](#dpla-api)
  - [AWS S3 — Metadata Completeness](#aws-s3--metadata-completeness)
  - [Wikimedia Commons Impact Metrics](#wikimedia-commons-impact-metrics)
- [Application Structure](#application-structure)
  - [Pages and Routes](#pages-and-routes)
  - [User and Permission Model](#user-and-permission-model)
  - [Date Range Handling](#date-range-handling)
  - [Async Rendering](#async-rendering)
  - [Data Builders and Presenters](#data-builders-and-presenters)
- [Wikimedia Cache System](#wikimedia-cache-system)
  - [How It Works](#how-it-works)
  - [Participant Status](#participant-status)
  - [Rebuilding the Cache](#rebuilding-the-cache)
  - [Scheduled Automatic Rebuild](#scheduled-automatic-rebuild)
  - [Wikidata Resolution Chain](#wikidata-resolution-chain)
- [Infrastructure and Deployment](#infrastructure-and-deployment)
  - [AWS Architecture](#aws-architecture)
  - [Deploying a Change](#deploying-a-change)
  - [Database Migrations in Production](#database-migrations-in-production)
  - [One-Off Tasks in Production](#one-off-tasks-in-production)
- [Local Development Setup](#local-development-setup)
  - [Prerequisites](#prerequisites)
  - [Configuration](#configuration)
  - [First-Time Setup](#first-time-setup)
  - [Running with Docker](#running-with-docker)
- [Account Management](#account-management)
- [Known Issues and Limitations](#known-issues-and-limitations)
- [Copyright and License](#copyright-and-license)

---

## Overview

The dashboard provides hub-level and contributor-level analytics for DPLA's network of content hubs. Each hub page shows:

- **Website usage** — sessions, users, and events on dp.la, filtered to the hub's content
- **API usage** — programmatic access to the hub's items via the DPLA API
- **Black Women's Suffrage (BWS) usage** — engagement with the hub's content in the BWS digital exhibit
- **Item counts** — total items contributed by the hub and each of its contributors
- **Metadata completeness** — field-level completeness scores from monthly S3 snapshots
- **Wikimedia Commons integration** — upload counts, page views, files used, and pages enhanced for hub content on Wikimedia Commons

Data is loaded asynchronously on each page so that slow API calls don't block the initial render.

---

## Data Sources

### Google Analytics 4 (GA4)

Website analytics are pulled live from the GA4 Reporting API (v1 beta) using a Google service account.

**Auth:** A JSON service account key file is provided to the application either as a local file (`config/google-analytics-key.json`) or via the `GOOGLE_ANALYTICS_KEY` environment variable (used in production). The key grants read-only access to the GA4 property.

**What is tracked:**

| Section | GA4 dimension used |
|---|---|
| Website overview | Sessions, users, events filtered by `customEvent:content_partner` |
| Website timelines | Monthly sessions over time |
| Website events | Event name and count breakdowns |
| Website search terms | `searchTerm` dimension on search events |
| Locations | `region` dimension on sessions |

**What is NOT tracked in GA4:**

- **API usage** — The DPLA API does not report to GA4. API usage sections on every page are present in the UI but show no data.
- **BWS usage** — The Black Women's Suffrage site is not instrumented with GA4 (it ran Universal Analytics, which stopped collecting data in July 2023). BWS usage sections are present in the UI but show zero values.

The GA4 integration lives in `app/lib/ga_response_builder.rb`. Each metric section has a dedicated builder class (e.g., `WebsiteOverview`, `WebsiteEvents`, `WebsiteSearchTerms`) that constructs and executes the appropriate GA4 `RunReportRequest`.

---

### DPLA API

Hub and contributor item counts are fetched from the DPLA API (`api.dp.la/v2/`). The API is also used to enumerate which contributors belong to each hub, providing the list used throughout the dashboard.

The source of truth for which hubs and contributors exist, and their Wikidata IDs, is a separate JSON file maintained by the ingestion team: [`institutions_v2.json`](https://raw.githubusercontent.com/dpla/ingestion3/main/src/main/resources/wiki/institutions_v2.json). This file is used by the Wikimedia cache builder but not directly by the API-based item count queries.

API calls are made via `DplaApiResponseBuilder` (using HTTParty). The API key is configured in `settings.yml` (`dpla_api.key`) or the `DPLA_API_KEY` environment variable.

---

### AWS S3 — Metadata Completeness

Monthly metadata completeness reports are stored as CSV files in an S3 bucket. Each file contains field-level completeness percentages for a hub or contributor.

**File layout in S3:**
```text
<bucket>/
  YYYY/MM/
    provider.csv      ← hub-level completeness
    contributor.csv   ← contributor-level completeness
```

The application reads the CSV for the selected month (falling back to prior months if the current month's file isn't yet available). Parsing is handled by `MetadataCompleteness` and `MetadataCompletenessPresenter` in `app/lib/`.

The S3 bucket name is configured in `settings.yml` (`s3.bucket`). The application uses the AWS SDK with the execution role's IAM permissions (no explicit key needed in production).

---

### Wikimedia Commons Impact Metrics

Wikimedia analytics data is pre-fetched and cached in the application's PostgreSQL database rather than queried live. This avoids latency from the external API on every page load.

The data comes from two Wikimedia APIs:

| API | Endpoint | Data |
|---|---|---|
| Commons Impact Metrics (CIM) — snapshot | `wikimedia.org/api/rest_v1/metrics/commons-analytics/category-metrics-snapshot/{category}/{start}/{end}` | Monthly upload count, files used, pages enhanced |
| Commons Impact Metrics (CIM) — pageviews | `wikimedia.org/api/rest_v1/metrics/commons-analytics/pageviews-per-category-monthly/{category}/deep/all-wikis/{start}/{end}` | Monthly page view count |

See the [Wikimedia Cache System](#wikimedia-cache-system) section for full details.

---

## Application Structure

### Pages and Routes

All routes require a logged-in user.

**Hub pages**

| Route | Description |
|---|---|
| `GET /` or `/hubs` | Hub index — card grid of all hubs with item counts. Single-hub users are redirected directly to their hub. |
| `GET /hubs/:hub_id` | Hub overview — the main dashboard for a hub |
| `GET /hubs/:hub_id/contributors` | Contributor comparison table for a hub |
| `GET /hubs/:hub_id/contributors/:id` | Individual contributor dashboard |

**Data sub-pages** (linked from the data menu on hub/contributor pages)

| Route | Description |
|---|---|
| `/hubs/:hub_id/timelines/website` | Month-by-month website session timeline |
| `/hubs/:hub_id/timelines/api` | Month-by-month API usage timeline |
| `/hubs/:hub_id/timelines/bws` | Month-by-month BWS usage timeline |
| `/hubs/:hub_id/events/website` | Website event breakdown (HTML + CSV) |
| `/hubs/:hub_id/events/api` | API event breakdown |
| `/hubs/:hub_id/events/bws` | BWS event breakdown |
| `/hubs/:hub_id/search_terms/website` | Top search terms (HTML + CSV) |
| `/hubs/:hub_id/search_terms/api` | API search terms |
| `/hubs/:hub_id/locations` | Geographic session distribution |
| `/hubs/:hub_id/wikimedia_preparations` | Wikimedia Commons readiness metrics |
| `/contributor_comparison` | Full contributor comparison export (HTML + CSV) |

**Async partial routes** — the hub and contributor overview pages load all expensive sections with a single async request to a `sections` endpoint, which fetches all data concurrently server-side and returns one combined HTML fragment:

```text
GET /hubs/:hub_id/sections
GET /hubs/:hub_id/contributors/:contributor_id/sections
```

Individual section routes still exist for sub-pages that load only one section at a time:

```text
GET /hubs/:hub_id/website_overview
GET /hubs/:hub_id/api_overview
GET /hubs/:hub_id/bws_overview
GET /hubs/:hub_id/item_count
GET /hubs/:hub_id/metadata_completeness
GET /hubs/:hub_id/wikimedia_overview
```

**Admin routes**

| Route | Description |
|---|---|
| `GET /admin/users` | User list (admin only) |
| `GET/POST /admin/users/new` | Create a user |
| `GET/PATCH /admin/users/:id/edit` | Edit user permissions |
| `DELETE /admin/users/:id` | Delete a user |
| `POST /admin/wikimedia_cache/rebuild` | Trigger an on-demand Wikimedia cache rebuild |

**Other**

| Route | Description |
|---|---|
| `GET /health` | Returns `200 ok` — used by the ECS load balancer health check |
| `GET/PATCH /users/edit` | User's own account settings (Devise) |

---

### User and Permission Model

Users are managed with [Devise](https://github.com/heartcombo/devise) (email + password). There are two permission axes:

**`admin` (boolean):** Grants access to the `/admin/users` interface for creating, editing, and deleting users. Regular users can only view their own account.

**`hub` (string):** Controls which data a user can see.

| `hub` value | Access |
|---|---|
| `"All"` | Full access to all hubs — sees the hub index grid and can browse any hub or contributor |
| `"Texas"` (or any hub name) | Restricted to that hub only — redirected from the hub index directly to their hub's overview page; redirected away from any other hub's pages |

Single-hub users see a simplified navigation: **Overview** (their hub), **Contributors** (if the hub has more than one), and **Search Terms**. The admin **Users** link is only shown to users with `admin: true`.

**Creating the first user** — from the Rails console:

```ruby
User.create!(email: "admin@example.com", admin: true, hub: "All", password: SecureRandom.hex(16))
```

Subsequent users are created via the admin UI at `/admin/users`. A generated password is emailed to the new user via AWS SES.

---

### Date Range Handling

All data views support a `start_date` / `end_date` URL parameter pair in `YYYY-MM` format:

```text
/hubs/Texas?start_date=2024-06&end_date=2024-06
```

When no params are provided, the date range defaults to all-time data. The `DateSetter` concern (included by all controllers) parses and validates these params, clamping them to the configured `min_date` and the current date.

Links between pages preserve the selected date range.

---

### Async Rendering

Hub and contributor overview pages use the [`render_async`](https://github.com/rendercoffee/render_async) gem to load metric sections independently from the initial page render. A single async request is made to the `sections` endpoint, which executes all data fetches concurrently in server-side threads and returns a combined HTML fragment. This means:

- The page structure renders immediately
- All metric sections are fetched in one background request via concurrent threads
- Slow sections (e.g., GA4 calls) don't block faster ones (e.g., item counts from the DPLA API)
- Individual data fetches can fail without taking down the whole page

---

### Data Builders and Presenters

Data fetching is organized into a library of plain Ruby classes in `app/lib/`. The pattern is:

- **Builder classes** make external API calls and return structured data (hashes or arrays).
- **Presenter classes** format that data for display (table rows, labels, totals).
- **Controller actions** instantiate builders/presenters with the current hub, contributor, and date range, then pass results to views.

**Key builder classes:**

| Class | Source | Purpose |
|---|---|---|
| `GaResponseBuilder` | GA4 API | Base class; all GA4 builders subclass this |
| `WebsiteOverview` | GA4 | Sessions, users, events for a hub/contributor |
| `WebsiteEvents` | GA4 | Event name/count breakdown |
| `WebsiteSearchTerms` | GA4 | Top search terms |
| `ApiOverview` | — | Stub — API data not available in GA4 |
| `BwsOverview` | — | Stub — BWS data not available in GA4 |
| `DplaApiResponseBuilder` | DPLA API | Item counts and contributor lists |
| `SThreeResponseBuilder` | AWS S3 | Metadata completeness CSVs |
| `MetadataCompleteness` | S3 CSVs | Parses field-level completeness data |
| `WikimediaCacheBuilder` | Wikidata + CIM API | Populates the PostgreSQL Wikimedia cache tables |
| `WikimediaAnalyticsPresenter` | PostgreSQL cache | Formats Wikimedia metrics for display |
| `WikimediaPreparationsPresenter` | Wikidata | Wikimedia readiness metrics |
| `ContributorComparison` | All sources | Combines all metrics for the comparison table/CSV |

---

## Wikimedia Cache System

### How It Works

Wikimedia Commons analytics are pre-cached in two PostgreSQL tables rather than fetched live on every page load.

**`wikimedia_cache`** — monthly metrics per hub/contributor:

```text
wikimedia_cache
  hub             string   — hub name (e.g., "Minnesota Digital Library")
  contributor     string   — contributor name, or "" for hub-level rows
  month           string   — "YYYY-MM"
  upload_count    integer  — media files contributed as of this month (cumulative)
  files_used      integer  — files actually used on Wikimedia projects
  pages_enhanced  integer  — Wikimedia pages using this content
  page_views      integer  — total page views for this content this month
  created_at / updated_at
```

Each `(hub, contributor, month)` combination is a unique row. `WikimediaAnalyticsPresenter` queries this table with the selected date range, summing `page_views` across months and taking the maximum of the cumulative snapshot fields within the range.

**`wikimedia_participants`** — participant status per contributor:

```text
wikimedia_participants
  hub             string   — hub name
  contributor     string   — contributor name
  participant     boolean  — true if upload: true in institutions_v2.json
  created_at / updated_at
```

Each `(hub, contributor)` pair is unique. This table is read at page load to choose the appropriate "no data" message: participants with no cached data yet see "No usage recorded yet across Wikimedia"; non-participants see "Not a Wikimedia pipeline participant."

### Participant Status

A contributor is a Wikimedia pipeline participant if `upload: true` is set on that contributor or its parent hub in `institutions_v2.json`. Having a Wikidata ID alone does not imply participation — all cultural institutions may have Wikidata IDs regardless of whether they contribute files to Wikimedia Commons.

The `wikimedia_participants` table is populated at rebuild time by `WikimediaCacheBuilder#sync_participant_flags`. Hub-level `upload: true` cascades to all contributors in that hub. The full table is replaced atomically on each rebuild (delete-all inside a transaction, then re-insert), so removed contributors are cleaned up automatically.

Hub pages use `WikimediaParticipant.hub_participant?` to check whether any contributor in the hub has `participant: true`, which determines whether to show "No usage recorded yet" vs "Not a Wikimedia pipeline participant" when no cached data is available.

### Rebuilding the Cache

**Via the admin UI:** Go to `/admin/users` and click **Rebuild Wikimedia Cache**. Use this for on-demand rebuilds (e.g., after a new hub is onboarded, or to recover from a failed scheduled run). The rebuild runs in a background thread; a flash notice confirms it was started. The button disables on click to prevent double-submission.

**What the rebuild does:**

1. Fetches `institutions_v2.json` from the ingestion3 repository.
2. Writes participant flags to `wikimedia_participants` (atomic delete + re-insert in a transaction).
3. Resolves each unique Wikidata ID to a Wikimedia Commons category name via two batched MediaWiki API phases (see [Wikidata Resolution Chain](#wikidata-resolution-chain)).
4. Spawns a pool of 20 worker threads. Each thread picks work items off a queue and fetches CIM API data for its assigned Commons category.
5. For each category, fetches all historical snapshot and pageview data in single wide-range API calls.
6. Upserts the results into `wikimedia_cache`. Snapshot fields and pageview fields are upserted separately so that a failed call for one does not overwrite cached values for the other with `nil`.

The rebuild takes approximately 10 minutes. Progress is logged at `error` level (the default production `LOG_LEVEL`) so milestones appear in CloudWatch:

```text
[WikimediaCacheBuilder] Starting rebuild
[WikimediaCacheBuilder] Synced participant flags for 421 contributors
[WikimediaCacheBuilder] 2750 work items to process
[WikimediaCacheBuilder] Phase 1: 423/519 Wikidata IDs resolved to P8464 category Q-ids
[WikimediaCacheBuilder] Phase 2: 421/423 category Q-ids resolved to Commons category names
[WikimediaCacheBuilder] 2708/2750 items have resolvable Commons categories
[WikimediaCacheBuilder] Rebuild complete
```

### Scheduled Automatic Rebuild

The cache should be rebuilt monthly after the ingestion cycle closes. The planned approach is a **scheduled GitHub Actions workflow** that triggers the rebuild on the 8th of each month.

**To implement:**
1. Add `.github/workflows/wikimedia-cache-rebuild.yml` with `on: schedule: - cron: '0 12 8 * *'` (noon UTC on the 8th).
2. The workflow should invoke `rake wikimedia:rebuild_cache` via a one-off ECS task (see [One-Off Tasks in Production](#one-off-tasks-in-production)), or POST to the rebuild endpoint with admin credentials stored as GitHub Actions secrets.

Until the scheduled workflow is deployed, trigger the rebuild manually each month via the admin UI button after the ingestion cycle completes.

### Wikidata Resolution Chain

Each institution in `institutions_v2.json` has a Wikidata entity ID (e.g., `Q83878485` for the Minnesota Digital Library). The cache builder resolves this to a Commons category name in two batched API phases:

**Phase 1 — Wikidata (wikidata.org):** Fetches P8464 claims in batches of 50 IDs per request. P8464 links each institution's Wikidata item to the Wikidata item for its Commons category (e.g., `Q112194444` → `Q113547185`). Entities without a P8464 claim have no Commons category and are skipped.

**Phase 2 — Wikidata (wikidata.org):** Fetches sitelinks for the resolved category Q-ids in batches of 50. Extracts the `commonswiki` sitelink title, strips the `"Category:"` prefix, and replaces spaces with underscores to produce the CIM API category name.

```text
Wikidata entity ID  (e.g., Q112194444)
  ↓ Phase 1: wbgetentities?ids=...&props=claims  (batches of 50)
  claims.P8464[0].mainsnak.datavalue.value.id
  ↓ Commons category Q-id  (e.g., Q113547185)
  ↓ Phase 2: wbgetentities?ids=...&props=sitelinks  (batches of 50)
  sitelinks.commonswiki.title  →  strip "Category:", replace spaces with "_"
  ↓ Commons category name  (e.g., "Media_contributed_by_Northwest_Digital_Heritage")
```

Each phase reuses a single TLS connection for all batches to minimize overhead.

---

## Infrastructure and Deployment

### AWS Architecture

| Component | Value |
|---|---|
| ECS Cluster | `analytics-dashboard` |
| ECS Service | `analytics-dashboard` |
| ECR Repository | `283408157088.dkr.ecr.us-east-1.amazonaws.com/analytics-dashboard` |
| CodePipeline | `analytics-dashboard-pipeline` |
| Deployment strategy | Blue/green via CodeDeploy (auto-rollback on failure) |
| Load balancer | Shared ALB (`baggins`) — routed by host header |
| Secrets Manager | `arn:aws:secretsmanager:us-east-1:283408157088:secret:terraform-20240821214923751700000001-7CZ7Cq` |
| Task execution role | `ecs-task-execution-role` |

**Secrets** (stored in Secrets Manager, injected as environment variables into ECS tasks):

| Variable | Purpose |
|---|---|
| `SECRET_KEY_BASE` | Rails session signing |
| `GOOGLE_ANALYTICS_KEY` | GA4 service account JSON (escaped) |
| `GA4_PROPERTY_ID` | GA4 property ID |
| `TRACKING_ID` | GA4 tracking/measurement ID |
| `DPLA_API_KEY` | DPLA API key |
| `S3_BUCKET` | Metadata completeness S3 bucket |
| `DB_HOST` / `DB_USERNAME` / `DB_PASSWORD` | PostgreSQL credentials |
| `SENTRY_DSN` | Sentry error tracking |
| `SMTP_PASSWORD` | AWS SES credentials for outbound email |
| `LOG_LEVEL` | Rails log level (defaults to `error` if unset — `warn` or `info` for more verbosity) |

**CodePipeline note:** The pipeline has a stale webhook (a known AWS CodeStar Connections migration issue) and does not auto-trigger on push to `main`. It must be started manually after merging:

```bash
aws codepipeline start-pipeline-execution --name analytics-dashboard-pipeline
```

### Deploying a Change

Use the `deploy-analytics-dashboard` Claude skill, which enforces the correct order. The manual steps are:

1. **Build the ECR image** — trigger the "Build ECR" GitHub Actions workflow on the branch to be deployed.
2. **Merge the PR** — squash merge and delete the branch. Do not merge before the image is built.
3. **Start the pipeline** — start `analytics-dashboard-pipeline` manually (stale webhook).
4. **Monitor** — CodeBuild compiles assets (~2 min), then CodeDeploy performs the blue/green ECS swap (~5–8 min).
5. **Run migrations** — if the deployment includes new migrations, run them as a one-off ECS task (see below).
6. **Verify** — health check: `curl -I https://analytics-dashboard.dp.la`

### Database Migrations in Production

**Migrations do not run automatically as part of the ECS deployment.** After deploying code that adds new migrations, run them as a separate one-off ECS task:

```bash
aws ecs run-task \
  --cluster analytics-dashboard \
  --task-definition arn:aws:ecs:us-east-1:283408157088:task-definition/analytics-dashboard:<VERSION> \
  --launch-type FARGATE \
  --network-configuration '{"awsvpcConfiguration":{"subnets":["subnet-0e6dbb3a02a55a416","subnet-00f8056d6e59465ca"],"securityGroups":["sg-09e35b96da021355c"],"assignPublicIp":"ENABLED"}}' \
  --overrides '{"containerOverrides":[{"name":"analytics-dashboard-container","command":["bundle","exec","rails","db:migrate"],"environment":[{"name":"DISABLE_SPRING","value":"1"}]}]}'
```

`DISABLE_SPRING=1` is required — Spring's preloader fails in the production environment and causes the task to exit with code 1 without it.

Get the current task definition version:
```bash
aws ecs describe-services --cluster analytics-dashboard --services analytics-dashboard \
  --query 'services[0].taskDefinition' --output text
```

After the task stops, check the exit code and view migration output in CloudWatch:
```bash
aws ecs describe-tasks --cluster analytics-dashboard --tasks <TASK_ARN> \
  --query 'tasks[0].{status:lastStatus,exit:containers[0].exitCode}'

aws logs get-log-events \
  --log-group-name /ecs/analytics-dashboard \
  --log-stream-name "ecs/analytics-dashboard-container/<TASK_ID>"
```

**Important:** After running migrations that add new tables or indexes, the running ECS tasks have a stale schema cache and may not recognize the new schema until restarted. If application code immediately uses the new schema (e.g., `upsert_all` with `unique_by`), restart the task after migrating by stopping it — ECS will automatically start a replacement with a fresh schema cache.

### One-Off Tasks in Production

To run a rake task or Rails runner against the production database, use ECS `run-task` with `DISABLE_SPRING=1`:

```bash
aws ecs run-task \
  --cluster analytics-dashboard \
  --task-definition arn:aws:ecs:us-east-1:283408157088:task-definition/analytics-dashboard:<VERSION> \
  --launch-type FARGATE \
  --network-configuration '{"awsvpcConfiguration":{"subnets":["subnet-0e6dbb3a02a55a416","subnet-00f8056d6e59465ca"],"securityGroups":["sg-09e35b96da021355c"],"assignPublicIp":"ENABLED"}}' \
  --overrides '{"containerOverrides":[{"name":"analytics-dashboard-container","environment":[{"name":"DISABLE_SPRING","value":"1"}],"command":["bundle","exec","rake","wikimedia:rebuild_cache"]}]}'
```

---

## Local Development Setup

### Prerequisites

- Ruby 3.1.2 (use `rbenv` or `asdf`)
- Rails 7.2
- Bundler 2.x
- SQLite 3 (development database)
- Node.js (for asset compilation if needed)

### Configuration

**1. Copy config templates:**

```bash
cp config/settings.yml.template config/settings.yml
cp config/database.yml.template config/database.yml
```

**2. Edit `config/settings.yml`** with real values:

```yaml
google_analytics:
  service_account_json_key: ./config/google-analytics-key.json
  property_id: "1234567890"            # GA4 property ID (numeric)
  tracking_id: "G-XXXXXXXXXX"          # GA4 measurement ID
dpla_api:
  base_uri: api.dp.la/v2/
  key: your_dpla_api_key
s3:
  bucket: your-s3-bucket-name
min_date:
  month: 01
  year: 2018
```

**3. Google Analytics service account key:**

Download the JSON service account key from the Google Cloud console and save it as `config/google-analytics-key.json`. See `config/google-analytics-key.json.template` for the expected format.

### First-Time Setup

```bash
bundle install
bundle exec rails db:migrate

# Create an initial admin user
bundle exec rails runner "User.create!(email: 'admin@example.com', admin: true, hub: 'All', password: 'changeme')"

bundle exec rails server
```

The app runs on `http://localhost:3000`. Log in with the credentials you just created.

### Running with Docker

```bash
cp docker-compose.yml.example docker-compose.yml
# Edit docker-compose.yml and set environment variables

docker-compose build
docker-compose up

# First time only — create and migrate the database:
docker-compose run web bundle exec rails db:create db:migrate
```

**Testing with Docker:**

```bash
docker-compose run -e RAILS_ENV=test web bundle exec rails db:create db:migrate
docker-compose run -e RAILS_ENV=test web bundle exec rspec
```

**Without Docker:**

```bash
bundle exec rspec
```

---

## Account Management

All user management is done through the admin UI at `/admin/users` (requires `admin: true`).

**Creating a user:**
1. Click **Sign up a new user**.
2. Enter the user's email address and select their hub (`All` for full access, or a specific hub name).
3. The system generates a random password and emails it to the user via AWS SES.
4. The user can change their password via **My account → Change password**.

**Hub names** must exactly match the hub names used in the DPLA API and `institutions_v2.json`. The hub name is case-sensitive and used as a URL slug (e.g., `"Minnesota Digital Library"` → `/hubs/Minnesota%20Digital%20Library`).

**Editing permissions:** Use the **Edit permissions** button on any user row to change their hub assignment or admin status.

**Deleting a user:** Use the **Delete** button. This is permanent and cannot be undone.

---

## Known Issues and Limitations

### Missing Data — API Usage

API usage metrics (sections labeled "API" across all hub and contributor pages) return no data. The DPLA API does not report usage to Google Analytics, and no alternative source has been integrated. The sections are present in the UI but display nothing.

### Missing Data — Black Women's Suffrage

The Black Women's Suffrage (BWS) digital exhibit at [blackwomenssuffrage.dp.la](https://blackwomenssuffrage.dp.la) ran Universal Analytics, which stopped collecting data in July 2023. The site has not been migrated to GA4, so all BWS analytics sections show zero values. BWS analytics will require a GA4 property to be set up for the BWS site and its ID configured in dashboard settings.

### Missing Data — Primary Source Sets

Primary Source Set (PSS) page view data is not tracked in the dashboard. The PSS pages on dp.la fire GA4 analytics events, but no PSS-specific query or metric section exists in the dashboard.

### Wikimedia Cache — No Scheduled Rebuild

The Wikimedia cache must currently be rebuilt manually each month via the admin UI button. A scheduled GitHub Actions workflow to trigger the rebuild automatically on the 8th of each month has not yet been implemented. See [Scheduled Automatic Rebuild](#scheduled-automatic-rebuild) for the planned approach.

### Metadata Completeness — Monthly Lag

Metadata completeness CSVs are generated as part of the monthly ingestion cycle and typically aren't available until the cycle completes. If a hub's CSV for the current month isn't in S3 yet, the dashboard silently falls back to the most recent available month.

### Contributor Comparison — Potential Timeouts

The contributor comparison page (`/contributor_comparison`) makes parallel GA4 API calls for every contributor in a hub. For hubs with many contributors, this can be slow and may time out under heavy load. The page includes a CSV export option for offline analysis.

### Hard-Coded Configuration

A few values that should be configurable are currently hard-coded:

- The AWS S3 region is hard-coded to `us-east-1` in `SThreeResponseBuilder`.
- The GA4 service account key file path defaults to `./google-analytics-key.json` relative to the Rails root in `config/application.rb`.

---

## Copyright and License

Copyright Digital Public Library of America, 2018–2026.
Licensed under the MIT License.
