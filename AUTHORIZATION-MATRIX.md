# Authorization matrix

This matrix records the intended access policy for identifier-based API routes. `AuthenticationGuard` means a valid access token is required; `PermissionsGuard` evaluates the permission named in the route. Record-level checks must still be applied after loading the record.

| Area | Method and route | Authentication | Permission | Ownership/company rule | Unauthorized result |
|---|---|---|---|---|---|
| Uploads | `POST /api/images/presign` | Required | `products.create/update` for `type=product`; `companies.create/update` for `type=company` | Scoped permission must match optional `companyId`; upload keys are server-generated | 401 anonymous, 403 missing/cross-company |
| Uploads | `POST /api/images/upload` | Required | Same as presign | Same; content is validated before storage | 401/403 or 400 invalid file |
| Tickets | `GET /api/tickets`, `GET /:id`, status/comments | Required | `ticketing.read` | Regular users are constrained to `createdBy`; staff/admin permission may read all | 403 cross-user, 404 missing |
| Tickets | `POST /`, `PATCH /:id`, status/resolve/escalate, comments, delete | Required | create/read/update/delete as applicable | Create forces `createdBy` from token; administrative mutations require explicit ticket permission | 403/404 |
| Transactions | `GET /api/transaction`, `GET /:trackId` | Required | `transaction.read` | Non-superadmins are restricted to their own `userId`; superadmin override is explicit | 403 cross-user, 404 missing |
| Transport | `GET /`, `GET /:id`, `GET /order/:orderId`, `GET /company/:companyId` | Required | transporting read/detailed-read | Company-scoped permission must match the record/company or related order | 403/404 |
| Transport | `POST /`, `PATCH /`, `PATCH /:id/cancel`, `PATCH /:id/delivered` | Required | transporting create/update | `companyId` comes from authorized scope; client cannot select another company | 403/404 |
| Companies | `POST /` | Required | companies.create | Created-by is the authenticated user | 403 |
| Companies | `PATCH/DELETE /:id`, status | Required | companies.update/delete | Service/controller verifies company administrator or explicit superadmin | 403/404 |
| Companies | `GET /:id`, list | Public | None | Public catalog data only | 404 missing |
| Products | `POST /`, `PATCH/DELETE /:id`, status | Required | products or product-status permission | Service resolves/preserves company ownership and rejects unauthorized company records; client cannot assign `companyId` | 403/404 |
| Products | Public search/catalog routes | Public | None | Must expose only published/catalog fields | 404/empty result |
| Orders | `POST /` | Required | orders.create | Non-admin `userId` is overwritten with token user | 403 |
| Orders | `GET /:id`, list | Required | orders.read | Non-admin users are restricted to their own orders; admin filters are permissioned | 403/404 |
| Orders | state transitions | Required | orders.update | Service preserves order ownership and transition rules; admin override is explicit | 403/404 |
| Wallets | wallet reads and credit/debit/transfer | Required | wallets read/update/deposit variant | Owner type and company scope derive from permissions; balances are server-controlled | 403 |
| Ratings | create/update/delete | Required | ratings create/update/delete | User ID always comes from token; product must exist | 403/404 |
| Ratings | product aggregates | Required | ratings.read | Product is a public catalog target but endpoint remains authenticated under current policy | 401/403/404 |
| Ratings | `GET /product/:productId/user/:userId` | Required | ratings.read | Only the requested user or an explicit ratings admin may access | 403/404 |
| Profiles | `GET /`, `PATCH /:id` | Required | profile read/update | Non-admin access is limited to the token user; ownership cannot be mass-assigned | 403/404 |

## Mass-assignment rules

Controllers/services derive `userId`, `createdBy`, `updatedBy`, company ownership, wallet owner, role/permission changes, balance, and status transitions from authenticated context and explicit permission checks. DTOs may carry display or business fields, but ownership and authorization fields are not trusted from clients.

## Upload security boundary

The server generates object keys and never accepts a client-supplied storage key. Direct multipart uploads are limited to five files, 10 MiB per file, 50 MiB request bodies, and 10 multipart parts. Only JPEG, PNG, and WebP magic bytes are accepted; SVG, extension/MIME mismatches, malformed images, trailing polyglot data, excessive dimensions, and excessive decoded pixels are rejected. Accepted images are decoded and re-encoded without source metadata. The malware scanner is an explicit interface with an unavailable adapter; no real malware scanning is claimed until an implementation is connected.
