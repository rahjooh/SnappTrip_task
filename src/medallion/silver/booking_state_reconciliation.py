"""
Silver Layer: Booking State Reconciliation

Reconciles booking state from multiple sources (bookings_raw and booking_events_raw).
Handles late-arriving events, deduplication, and applies business rules.
"""

import logging
from datetime import datetime, timedelta
from pyspark.sql import SparkSession, DataFrame, Window
from pyspark.sql.functions import (
    col, row_number, coalesce, lit, current_timestamp,
    when, max as spark_max, expr
)

from src.common.spark_session import create_spark_session
from src.common.config import config
from src.common.logging_config import setup_logging
from src.common.iceberg_utils import merge_into_iceberg, create_iceberg_table
from src.common.metrics import records_processed, processing_duration

logger = setup_logging(__name__)


class BookingStateReconciliation:
    """
    Reconcile booking state from multiple data sources
    
    Strategy:
    1. Deduplicate bookings_raw by (booking_id, max(updated_at))
    2. Deduplicate booking_events_raw by (booking_id, max(event_ts))
    3. Use event_ts as source of truth for status
    4. Use bookings_raw for attributes (user_id, hotel_id, price, created_at)
    5. Handle late-arriving events with watermarking
    """
    
    def __init__(self, spark: SparkSession):
        """
        Initialize reconciliation
        
        Args:
            spark: SparkSession
        """
        self.spark = spark
        self.watermark_delay = f"{config.pipeline.watermark_delay_hours} hours"
        
    def read_bronze_bookings(self) -> DataFrame:
        """Read bookings from Bronze layer"""
        logger.info("Reading bookings from Bronze...")
        
        df = self.spark.read \
            .format("iceberg") \
            .load(f"{config.iceberg.warehouse_path}/bronze/bookings_raw")
        
        logger.info(f"Read {df.count()} booking records from Bronze")
        return df
    
    def read_bronze_events(self) -> DataFrame:
        """Read events from Bronze layer"""
        logger.info("Reading events from Bronze...")
        
        df = self.spark.read \
            .format("iceberg") \
            .load(f"{config.iceberg.warehouse_path}/bronze/booking_events_raw")
        
        logger.info(f"Read {df.count()} event records from Bronze")
        return df
    
    def read_bronze_hotels(self) -> DataFrame:
        """Read hotels from Bronze layer"""
        logger.info("Reading hotels from Bronze...")
        
        df = self.spark.read \
            .format("iceberg") \
            .load(f"{config.iceberg.warehouse_path}/bronze/hotels_raw")
        
        logger.info(f"Read {df.count()} hotel records from Bronze")
        return df
    
    def deduplicate_bookings(self, bookings_df: DataFrame) -> DataFrame:
        """
        Deduplicate bookings by taking latest updated_at per booking_id
        
        Args:
            bookings_df: Raw bookings DataFrame
            
        Returns:
            Deduplicated DataFrame
        """
        logger.info("Deduplicating bookings...")
        
        window_spec = Window.partitionBy("booking_id").orderBy(col("updated_at").desc())
        
        deduped_df = bookings_df \
            .withColumn("row_num", row_number().over(window_spec)) \
            .filter(col("row_num") == 1) \
            .drop("row_num")
        
        logger.info(f"Deduplicated to {deduped_df.count()} unique bookings")
        return deduped_df
    
    def deduplicate_events(self, events_df: DataFrame) -> DataFrame:
        """
        Deduplicate events by taking latest event_ts per booking_id
        
        Args:
            events_df: Raw events DataFrame
            
        Returns:
            Deduplicated DataFrame
        """
        logger.info("Deduplicating events...")
        
        window_spec = Window.partitionBy("booking_id").orderBy(col("event_ts").desc())
        
        deduped_df = events_df \
            .withColumn("row_num", row_number().over(window_spec)) \
            .filter(col("row_num") == 1) \
            .drop("row_num")
        
        logger.info(f"Deduplicated to {deduped_df.count()} unique events")
        return deduped_df
    
    def reconcile_state(
        self,
        bookings_df: DataFrame,
        events_df: DataFrame
    ) -> DataFrame:
        """
        Reconcile booking state between bookings and events
        
        Args:
            bookings_df: Deduplicated bookings
            events_df: Deduplicated events
            
        Returns:
            Reconciled DataFrame
        """
        logger.info("Reconciling booking state...")
        
        # Select relevant columns from bookings
        bookings_clean = bookings_df.select(
            col("booking_id"),
            col("user_id"),
            col("hotel_id"),
            col("status").alias("booking_status"),
            col("price"),
            col("created_at"),
            col("updated_at").alias("booking_updated_at")
        )
        
        # Select relevant columns from events
        events_clean = events_df.select(
            col("booking_id").alias("event_booking_id"),
            col("event_type").alias("event_status"),
            col("event_ts")
        )
        
        # Left join bookings with events
        reconciled_df = bookings_clean.join(
            events_clean,
            bookings_clean.booking_id == events_clean.event_booking_id,
            "left"
        )
        
        # Reconciliation logic:
        # - Use event_status if available and event_ts > booking_updated_at
        # - Otherwise use booking_status
        # - Use event_ts as last_updated_ts if event is newer
        reconciled_df = reconciled_df.select(
            col("booking_id"),
            col("user_id"),
            col("hotel_id"),
            when(
                col("event_status").isNotNull() & (col("event_ts") > col("booking_updated_at")),
                col("event_status")
            ).otherwise(col("booking_status")).alias("status"),
            col("price"),
            col("created_at"),
            when(
                col("event_ts").isNotNull() & (col("event_ts") > col("booking_updated_at")),
                col("event_ts")
            ).otherwise(col("booking_updated_at")).alias("last_updated_ts"),
            current_timestamp().alias("processing_ts"),
            when(
                col("event_status").isNotNull() & (col("event_ts") > col("booking_updated_at")),
                lit("events_raw")
            ).when(
                col("event_status").isNotNull(),
                lit("reconciled")
            ).otherwise(lit("bookings_raw")).alias("data_source")
        )
        
        logger.info(f"Reconciled {reconciled_df.count()} bookings")
        return reconciled_df
    
    def apply_business_rules(self, df: DataFrame) -> DataFrame:
        """
        Apply business rules and validations
        
        Args:
            df: Reconciled DataFrame
            
        Returns:
            Validated DataFrame
        """
        logger.info("Applying business rules...")
        
        # Filter out invalid records
        validated_df = df.filter(
            # Price must be positive
            (col("price") > 0) &
            # Status must be valid
            col("status").isin(["created", "confirmed", "cancelled"]) &
            # created_at must be <= updated_at
            (col("created_at") <= col("updated_at")) &
            # Required fields must not be null
            col("booking_id").isNotNull() &
            col("user_id").isNotNull() &
            col("hotel_id").isNotNull()
        )
        
        rejected_count = df.count() - validated_df.count()
        if rejected_count > 0:
            logger.warning(f"Rejected {rejected_count} records due to business rule violations")
        
        return validated_df
    
    def enrich_with_hotels(
        self,
        bookings_df: DataFrame,
        hotels_df: DataFrame
    ) -> DataFrame:
        """
        Enrich bookings with hotel information
        
        Args:
            bookings_df: Reconciled bookings
            hotels_df: Hotels reference data
            
        Returns:
            Enriched DataFrame
        """
        logger.info("Enriching with hotel data...")
        
        # Deduplicate hotels
        window_spec = Window.partitionBy("hotel_id").orderBy(col("processing_ts").desc())
        hotels_deduped = hotels_df \
            .withColumn("row_num", row_number().over(window_spec)) \
            .filter(col("row_num") == 1) \
            .drop("row_num")
        
        # Join with hotels
        enriched_df = bookings_df.join(
            hotels_deduped.select("hotel_id", "city", "star_rating"),
            "hotel_id",
            "left"
        )
        
        return enriched_df
    
    def write_to_silver(self, df: DataFrame):
        """
        Write reconciled data to Silver layer
        
        Args:
            df: Reconciled DataFrame
        """
        logger.info("Writing to Silver layer...")
        
        # Create Silver table if not exists
        create_iceberg_table(
            self.spark,
            table_name="bookings",
            schema="""
                booking_id STRING NOT NULL,
                user_id STRING NOT NULL,
                hotel_id STRING NOT NULL,
                status STRING NOT NULL,
                price DECIMAL(10,2) NOT NULL,
                created_at TIMESTAMP NOT NULL,
                last_updated_ts TIMESTAMP NOT NULL,
                processing_ts TIMESTAMP NOT NULL,
                data_source STRING,
                city STRING,
                star_rating INT
            """,
            partition_by="days(created_at)",
            namespace="silver"
        )
        
        # Write to Iceberg using MERGE (upsert)
        merge_into_iceberg(
            self.spark,
            df,
            "bookings",
            "booking_id",
            namespace="silver"
        )
        
        logger.info(f"Written {df.count()} records to Silver layer")
    
    def run(self):
        """Execute the complete reconciliation process"""
        logger.info("Starting Silver layer reconciliation...")
        
        start_time = datetime.now()
        
        try:
            # Read Bronze data
            bookings_df = self.read_bronze_bookings()
            events_df = self.read_bronze_events()
            hotels_df = self.read_bronze_hotels()
            
            # Deduplicate
            bookings_deduped = self.deduplicate_bookings(bookings_df)
            events_deduped = self.deduplicate_events(events_df)
            
            # Reconcile state
            reconciled_df = self.reconcile_state(bookings_deduped, events_deduped)
            
            # Apply business rules
            validated_df = self.apply_business_rules(reconciled_df)
            
            # Enrich with hotels
            enriched_df = self.enrich_with_hotels(validated_df, hotels_df)
            
            # Write to Silver
            self.write_to_silver(enriched_df)
            
            # Record metrics
            duration = (datetime.now() - start_time).total_seconds()
            records_processed.labels(layer="silver", table="bookings").inc(enriched_df.count())
            processing_duration.labels(layer="silver", job="reconciliation").observe(duration)
            
            logger.info(f"Silver layer reconciliation completed in {duration:.2f} seconds")
            
        except Exception as e:
            logger.error(f"Error in Silver layer reconciliation: {e}", exc_info=True)
            raise


def main():
    """Main entry point"""
    logger.info("Starting Silver layer booking state reconciliation...")
    
    # Create Spark session
    spark = create_spark_session(
        app_name="Silver_Booking_State_Reconciliation",
        iceberg_enabled=True
    )
    
    # Create reconciliation instance
    reconciliation = BookingStateReconciliation(spark)
    
    # Run reconciliation
    reconciliation.run()
    
    spark.stop()


if __name__ == "__main__":
    main()
