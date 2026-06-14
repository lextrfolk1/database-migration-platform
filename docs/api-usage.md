# API Usage

## Endpoints

- `GET /health`
- `GET /inventory`
- `GET /services`
- `GET /services/{service}/databases`
- `POST /migrations/validate`
- `POST /migrations/plan`
- `POST /migrations/run`
- `POST /migrations/rebuild`
- `POST /migrations/repair`
- `GET /migrations/history`
- `GET /migrations/status/{execution_id}`

## Example request

```http
POST /migrations/run
Content-Type: application/json
```

```json
{
  "scope": "service",
  "service": "customer-service",
  "database": "postgres",
  "environment": "dev",
  "mode": "delta",
  "continueOnError": false,
  "allowRisky": false,
  "requestedBy": "dba-operator"
}
```

## Example all-services request

```json
{
  "scope": "all-services",
  "database": "postgres",
  "environment": "dev",
  "mode": "delta",
  "continueOnError": false,
  "allowRisky": false,
  "confirm": false
}
```
