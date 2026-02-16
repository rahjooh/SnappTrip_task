"""
Great Expectations Data Validator.

This module provides data quality validation using Great Expectations.
"""

import logging
from typing import Dict, Any, Optional
from pyspark.sql import DataFrame
import great_expectations as gx
from great_expectations.core.batch import RuntimeBatchRequest
from great_expectations.data_context import DataContext

logger = logging.getLogger(__name__)


class DataValidator:
    """Data validator using Great Expectations."""
    
    def __init__(self, context_root_dir: str = './great_expectations'):
        """
        Initialize data validator.
        
        Args:
            context_root_dir: Path to Great Expectations context
        """
        self.context = DataContext(context_root_dir=context_root_dir)
        logger.info("Data validator initialized")
    
    def validate_dataframe(self, df: DataFrame, expectation_suite_name: str,
                          batch_identifier: str = "default") -> Dict[str, Any]:
        """
        Validate a Spark DataFrame against an expectation suite.
        
        Args:
            df: Spark DataFrame to validate
            expectation_suite_name: Name of the expectation suite
            batch_identifier: Identifier for this batch
            
        Returns:
            Validation results dictionary
        """
        logger.info(f"Validating DataFrame with suite: {expectation_suite_name}")
        
        # Create runtime batch request
        batch_request = RuntimeBatchRequest(
            datasource_name="spark_datasource",
            data_connector_name="runtime_data_connector",
            data_asset_name="spark_dataframe",
            runtime_parameters={"batch_data": df},
            batch_identifiers={"batch_id": batch_identifier}
        )
        
        # Get validator
        validator = self.context.get_validator(
            batch_request=batch_request,
            expectation_suite_name=expectation_suite_name
        )
        
        # Run validation
        results = validator.validate()
        
        # Log results
        if results.success:
            logger.info(f"Validation passed: {expectation_suite_name}")
        else:
            logger.warning(f"Validation failed: {expectation_suite_name}")
            logger.warning(f"Failed expectations: {results.statistics['unsuccessful_expectations']}")
        
        return results.to_json_dict()
    
    def create_silver_expectations(self) -> str:
        """
        Create expectation suite for Silver layer.
        
        Returns:
            Expectation suite name
        """
        suite_name = "silver_booking_state_suite"
        
        try:
            suite = self.context.get_expectation_suite(suite_name)
            logger.info(f"Expectation suite already exists: {suite_name}")
        except:
            suite = self.context.create_expectation_suite(suite_name)
            
            # Add expectations
            expectations = [
                {
                    "expectation_type": "expect_column_values_to_not_be_null",
                    "kwargs": {"column": "booking_id"}
                },
                {
                    "expectation_type": "expect_column_values_to_not_be_null",
                    "kwargs": {"column": "user_id"}
                },
                {
                    "expectation_type": "expect_column_values_to_not_be_null",
                    "kwargs": {"column": "hotel_id"}
                },
                {
                    "expectation_type": "expect_column_values_to_be_in_set",
                    "kwargs": {
                        "column": "status",
                        "value_set": ["created", "confirmed", "cancelled"]
                    }
                },
                {
                    "expectation_type": "expect_column_values_to_be_between",
                    "kwargs": {
                        "column": "price",
                        "min_value": 0,
                        "strict_min": True
                    }
                }
            ]
            
            for exp in expectations:
                suite.add_expectation(exp)
            
            self.context.save_expectation_suite(suite)
            logger.info(f"Created expectation suite: {suite_name}")
        
        return suite_name


def validate_silver_layer(df: DataFrame, context_root_dir: str = './great_expectations') -> bool:
    """
    Validate Silver layer DataFrame.
    
    Args:
        df: Spark DataFrame to validate
        context_root_dir: Path to Great Expectations context
        
    Returns:
        True if validation passed, False otherwise
    """
    validator = DataValidator(context_root_dir)
    suite_name = validator.create_silver_expectations()
    results = validator.validate_dataframe(df, suite_name)
    return results.get('success', False)


if __name__ == '__main__':
    logging.basicConfig(level=logging.INFO)
    
    # Example usage
    validator = DataValidator()
    validator.create_silver_expectations()
