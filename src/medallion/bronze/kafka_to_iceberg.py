"""
Bronze Layer: Kafka to Iceberg Streaming Ingestion

Reads data from Kafka topics and writes to Iceberg tables in HDFS.
Implements Spark Structured Streaming with checkpointing and monitoring.
"""

import logging
from pyspark.sql import SparkSession
from pyspark.sql.functions import (
    col, from_json, current_timestamp, expr
)
from pyspark.sql.types import (
    StructType, StructField, StringType, DecimalType,
    TimestampType, IntegerType
)

from src.common.spark_session import create_spark_session
from src.common.config import config
from src.common.logging_config import setup_logging
from src.common.metrics import records_processed, kafka_messages_consumed

logger = setup_logging(__name__)


# Define schemas for Kafka messages
BOOKING_SCHEMA = StructType([
    StructField("booking_id", StringType(), False),
    StructField("user_id", StringType(), False),
    StructField("hotel_id", StringType(), False),
    StructField("status", StringType(), False),
    StructField("price", DecimalType(10, 2), False),
    StructField("created_at", TimestampType(), False),
    StructField("updated_at", TimestampType(), False)
])

BOOKING_EVENT_SCHEMA = StructType([
    StructField("booking_id", StringType(), False),
    StructField("event_type", StringType(), False),
    StructField("event_ts", TimestampType(), False),
    StructField("event_id", StringType(), True),
    StructField("metadata", StringType(), True)
])

HOTEL_SCHEMA = StructType([
    StructField("hotel_id", StringType(), False),
    StructField("city", StringType(), False),
    StructField("star_rating", IntegerType(), False),
    StructField("name", StringType(), True),
    StructField("updated_at", TimestampType(), True)
])


class BronzeIngestion:
    """Bronze layer streaming ingestion from Kafka to Iceberg"""
    
    def __init__(self, spark: SparkSession):
        """
        Initialize Bronze ingestion
        
        Args:
            spark: SparkSession
        """
        self.spark = spark
        self.kafka_bootstrap_servers = config.kafka.bootstrap_servers
        self.checkpoint_location = config.pipeline.checkpoint_location
        
    def read_kafka_stream(
        self,
        topic: str,
        schema: StructType
    ):
        """
        Read streaming data from Kafka
        
        Args:
            topic: Kafka topic name
            schema: Schema for parsing JSON messages
            
        Returns:
            Streaming DataFrame
        """
        logger.info(f"Reading from Kafka topic: {topic}")
        
        # Read from Kafka
        kafka_df = self.spark.readStream \
            .format("kafka") \
            .option("kafka.bootstrap.servers", self.kafka_bootstrap_servers) \
            .option("subscribe", topic) \
            .option("startingOffsets", "earliest") \
            .option("maxOffsetsPerTrigger", 10000) \
            .option("failOnDataLoss", "false") \
            .load()
        
        # Parse JSON value
        parsed_df = kafka_df.select(
            col("key").cast("string").alias("key"),
            from_json(col("value").cast("string"), schema).alias("data"),
            col("topic"),
            col("partition"),
            col("offset"),
            col("timestamp").alias("kafka_timestamp")
        ).select(
            "key",
            "data.*",
            "topic",
            "partition",
            "offset",
            "kafka_timestamp",
            current_timestamp().alias("processing_ts")
        )
        
        return parsed_df
    
    def write_to_iceberg(
        self,
        df,
        table_name: str,
        checkpoint_suffix: str
    ):
        """
        Write streaming DataFrame to Iceberg table
        
        Args:
            df: Streaming DataFrame
            table_name: Target Iceberg table name
            checkpoint_suffix: Suffix for checkpoint location
        """
        logger.info(f"Writing to Iceberg table: local.bronze.{table_name}")
        
        query = df.writeStream \
            .format("iceberg") \
            .outputMode("append") \
            .option("path", f"{config.iceberg.warehouse_path}/bronze/{table_name}") \
            .option("checkpointLocation", f"{self.checkpoint_location}/bronze_{checkpoint_suffix}") \
            .trigger(processingTime="30 seconds") \
            .start()
        
        return query
    
    def ingest_bookings(self):
        """Ingest bookings from Kafka to Iceberg"""
        logger.info("Starting bookings ingestion...")
        
        # Read from Kafka
        bookings_df = self.read_kafka_stream("bookings.raw", BOOKING_SCHEMA)
        
        # Data quality checks
        bookings_df = bookings_df.filter(
            col("booking_id").isNotNull() &
            col("user_id").isNotNull() &
            col("hotel_id").isNotNull() &
            (col("price") > 0)
        )
        
        # Write to Iceberg
        query = self.write_to_iceberg(
            bookings_df,
            "bookings_raw",
            "bookings"
        )
        
        return query
    
    def ingest_events(self):
        """Ingest booking events from Kafka to Iceberg"""
        logger.info("Starting events ingestion...")
        
        # Read from Kafka
        events_df = self.read_kafka_stream("booking_events.raw", BOOKING_EVENT_SCHEMA)
        
        # Data quality checks
        events_df = events_df.filter(
            col("booking_id").isNotNull() &
            col("event_type").isNotNull() &
            col("event_ts").isNotNull()
        )
        
        # Write to Iceberg
        query = self.write_to_iceberg(
            events_df,
            "booking_events_raw",
            "events"
        )
        
        return query
    
    def ingest_hotels(self):
        """Ingest hotels from Kafka to Iceberg"""
        logger.info("Starting hotels ingestion...")
        
        # Read from Kafka
        hotels_df = self.read_kafka_stream("hotels.raw", HOTEL_SCHEMA)
        
        # Data quality checks
        hotels_df = hotels_df.filter(
            col("hotel_id").isNotNull() &
            col("city").isNotNull() &
            (col("star_rating").between(1, 5))
        )
        
        # Write to Iceberg
        query = self.write_to_iceberg(
            hotels_df,
            "hotels_raw",
            "hotels"
        )
        
        return query
    
    def run_all(self):
        """Run all ingestion streams"""
        logger.info("Starting all Bronze ingestion streams...")
        
        # Start all streams
        bookings_query = self.ingest_bookings()
        events_query = self.ingest_events()
        hotels_query = self.ingest_hotels()
        
        # Wait for termination
        try:
            self.spark.streams.awaitAnyTermination()
        except KeyboardInterrupt:
            logger.info("Stopping streams...")
            bookings_query.stop()
            events_query.stop()
            hotels_query.stop()


def main():
    """Main entry point"""
    logger.info("Starting Bronze layer ingestion...")
    
    # Create Spark session
    spark = create_spark_session(
        app_name="Bronze_Kafka_to_Iceberg",
        iceberg_enabled=True,
        kafka_enabled=True
    )
    
    # Create Bronze ingestion instance
    ingestion = BronzeIngestion(spark)
    
    # Run ingestion
    ingestion.run_all()


if __name__ == "__main__":
    main()
