"""
Kafka Producer - Push data to Kafka topics.

This module handles producing messages to Kafka topics with Avro serialization.
"""

import json
import logging
import os
from typing import Dict, List, Any, Optional
from datetime import datetime
from confluent_kafka import Producer
from confluent_kafka.avro import AvroProducer
import pandas as pd

logger = logging.getLogger(__name__)

_DEFAULT_BOOTSTRAP = os.getenv("KAFKA_BOOTSTRAP_SERVERS", "localhost:19092")
_DEFAULT_SCHEMA_REGISTRY = os.getenv("SCHEMA_REGISTRY_URL", "http://localhost:8081")


class KafkaProducer:
    """Kafka producer for sending messages to topics."""
    
    def __init__(self, bootstrap_servers: Optional[str] = None, 
                 schema_registry_url: Optional[str] = None):
        """
        Initialize Kafka producer.
        
        Args:
            bootstrap_servers: Kafka broker addresses (str or list of str). Defaults to KAFKA_BOOTSTRAP_SERVERS env.
            schema_registry_url: Schema registry URL for Avro. Defaults to SCHEMA_REGISTRY_URL env.
        """
        bootstrap_servers = bootstrap_servers or _DEFAULT_BOOTSTRAP
        schema_registry_url = schema_registry_url or _DEFAULT_SCHEMA_REGISTRY
        # Confluent Kafka expects comma-separated string, not a list
        if isinstance(bootstrap_servers, (list, tuple)):
            bootstrap_servers = ','.join(str(s) for s in bootstrap_servers)
        self.bootstrap_servers = bootstrap_servers
        self.schema_registry_url = schema_registry_url
        
        # Producer config: generous timeouts and acks=1 so leader ack is enough (avoids timeout on slow replicas)
        self.producer_config = {
            'bootstrap.servers': bootstrap_servers,
            'client.id': 'snapptrip-producer',
            'acks': 1,                         # leader ack only (faster, fewer timeouts)
            'message.timeout.ms': 120000,     # 2 min for message send ack
            'request.timeout.ms': 60000,      # 1 min for metadata/requests
            'delivery.timeout.ms': 300000,    # 5 min total (retries included)
            'retries': 6,
            'retry.backoff.ms': 1000,
        }
        
        self.producer = Producer(self.producer_config)
        logger.info(f"Kafka producer initialized: {bootstrap_servers}")
    
    def produce(self, topic: str, key: str, value: Dict[str, Any]):
        """
        Produce a message to Kafka topic.
        
        Args:
            topic: Kafka topic name
            key: Message key
            value: Message value (dict)
        """
        try:
            self.producer.produce(
                topic=topic,
                key=key.encode('utf-8'),
                value=json.dumps(value).encode('utf-8'),
                callback=self._delivery_callback
            )
            self.producer.poll(0)
        except Exception as e:
            logger.error(f"Error producing message: {e}")
            raise
    
    def flush(self):
        """Flush pending messages."""
        self.producer.flush()
        logger.info("Producer flushed")
    
    @staticmethod
    def _delivery_callback(err, msg):
        """Callback for message delivery."""
        if err:
            logger.error(f'Message delivery failed: {err}')
        else:
            logger.debug(f'Message delivered to {msg.topic()} [{msg.partition()}]')


def produce_bookings(csv_path: str, topic: str = 'bookings_raw', 
                    bootstrap_servers: Optional[str] = None):
    """
    Produce booking records from CSV to Kafka.
    
    Args:
        csv_path: Path to bookings CSV file
        topic: Kafka topic name
        bootstrap_servers: Kafka broker addresses (defaults to KAFKA_BOOTSTRAP_SERVERS env)
    """
    producer = KafkaProducer(bootstrap_servers=bootstrap_servers)
    df = pd.read_csv(csv_path)
    
    logger.info(f"Producing {len(df)} booking records to {topic}")
    
    for _, row in df.iterrows():
        message = {
            'booking_id': str(row['booking_id']),
            'user_id': str(row['user_id']),
            'hotel_id': str(row['hotel_id']),
            'status': str(row['status']),
            'price': float(row['price']),
            'created_at': str(row['created_at']),
            'updated_at': str(row['updated_at'])
        }
        producer.produce(topic, key=message['booking_id'], value=message)
    
    producer.flush()
    logger.info(f"Successfully produced {len(df)} bookings")


def produce_events(csv_path: str, topic: str = 'booking_events_raw',
                  bootstrap_servers: Optional[str] = None):
    """
    Produce booking event records from CSV to Kafka.
    
    Args:
        csv_path: Path to events CSV file
        topic: Kafka topic name
        bootstrap_servers: Kafka broker addresses (defaults to KAFKA_BOOTSTRAP_SERVERS env)
    """
    producer = KafkaProducer(bootstrap_servers=bootstrap_servers)
    df = pd.read_csv(csv_path)
    
    logger.info(f"Producing {len(df)} event records to {topic}")
    
    for _, row in df.iterrows():
        message = {
            'booking_id': str(row['booking_id']),
            'event_type': str(row['event_type']),
            'event_ts': str(row['event_ts'])
        }
        producer.produce(topic, key=message['booking_id'], value=message)
    
    producer.flush()
    logger.info(f"Successfully produced {len(df)} events")


def produce_hotels(csv_path: str, topic: str = 'hotels_raw',
                  bootstrap_servers: Optional[str] = None):
    """
    Produce hotel records from CSV to Kafka.
    
    Args:
        csv_path: Path to hotels CSV file
        topic: Kafka topic name
        bootstrap_servers: Kafka broker addresses (defaults to KAFKA_BOOTSTRAP_SERVERS env)
    """
    producer = KafkaProducer(bootstrap_servers=bootstrap_servers)
    df = pd.read_csv(csv_path)
    
    logger.info(f"Producing {len(df)} hotel records to {topic}")
    
    for _, row in df.iterrows():
        message = {
            'hotel_id': str(row['hotel_id']),
            'city': str(row['city']),
            'star_rating': int(row['star_rating'])
        }
        producer.produce(topic, key=message['hotel_id'], value=message)
    
    producer.flush()
    logger.info(f"Successfully produced {len(df)} hotels")


if __name__ == '__main__':
    # Example usage
    logging.basicConfig(level=logging.INFO)
    
    # Produce sample data
    produce_bookings('data/bookings_raw.csv')
    produce_events('data/booking_events_raw.csv')
    produce_hotels('data/hotels_raw.csv')
