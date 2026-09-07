# LedgerGuard API contract

| Method | Endpoint | Behavior | Success | Negative cases |
|---|---|---|---|---|
| POST | `/auth/token` | Create a tenant-scoped session | 200 | 401 invalid credentials; 422 invalid tenant |
| POST | `/accounts` | Open EUR or USD account | 201 | 422 currency |
| GET | `/accounts` | List owned accounts | 200 | 401 missing session |
| GET | `/accounts/{id}` | Read integer-cent balance | 200 | 403 owner; 404 missing |
| POST | `/accounts/{id}/fund` | Credit fictional funds | 200 | 422 amount; 403 owner |
| POST | `/transfers` | Atomic same-currency transfer with idempotency | 201 | 400 missing key; 409 funds or replay conflict; 422 amount/currency/same account |
| GET | `/transfers` | List owned transfers | 200 | 401 missing session |
| GET | `/transfers/{id}` | Read transfer status | 200 | 403 owner; 404 missing |
| POST | `/transfers/{id}/reverse` | Reverse once, subject to destination funds | 200 | 409 already reversed or insufficient destination funds |

All protected endpoints require `Authorization: Bearer <token>`. Errors have JSON shape `{"error":"CODE"}`. Missing IDs return 404, foreign ownership returns 403. Request bodies must be JSON objects; malformed JSON returns 400. The service uses a lock around state transitions to prevent partial updates and overselling or double debits. `POST /auth/token` accepts `username` (alice or bob), `password` (demo-password), and `tenant` (scenario UUID). Different tenants never share business state.

Create-operation retries with the same `Idempotency-Key` and JSON payload return 200 and the original resource. A different payload with the same key returns 409. Keys are scoped to the authenticated owner within a tenant. Subsequent reads and replays reflect current resource state.

This is a deliberately local teaching fixture: authentication uses fixed demo credentials, sessions do not expire, data is in memory, and all balances are fictional. It is not a production commerce or banking service. Restart the fixture between sustained load runs to clear retained state. Never expose its ports to the internet.
