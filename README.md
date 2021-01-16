# sqlc-demo

Simple demo of using sqlc and go-migrate

## Setting up the local environment

```bash
make stack-up
```

## Example for creating queries

```sql
-- name: GetAuthor :one
SELECT * FROM authors
WHERE id = $1 LIMIT 1;

-- name: ListAuthors :many
SELECT * FROM authors
ORDER BY name;

-- name: CreateAuthor :one
INSERT INTO authors (
  name, bio, reference
) VALUES (
  $1, $2, $3
)
RETURNING *;

-- name: DeleteAuthor :exec
DELETE FROM authors
WHERE id = $1;
```

## Demonstration

End to end, followable demo.

```bash
make stack-up
...

DB_MIGRATIONS_ENABLED=true make run
2021-01-16T11:37:38.970+1100	INFO	demo/main.go:35	Set logging to Development
2021-01-16T11:37:38.970+1100	INFO	demo/main.go:38	Creating sql instance
2021-01-16T11:37:38.984+1100	INFO	demo/main.go:45	Running config SQL Migration
2021-01-16T11:37:38.984+1100	INFO	migrator/migrator.go:27	Bootstrapping: Migrations
2021-01-16T11:37:38.989+1100	DEBUG	migrator/migrator.go:59	No migrations to apply
2021-01-16T11:37:38.993+1100	DEBUG	migrator/migrator.go:77		{"id": "0__schema.sql", "applied": true, "applied_at": "2021-01-16 11:26:02.539192 +1100 AEDT"}
2021-01-16T11:37:38.993+1100	DEBUG	migrator/migrator.go:77		{"id": "1__loan.sql", "applied": true, "applied_at": "2021-01-16 11:26:02.554635 +1100 AEDT"}
2021-01-16T11:37:38.998+1100	INFO	demo/main.go:78	Created Loan	{"loan_id": "703bb503-ffa9-4f78-ba47-c572231eb8bb", "loan": {"loan_id":"703bb503-ffa9-4f78-ba47-c572231eb8bb","artifact_type":"Invoice","artifact_id":"0a6087bc-e012-4e41-b9a3-c2115f95d624","merchant_id":"f3bdacd6-7984-4076-833e-89fb441dc9fe","payee_id":"b7967179-e4d5-4126-90e4-963a702dcee8","payee_type":"User","number_of_repayments":10,"loan_amount":"1000","merchant_fee":"100","principal":"200","setup_fee":"300","total_repayable":"10000","status":"Approved","next_repayment_date":"2021-01-16T11:37:38.993802+11:00","origination_date":"2021-01-16T11:37:38.993803+11:00","maturation_date":"2021-01-16T11:37:38.993803+11:00"}}

```
