"""
Unit Tests for Silver Layer Reconciliation

Tests the booking state reconciliation logic with various scenarios.
"""

import pytest
from datetime import datetime
from decimal import Decimal
from pyspark.sql import SparkSession
from chispa.dataframe_comparer import assert_df_equality


@pytest.fixture(scope="session")
def spark():
    """Create Spark session for testing"""
    return SparkSession.builder \
        .appName("test_silver_reconciliation") \
        .master("local[2]") \
        .config("spark.sql.shuffle.partitions", "2") \
        .getOrCreate()


def test_late_arriving_event_handling(spark):
    """Test that late-arriving events take precedence"""
    # Given: Booking updated at 10:10, but event arrived at 10:05
    bookings_data = [
        ("b1", "u1", "h1", "confirmed", Decimal("120.00"), 
         datetime(2025, 1, 1, 10, 0), datetime(2025, 1, 1, 10, 10))
    ]
    bookings_df = spark.createDataFrame(
        bookings_data,
        ["booking_id", "user_id", "hotel_id", "status", "price", "created_at", "updated_at"]
    )
    
    events_data = [
        ("b1", "cancelled", datetime(2025, 1, 1, 10, 5))
    ]
    events_df = spark.createDataFrame(
        events_data,
        ["booking_id", "event_type", "event_ts"]
    )
    
    # When: Reconcile (simplified logic for test)
    from src.medallion.silver.booking_state_reconciliation import BookingStateReconciliation
    reconciliation = BookingStateReconciliation(spark)
    result_df = reconciliation.reconcile_state(bookings_df, events_df)
    
    # Then: Event status should NOT take precedence (event_ts < updated_at)
    assert result_df.filter("booking_id = 'b1'").select("status").collect()[0][0] == "confirmed"


def test_duplicate_handling(spark):
    """Test deduplication of bookings by latest updated_at"""
    # Given: Multiple booking records with different timestamps
    bookings_data = [
        ("b1", "u1", "h1", "created", Decimal("120.00"), 
         datetime(2025, 1, 1, 10, 0), datetime(2025, 1, 1, 10, 0)),
        ("b1", "u1", "h1", "confirmed", Decimal("120.00"), 
         datetime(2025, 1, 1, 10, 0), datetime(2025, 1, 1, 10, 10)),
        ("b1", "u1", "h1", "cancelled", Decimal("120.00"), 
         datetime(2025, 1, 1, 10, 0), datetime(2025, 1, 1, 10, 20))
    ]
    bookings_df = spark.createDataFrame(
        bookings_data,
        ["booking_id", "user_id", "hotel_id", "status", "price", "created_at", "updated_at"]
    )
    
    # When: Deduplicate
    from src.medallion.silver.booking_state_reconciliation import BookingStateReconciliation
    reconciliation = BookingStateReconciliation(spark)
    result_df = reconciliation.deduplicate_bookings(bookings_df)
    
    # Then: Should have only one record with latest status
    assert result_df.count() == 1
    assert result_df.select("status").collect()[0][0] == "cancelled"


def test_business_rule_validation(spark):
    """Test business rule validation filters invalid records"""
    # Given: Bookings with invalid data
    bookings_data = [
        ("b1", "u1", "h1", "confirmed", Decimal("120.00"), 
         datetime(2025, 1, 1, 10, 0), datetime(2025, 1, 1, 10, 10)),
        ("b2", "u2", "h2", "confirmed", Decimal("-50.00"),  # Invalid: negative price
         datetime(2025, 1, 1, 11, 0), datetime(2025, 1, 1, 11, 10)),
        ("b3", None, "h3", "confirmed", Decimal("150.00"),  # Invalid: null user_id
         datetime(2025, 1, 1, 12, 0), datetime(2025, 1, 1, 12, 10))
    ]
    bookings_df = spark.createDataFrame(
        bookings_data,
        ["booking_id", "user_id", "hotel_id", "status", "price", "created_at", "updated_at"]
    )
    
    # When: Apply business rules
    from src.medallion.silver.booking_state_reconciliation import BookingStateReconciliation
    reconciliation = BookingStateReconciliation(spark)
    result_df = reconciliation.apply_business_rules(bookings_df)
    
    # Then: Should filter out invalid records
    assert result_df.count() == 1
    assert result_df.select("booking_id").collect()[0][0] == "b1"


def test_event_status_precedence(spark):
    """Test that event status takes precedence when event is newer"""
    # Given: Event timestamp is after booking updated_at
    bookings_data = [
        ("b1", "u1", "h1", "created", Decimal("120.00"), 
         datetime(2025, 1, 1, 10, 0), datetime(2025, 1, 1, 10, 5))
    ]
    bookings_df = spark.createDataFrame(
        bookings_data,
        ["booking_id", "user_id", "hotel_id", "status", "price", "created_at", "updated_at"]
    )
    
    events_data = [
        ("b1", "confirmed", datetime(2025, 1, 1, 10, 10))
    ]
    events_df = spark.createDataFrame(
        events_data,
        ["booking_id", "event_type", "event_ts"]
    )
    
    # When: Reconcile
    from src.medallion.silver.booking_state_reconciliation import BookingStateReconciliation
    reconciliation = BookingStateReconciliation(spark)
    result_df = reconciliation.reconcile_state(bookings_df, events_df)
    
    # Then: Event status should take precedence
    assert result_df.filter("booking_id = 'b1'").select("status").collect()[0][0] == "confirmed"
