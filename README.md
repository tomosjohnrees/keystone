# Keystone

A Rails 8 JSON API for submitting mortgage applications and asynchronously
producing an affordability assessment.

## Development with Docker

The development environment runs entirely in Docker, so the only host
dependencies are [Docker Desktop](https://www.docker.com/products/docker-desktop/)
and `make`.

### First-time setup

1. Run `make setup` to build the image, install gems, and prepare the
   database. Development uses `development-api-token` unless
   `KEYSTONE_API_TOKEN` is set; copy `.env.example` to `.env` to override.
2. Run `make up` to start the app on <http://localhost:3000>.
3. Run `make jobs` in another terminal to start the Solid Queue worker
   that processes assessments.

### Day-to-day

- `make up` — start the app in the foreground (Ctrl-C to stop).
  Use `make up-d` for a backgrounded start, then `make logs` to tail.
- `make jobs` — start the Solid Queue worker (background profile).
- `make help` — list every available target.
- `make test`, `make lint`, `make console`, `make db-migrate`, etc. — work
  whether or not the server is already running.

## API

All endpoints live under `/api/v1/` and accept and return JSON.
They require a bearer token:

```http
Authorization: Bearer <KEYSTONE_API_TOKEN>
```

Missing, malformed, or incorrect tokens return `401` with
`{ "error": "unauthorized" }`. The `/up` health check is not under
`/api/v1/` and remains unauthenticated. Development defaults to
`development-api-token`; production requires `KEYSTONE_API_TOKEN`.

### `POST /api/v1/mortgage_applications`

Create an application. A pending `Assessment` is created in the same
transaction and enqueued for background processing.

```bash
curl -X POST http://localhost:3000/api/v1/mortgage_applications \
  -H "Authorization: Bearer ${KEYSTONE_API_TOKEN:-development-api-token}" \
  -H "Content-Type: application/json" \
  -d '{
    "mortgage_application": {
      "annual_income": 60000,
      "monthly_expenses": 1500,
      "deposit_amount": 30000,
      "property_value": 250000,
      "term_years": 25
    }
  }'
```

Returns `201 Created` with the persisted application. Validation failures
return `422` with `{ "errors": { field: [messages] } }`. A missing
`mortgage_application` key returns `400`.

### `GET /api/v1/mortgage_applications/:id`

Fetch an application by id. Returns `200` or `404`.

### `GET /api/v1/mortgage_applications/:id/assessment`

Fetch the assessment for an application. The response always includes a
`status` (`pending`, `completed`, or `failed`); the result fields (`ltv`,
`dti`, `decision`, `max_borrowing`, `explanation`) are populated once the
job completes. `404` if the application or assessment does not exist.

## Application structure

```
app/
  controllers/api/v1/   thin HTTP layer; rescues map exceptions to JSON errors
    base_controller.rb         shared error handling (404 / 422 / 400)
    mortgage_applications_controller.rb
    assessments_controller.rb
  models/
    mortgage_application.rb    domain validations
    assessment.rb              status enum (pending/completed/failed)
    affordability.rb           pure PORO; the only place the rules live
  services/
    submit_mortgage_application.rb  creates application + assessment, enqueues the job
  jobs/
    assess_affordability_job.rb  runs the calculator, persists the result
  serializers/                  POROs that wrap `as_json` with an attribute allow-list
config/routes.rb                versioned namespace; assessment is a singular nested resource
db/migrate/                     two migrations: applications, then assessments
spec/                           RSpec — model, request, service, job, serializer
```

The flow on `POST /api/v1/mortgage_applications`:

1. The controller hands the params to `SubmitMortgageApplication`.
2. The service creates the `MortgageApplication` and its `pending`
   `Assessment` in a single transaction.
3. After the transaction commits, the service enqueues
   `AssessAffordabilityJob` via Solid Queue.
4. The worker runs `Affordability` against the application and
   updates the assessment to `completed` (or `failed`, with
   `error_message`).
5. The client polls `GET …/assessment` to read the current state.

## Key design decisions and assumptions

- **Pure calculator model.** `Affordability` is a plain Ruby object that
  takes any object responding to the five domain attributes and exposes
  `ltv`, `dti`, `max_borrowing`, `decision`, and `explanation` as
  readers. No ActiveRecord, no IO. This keeps the rules trivially
  unit-testable and easy to evolve in isolation from controllers and
  persistence.
- **Persisted, asynchronous assessments.** The result lives in the
  `assessments` table and is produced by a background job rather than on
  the request thread. The trade-off: a small amount of plumbing (job,
  status enum, polling endpoint) in exchange for fast `POST` responses,
  an auditable record of every decision, and a place to record failures
  (`status: :failed`, `error_message`).
- **Solid Queue, not Redis-backed Sidekiq.** Solid Queue is bundled with
  Rails 8 and is database-backed, so the dev/CI footprint stays at "just
  Postgres". We accept its lower throughput ceiling because the workload
  is one cheap, deterministic computation per application.
- **Versioned API namespace (`/api/v1`).** Cheap insurance against
  breaking changes to the response shape down the line.
- **PORO serializers, not `active_model_serializers`/`jsonapi`.** Two
  resources with stable shapes don't justify a serialization framework.
  Each serializer is an attribute allow-list around `as_json`.
- **Validation lives on the model, error rendering on the base
  controller.** `Api::V1::BaseController` rescues `RecordNotFound`,
  `RecordInvalid`, and `ParameterMissing` once, so individual actions
  stay 2–3 lines.
- **Unique index on `assessments.mortgage_application_id`.** Enforces
  one assessment per application at the database level rather than only
  at the model layer.
- **Decimals everywhere.** Money columns are `decimal(12,2)`; ratios are
  `decimal(8,2)`. We never round-trip currency through `Float`.
- **Assumption: the rules are illustrative.** LTV ≤ 90%, DTI ≤ 40%,
  income multiple of 4.5×, positive disposable income — these are common
  UK heuristics, not real underwriting. They live as constants at the
  top of `Affordability` and are intended to be replaced.
- **Single API bearer token.** `/api/v1/*` expects
  `Authorization: Bearer <token>`. Development defaults to
  `development-api-token`, test uses `test-api-token`, and production
  fails boot unless `KEYSTONE_API_TOKEN` is set. This is simple
  machine-to-machine authentication, not per-user authorization, audit
  trails, scopes, or token rotation.

## How the assessment logic works

The calculation is in `app/models/affordability.rb`. Given
an application's `annual_income`, `monthly_expenses`, `deposit_amount`,
and `property_value`:

| Quantity        | Formula                                       |
| --------------- | --------------------------------------------- |
| Loan amount     | `property_value − deposit_amount`             |
| LTV             | `loan_amount / property_value × 100` (2 d.p.) |
| Monthly income  | `annual_income / 12.0`                        |
| DTI             | `monthly_expenses / monthly_income × 100`     |
| Max borrowing   | `annual_income × 4.5`                         |
| Disposable inc. | `monthly_income − monthly_expenses`           |

An application is **approved** only if **all four** rules pass:

1. `LTV ≤ 90%`
2. `DTI ≤ 40%`
3. `loan_amount ≤ max_borrowing`
4. `disposable_income > 0`

If any rule fails, the decision is `declined` and the `explanation`
field lists every failing rule. On approval, the explanation summarises
the fit (LTV, DTI, max borrowing). The thresholds (`MAX_LTV`, `MAX_DTI`,
`INCOME_MULTIPLE`) are constants and trivial to tune.

The job (`AssessAffordabilityJob`) wraps the calculator: on success it
writes the five result fields and sets `status: :completed`. Any
`StandardError` is retried up to three times via Active Job's
`retry_on`; once retries are exhausted, the job marks the assessment
`status: :failed` and stores `error_message`. Each update runs inside
`with_lock` and is a no-op if the assessment is no longer `pending`,
so concurrent runs can't clobber a finished result.
