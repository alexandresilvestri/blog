.PHONY: pgcli db-migrate db-seed

pgcli:
	pgcli postgresql://alexandre:0405@127.0.0.1:5432/blog

db-migrate:
	@docker compose exec app bun run db:migrate

db-seed:
	@docker compose exec app bun run db:seed

