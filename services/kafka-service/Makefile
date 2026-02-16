.PHONY: help up down status logs clean test-producer test-consumer list-topics create-topics

help:
	@echo "Kafka Service Commands:"
	@echo "  make up              - Start Kafka service"
	@echo "  make down            - Stop Kafka service"
	@echo "  make status          - Check service status"
	@echo "  make logs            - View logs"
	@echo "  make clean           - Remove volumes"
	@echo "  make test-producer   - Test Kafka producer"
	@echo "  make test-consumer   - Test Kafka consumer"
	@echo "  make list-topics     - List all topics"
	@echo "  make create-topics   - Create required topics"

up:
	@echo "Starting Kafka service..."
	docker-compose up -d
	@echo "Waiting for Kafka to be ready..."
	@sleep 10
	@echo "Kafka service is ready!"
	@echo "Kafka UI: http://localhost:8080"
	@echo "Schema Registry: http://localhost:8081"

down:
	@echo "Stopping Kafka service..."
	docker-compose down

status:
	@docker-compose ps

logs:
	@docker-compose logs -f

clean:
	@echo "Removing Kafka volumes..."
	docker-compose down -v

test-producer:
	@echo "Testing Kafka producer..."
	docker exec kafka-broker kafka-console-producer \
		--bootstrap-server localhost:9092 \
		--topic test-topic

test-consumer:
	@echo "Testing Kafka consumer..."
	docker exec kafka-broker kafka-console-consumer \
		--bootstrap-server localhost:9092 \
		--topic test-topic \
		--from-beginning

list-topics:
	@docker exec kafka-broker kafka-topics \
		--bootstrap-server localhost:9092 \
		--list

create-topics:
	@echo "Creating required topics..."
	@docker exec kafka-broker kafka-topics \
		--bootstrap-server localhost:9092 \
		--create --if-not-exists \
		--topic bookings_raw \
		--partitions 3 \
		--replication-factor 1
	@docker exec kafka-broker kafka-topics \
		--bootstrap-server localhost:9092 \
		--create --if-not-exists \
		--topic booking_events_raw \
		--partitions 3 \
		--replication-factor 1
	@docker exec kafka-broker kafka-topics \
		--bootstrap-server localhost:9092 \
		--create --if-not-exists \
		--topic hotels_raw \
		--partitions 1 \
		--replication-factor 1
	@echo "Topics created successfully!"
