# Production deployment security

Compose reads `production.env` from the deployment host for interpolation and reads the ignored
`pre-shantia/.env.production` and `pre-shantia-front/.env.production` files for application settings.
Use `production.env.example` and `pre-shantia/.env.example` as inventories only; never commit real values.

Required application secrets include `ENCRYPTION_KEY`, `JWT_ACCESS_SECRET`, `JWT_REFRESH_SECRET`,
`JWT_SECRET_KEY`, `REDIS_PASSWORD`, and `HEALTH_READINESS_TOKEN`.
Configured JWT and callback secrets must be random and at least 32 characters. Production startup rejects empty,
default, or placeholder-like values.

The installed `zibal@1.x` SDK authenticates with `ZIBAL_MERCHANT_ID`; it does not consume a
`ZIBAL_SECRET_KEY`. The legacy variable is therefore optional and is not sent to Zibal.

The MongoDB keyfile must be created and permissioned by the server administrator, then supplied through
`MONGO_KEYFILE_PATH` (for example, a root-owned file under `/run/secrets`). No replacement keyfile is
generated or committed here. MongoDB and Redis are private to the Compose network; only nginx publishes
HTTP(S) ports.

The deployment workflow expects a non-root `SSH_USER` with access to the deployment directory. If the
server currently requires root, configure that account through separate server administration. The
workflow fast-forwards only a clean checkout, never removes volumes, and verifies service health after
startup. The previous commit remains available for rollback via an explicit reviewed checkout.

`SHAHKAR_ENABLED` is used only to initialize the persistent Shahkar registration-enforcement setting when
no setting exists yet. After that, the administrator's database-backed choice is authoritative and survives
backend restarts/container recreation. Shahkar credentials remain server-side; they are required only when
enforcement is enabled (or when an administrator attempts to enable it). When enforcement is disabled,
signup still requires normal national-ID validation and OTP but makes no provider request.

Health liveness is intentionally generic at `/api/health` and `/api/health/live`. Detailed readiness
is protected by `HEALTH_READINESS_TOKEN` and returns only boolean component checks. Production Swagger is
disabled unless `ENABLE_SWAGGER=true`; when enabled, `SWAGGER_USERNAME` and `SWAGGER_PASSWORD` are
required and protect both the UI and OpenAPI JSON. Nginx does not proxy `/docs/`.

Application logs are structured, carry an `X-Request-ID` correlation value, and recursively redact
credentials, tokens, OTPs, cookies, phone/national identifiers, signed URLs, payloads, and provider
errors. The production Nginx CSP allows only same-origin scripts/styles, same-origin connections, and
the verified image hosts used by the Nuxt application (`picsum.photos` and `*.tejaris.ir`). It omits
`unsafe-eval` and `unsafe-inline`; if a future Nuxt build requires inline bootstrap code, add a nonce-based
integration rather than weakening this policy.
