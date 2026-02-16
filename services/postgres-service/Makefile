.PHONY: help up down status connect test query backup restore clean

help:
	@echo "PostgreSQL Service Commands:"
	@echo "  make up       - Start PostgreSQL service"
	@echo "  make down     - Stop PostgreSQL service"
	@echo "  make status   - Check service status"
	@echo "  make connect  - Connect to database"
	@echo "  make test     - Test connection"
	@echo "  make query    - Run SQL query (use SQL='...')"
	@echo "  make backup   - Backup database"
	@echo "  make restore  - Restore database (use FILE=...)"
	@echo "  make clean    - Remove volumes"

up:
	@echo "Starting PostgreSQL service..."
	docker-compose up -d
	@echo "Waiting for PostgreSQL to be ready..."
	@sleep 5
	@echo "PostgreSQL is ready!"
	@echo "Connection: postgresql://snapptrip:snapptrip123@localhost:5432/snapptrip_analytics"
	@echo "PgAdmin: http://localhost:5050"

down:
	@echo "Stopping PostgreSQL service..."
	docker-compose down

status:
	@docker-compose ps

connect:
	@docker exec -it postgres-analytics psql -U snapptrip -d snapptrip_analytics

test:
	@echo "Testing PostgreSQL connection..."
	@docker exec postgres-analytics pg_isready -U snapptrip

query:
	@docker exec postgres-analytics psql -U snapptrip -d snapptrip_analytics -c "$(SQL)"

backup:
	@echo "Backing up database..."
	@docker exec postgres-analytics pg_dump -U snapptrip snapptrip_analytics > backup_$$(date +%Y%m%d_%H%M%S).sql
	@echo "Backup complete!"

restore:
	@echo "Restoring database from $(FILE)..."
	@docker exec -i postgres-analytics psql -U snapptrip snapptrip_analytics < $(FILE)
	@echo "Restore complete!"

clean:
	@echo "Removing PostgreSQL volumes..."
	docker-compose down -v
