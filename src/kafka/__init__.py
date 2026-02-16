"""
Kafka module for producing and consuming messages.
"""

from .producer import KafkaProducer, produce_bookings, produce_events, produce_hotels
from .consumer import KafkaConsumer, consume_topic

__all__ = [
    'KafkaProducer',
    'KafkaConsumer',
    'produce_bookings',
    'produce_events',
    'produce_hotels',
    'consume_topic',
]
