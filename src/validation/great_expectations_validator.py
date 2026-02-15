"""
Great Expectations Data Validator.

This module provides data quality validation using Great Expectations.
"""

import logging
from typing import Dict, Any, Optional
from pyspark.sql import DataFrame
import great_expectations as gx

logger = logging.getLogger(__name__)


class DataValidator:
    """Data validator using Great Expectations."""
    
    def __init__(self, context_root_dir: str = './great_expectations'):
        """
        Initialize data validator.
        
        Args:
            context_root_dir: Path to Great Expectations context
        """
        try:
            # Try to get existing context
            self.context = gx.get_context(context_root_dir=context_root_dir)
        except:
            # Create new context if it doesn't exist
            self.context = gx.get_context(context_root_dir=context_root_dir, create_new=True)
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
        
        try:
            # Get or create datasource using the modern API
            datasource_name = "spark_datasource"
            try:
                datasource = self.context.sources.get(datasource_name)
            except:
                # Create Spark datasource if it doesn't exist
                datasource = self.context.sources.add_spark(datasource_name)
                
            # Add data asset
            data_asset_name = "spark_dataframe"
            try:
                data_asset = datasource.get_asset(data_asset_name)
            except:
                data_asset = datasource.add_dataframe_asset(name=data_asset_name)
            
            # Create batch request
            batch_request = data_asset.build_batch_request(dataframe=df)
            
            # Get expectation suite
            expectation_suite = self.context.suites.get(expectation_suite_name)
            
            # Get validator
            validator = self.context.get_validator(
                batch_request=batch_request,
                expectation_suite=expectation_suite
            )
            
            # Run validation
            results = validator.validate()
            
            # Log results
            if results.success:
                logger.info(f"Validation passed: {expectation_suite_name}")
            else:
                logger.warning(f"Validation failed: {expectation_suite_name}")
                if hasattr(results, 'statistics'):
                    logger.warning(f"Failed expectations: {results.statistics.get('unsuccessful_expectations', 'Unknown')}")
            
            return results.to_json_dict()
            
        except Exception as e:
            logger.error(f"Validation error: {str(e)}")
            return {"success": False, "error": str(e)}
    
    def create_silver_expectations(self) -> str:
        """
        Create expectation suite for Silver layer.
        
        Returns:
            Expectation suite name
        """
        suite_name = "silver_booking_state_suite"
        
        # Create or get expectation suite
        try:
            suite = self.context.suites.get(suite_name)
            logger.info(f"Expectation suite already exists: {suite_name}")
            return suite_name
        except:
            pass
            
        # Create new suite
        suite = self.context.suites.add(gx.ExpectationSuite(name=suite_name))
        logger.info(f"Created new expectation suite: {suite_name}")
        
        # Define expectations using the fluent API
        expectations = [
            gx.expectations.ExpectColumnValuesToNotBeNull(column="booking_id"),
            gx.expectations.ExpectColumnValuesToNotBeNull(column="user_id"), 
            gx.expectations.ExpectColumnValuesToNotBeNull(column="hotel_id"),
            gx.expectations.ExpectColumnValuesToBeInSet(column="status", value_set=["created", "confirmed", "cancelled"]),
            gx.expectations.ExpectColumnValuesToBeBetween(column="price", min_value=0, strict_min=True)
        ]
        
        # Add expectations to suite
        for expectation in expectations:
            suite.add_expectation(expectation)
        
        logger.info(f"Added {len(expectations)} expectations to suite: {suite_name}")
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
