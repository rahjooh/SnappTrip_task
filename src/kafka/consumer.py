"""
Kafka Consumer - Read data from Kafka topics.

This module handles consuming messages from Kafka topics.
"""

import json
import logging
from typing import Callable, Optional, Dict, Any
from confluent_kafka import Consumer, KafkaError

logger = logging.getLogger(__name__)


class KafkaConsumer:
    """Kafka consumer for reading messages from topics."""
    
    def __init__(self, bootstrap_servers: str = 'localhost:19092',
                 group_id: str = 'snapptrip-consumer',
                 auto_offset_reset: str = 'earliest'):
        """
        Initialize Kafka consumer.
        
        Args:
            bootstrap_servers: Kafka broker addresses
            group_id: Consumer group ID
            auto_offset_reset: Offset reset strategy ('earliest' or 'latest')
        """
        self.consumer_config = {
            'bootstrap.servers': bootstrap_servers,
            'group.id': group_id,
            'auto.offset.reset': auto_offset_reset,
            'enable.auto.commit': True
        }
        
        self.consumer = Consumer(self.consumer_config)
        logger.info(f"Kafka consumer initialized: {bootstrap_servers}, group: {group_id}")
    
    def subscribe(self, topics: list):
        """
        Subscribe to Kafka topics.
        
        Args:
            topics: List of topic names
        """
        self.consumer.subscribe(topics)
        logger.info(f"Subscribed to topics: {topics}")
    
    def consume(self, callback: Callable[[Dict[str, Any]], None], 
                timeout: float = 1.0, max_messages: Optional[int] = None):
        """
        Consume messages and process with callback.
        
        Args:
            callback: Function to process each message
            timeout: Poll timeout in seconds
            max_messages: Maximum number of messages to consume (None = infinite)
        """
        messages_consumed = 0
        
        try:
            while True:
                msg = self.consumer.poll(timeout)
                
                if msg is None:
                    continue
                
                if msg.error():
                    if msg.error().code() == KafkaError._PARTITION_EOF:
                        logger.debug(f'Reached end of partition: {msg.topic()} [{msg.partition()}]')
                    else:
                        logger.error(f'Consumer error: {msg.error()}')
                    continue
                
                # Decode message
                try:
                    value = json.loads(msg.value().decode('utf-8'))
                    key = msg.key().decode('utf-8') if msg.key() else None
                    
                    message_data = {
                        'topic': msg.topic(),
                        'partition': msg.partition(),
                        'offset': msg.offset(),
                        'key': key,
                        'value': value,
                        'timestamp': msg.timestamp()
                    }
                    
                    # Process message with callback
                    callback(message_data)
                    messages_consumed += 1
                    
                    if max_messages and messages_consumed >= max_messages:
                        logger.info(f"Reached max messages limit: {max_messages}")
                        break
                        
                except json.JSONDecodeError as e:
                    logger.error(f"Failed to decode message: {e}")
                except Exception as e:
                    logger.error(f"Error processing message: {e}")
                    
        except KeyboardInterrupt:
            logger.info("Consumer interrupted by user")
        finally:
            self.close()
    
    def close(self):
        """Close the consumer."""
        self.consumer.close()
        logger.info("Consumer closed")


def consume_topic(topic: str, callback: Callable[[Dict[str, Any]], None],
                 bootstrap_servers: str = 'localhost:9092',
                 max_messages: Optional[int] = None):
    """
    Consume messages from a Kafka topic.
    
    Args:
        topic: Kafka topic name
        callback: Function to process each message
        bootstrap_servers: Kafka broker addresses
        max_messages: Maximum number of messages to consume
    """
    consumer = KafkaConsumer(bootstrap_servers)
    consumer.subscribe([topic])
    consumer.consume(callback, max_messages=max_messages)


if __name__ == '__main__':
    # Example usage
    logging.basicConfig(level=logging.INFO)
    
    def print_message(msg: Dict[str, Any]):
        """Example callback to print messages."""
        print(f"Topic: {msg['topic']}, Key: {msg['key']}, Value: {msg['value']}")
    
    # Consume from bookings topic
    consume_topic('bookings_raw', print_message, max_messages=10)
