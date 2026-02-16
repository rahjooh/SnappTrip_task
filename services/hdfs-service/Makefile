.PHONY: help up down status logs clean test ls mkdir put get

help:
	@echo "HDFS Service Commands:"
	@echo "  make up       - Start HDFS service"
	@echo "  make down     - Stop HDFS service"
	@echo "  make status   - Check service status"
	@echo "  make logs     - View logs"
	@echo "  make clean    - Remove volumes"
	@echo "  make test     - Test HDFS"
	@echo "  make ls       - List HDFS root"
	@echo "  make mkdir    - Create directory (use DIR=/path)"
	@echo "  make put      - Upload file (use LOCAL=/path REMOTE=/path)"

up:
	@echo "Starting HDFS service..."
	docker-compose up -d
	@echo "Waiting for HDFS to be ready..."
	@sleep 15
	@echo "Initializing lakehouse directories..."
	@$(MAKE) init-dirs
	@echo "HDFS service is ready!"
	@echo "NameNode UI: http://localhost:9870"

down:
	@echo "Stopping HDFS service..."
	docker-compose down

status:
	@docker-compose ps

logs:
	@docker-compose logs -f namenode

clean:
	@echo "Removing HDFS volumes..."
	docker-compose down -v

test:
	@echo "Testing HDFS..."
	@docker exec hdfs-namenode hdfs dfsadmin -report

ls:
	@docker exec hdfs-namenode hdfs dfs -ls /

mkdir:
	@docker exec hdfs-namenode hdfs dfs -mkdir -p $(DIR)

put:
	@docker exec -i hdfs-namenode hdfs dfs -put $(LOCAL) $(REMOTE)

get:
	@docker exec hdfs-namenode hdfs dfs -get $(REMOTE) $(LOCAL)

init-dirs:
	@docker exec hdfs-namenode hdfs dfs -mkdir -p /lakehouse/bronze/bookings_raw || true
	@docker exec hdfs-namenode hdfs dfs -mkdir -p /lakehouse/bronze/booking_events_raw || true
	@docker exec hdfs-namenode hdfs dfs -mkdir -p /lakehouse/bronze/hotels_raw || true
	@docker exec hdfs-namenode hdfs dfs -mkdir -p /lakehouse/silver/booking_state || true
	@echo "Lakehouse directories created!"
