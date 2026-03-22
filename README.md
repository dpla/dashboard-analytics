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
  - [Rebuilding the Cache](#rebuilding-the-cache)
  - [Wikidata Resolution Chain](#wikidata-resolution-chain)
- [Infrastructure and Deployment](#infrastructure-and-deployment)
  - [AWS Architecture](#aws-architecture)
  - [Deploying a Change](#deploying-a-change)
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
```
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

**Async partial routes** — the hub and contributor overview pages load expensive sections via `render_async`. Each has a dedicated route that returns an HTML fragment:

```
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
| `POST /admin/wikimedia_cache/rebuild` | Trigger a Wikimedia cache rebuild |

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

```
/hubs/Texas?start_date=2024-06&end_date=2024-06
```

When no params are provided, the date range defaults to the current month. The `DateSetter` concern (included by all controllers) parses and validates these params, clamping them to the configured `min_date` and the current date.

Links between pages preserve the selected date range. When the current month is selected (the default), date params are omitted from URLs to keep them clean.

---

### Async Rendering

Hub and contributor overview pages use the [`render_async`](https://github.com/rendercoffee/render_async) gem to load each metric section independently. This means:

- The page structure renders immediately
- Each metric section fires its own background HTTP request
- Slow sections (e.g., GA4 calls) don't block faster ones (e.g., item counts)
- Individual sections can fail without taking down the whole page

Each async section has a dedicated controller action and route. The partial is rendered into a `<div>` placeholder and swapped in via JavaScript when the request completes.

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
| `WikimediaCacheBuilder` | Wikidata + CIM API | Populates the PostgreSQL Wikimedia cache |
| `WikimediaAnalyticsPresenter` | PostgreSQL cache | Formats Wikimedia metrics for display |
| `WikimediaPreparationsPresenter` | Wikidata | Wikimedia readiness metrics |
| `ContributorComparison` | All sources | Combines all metrics for the comparison table/CSV |

---

## Wikimedia Cache System

### How It Works

Wikimedia Commons analytics are pre-cached in a PostgreSQL table (`wikimedia_cache`) rather than fetched live. The table schema is:

```
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

Each `(hub, contributor, month)` combination is a unique row. The `WikimediaAnalyticsPresenter` queries this table with the selected date range, summing `page_views` across months and taking the maximum of the cumulative snapshot fields within the range.

### Rebuilding the Cache

**Via the admin UI:** Go to `/admin/users` and click **Rebuild Wikimedia Cache**. The rebuild runs in a background thread and takes several minutes. A flash notice confirms the job was started.

**Via rake task:**
```bash
bundle exec rake wikimedia:rebuild_cache
```

**What the rebuild does:**

1. Fetches `institutions_v2.json` from the ingestion3 repository — the authoritative list of hubs and contributors with their Wikidata IDs.
2. Resolves each unique Wikidata ID to a Wikimedia Commons category name (see below). This step is sequential to avoid rate-limiting by Wikidata.
3. Spawns a pool of 20 worker threads. Each thread picks work items off a queue and fetches data from the CIM API for its assigned category.
4. For each category, fetches all historical snapshot data and all historical pageview data in single wide-range API calls.
5. Upserts the results into `wikimedia_cache`. Snapshot fields and pageview fields are upserted separately so that a failed call for one doesn't overwrite cached values for the other with `nil`.

**Monthly automatic rebuild** is planned for the 8th of each month via an EventBridge scheduled task. Until that scheduler is deployed, use the admin button or rake task each month after the ingestion cycle completes.

### Wikidata Resolution Chain

Each institution in `institutions_v2.json` has a Wikidata entity ID (e.g., `Q83878485` for the Minnesota Digital Library). The cache builder resolves this to a Commons category name using two Wikidata API calls per unique ID:

```
Wikidata entity ID (e.g., Q83878485)
  → fetch entity JSON from wikidata.org
  → extract claims.P8464[0] (MediaInfo entity on Commons)
  → get the Commons entity ID (e.g., Q97584242)
  → fetch that entity's JSON
  → extract sitelinks.commonswiki.title
  → strip "Category:" prefix, replace spaces with underscores
  → Commons category name (e.g., "Media_contributed_by_the_Minnesota_Digital_Library")
```

This category name is then used in CIM API calls. Both Wikidata lookups reuse a single TLS connection per institution to minimize overhead.

---

## Infrastructure and Deployment

### AWS Architecture

| Component | Value |
|---|---|
| ECS Cluster | `analytics-dashboard` |
| ECS Service | `analytics-dashboard` |
| ECR Repository | `283408157088.dkr.ecr.us-east-1.amazonaws.com/analytics-dashboard` |
| CodePipeline | `analytics-dashboard-pipeline` |
| CodeBuild Project | See pipeline |
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
5. **Verify** — health check: `curl -I https://analytics-dashboard.dp.la`

If the deployment includes new database migrations, they run automatically as part of the Docker entrypoint (`bundle exec rails db:migrate`) before the Rails server starts.

### One-Off Tasks in Production

To run a rake task or Rails runner against the production database, use ECS `run-task` with the current ECR image:

```bash
aws ecs run-task \
  --cluster analytics-dashboard \
  --task-definition analytics-dashboard \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[<subnet>],securityGroups=[<sg>],assignPublicIp=ENABLED}" \
  --overrides '{"containerOverrides":[{"name":"analytics-dashboard","environment":[{"name":"DISABLE_SPRING","value":"1"}],"command":["bundle","exec","rake","wikimedia:rebuild_cache"]}]}'
```

---

## Local Development Setup

### Prerequisites

- Ruby 3.1.2 (use `rbenv` or `asdf`)
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

Primary Source Set (PSS) page view data is not tracked in the dashboard. The PSS pages on dp.la fire GA4 analytics events, but no PSS-specific query or metric section exists in the dashboard. This is a gap in the GA4 migration work.

### Wikimedia Cache — No Automatic Rebuild

The Wikimedia cache must be rebuilt manually each month (via the admin UI button or `rake wikimedia:rebuild_cache`). An EventBridge scheduled task to run the rebuild automatically on the 8th of each month is planned but not yet deployed. Until the scheduler exists, stale data will accumulate after the ingestion cycle closes for the month.

### Wikimedia Cache — Stale Rows

The cache rebuild is additive (upsert-only). If an institution is removed from `institutions_v2.json` or its Wikidata ID becomes unresolvable, its old rows remain in the table and continue to appear in the dashboard. A cleanup pass to delete rows not touched by the most recent rebuild is not yet implemented.

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
