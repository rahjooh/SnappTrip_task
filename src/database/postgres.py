"""
PostgreSQL Database - Write Gold layer data to PostgreSQL.

This module handles all PostgreSQL database operations for the Gold layer.
"""

import logging
import psycopg
from psycopg import Connection
from typing import Optional, Dict, Any, List
import pandas as pd
from pyspark.sql import DataFrame

logger = logging.getLogger(__name__)


class PostgresWriter:
    """PostgreSQL writer for Gold layer data."""
    
    def __init__(self, host: str = 'localhost', port: int = 5432,
                 database: str = 'snapptrip_analytics',
                 user: str = 'snapptrip', password: str = 'snapptrip123'):
        """
        Initialize PostgreSQL writer.
        
        Args:
            host: PostgreSQL host
            port: PostgreSQL port
            database: Database name
            user: Username
            password: Password
        """
        self.connection_params = {
            'host': host,
            'port': port,
            'dbname': database,
            'user': user,
            'password': password
        }
        logger.info(f"PostgreSQL writer initialized: {host}:{port}/{database}")
    
    def get_connection(self) -> Connection:
        """Get PostgreSQL connection."""
        return psycopg.connect(**self.connection_params)
    
    def create_gold_tables(self):
        """Create Gold layer tables if they don't exist."""
        with self.get_connection() as conn:
            with conn.cursor() as cur:
                # Create gold_daily_kpis table
                cur.execute("""
                    CREATE TABLE IF NOT EXISTS gold_daily_kpis (
                        booking_date DATE NOT NULL,
                        city VARCHAR(100) NOT NULL,
                        total_bookings INTEGER NOT NULL,
                        confirmed_bookings INTEGER NOT NULL,
                        cancelled_bookings INTEGER NOT NULL,
                        cancellation_rate DECIMAL(5,2),
                        total_revenue DECIMAL(15,2),
                        avg_booking_price DECIMAL(10,2),
                        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                        PRIMARY KEY (booking_date, city)
                    )
                """)
                conn.commit()
                logger.info("Gold tables created successfully")
    
    def write_dataframe(self, df: pd.DataFrame, table: str, if_exists: str = 'replace'):
        """
        Write pandas DataFrame to PostgreSQL.
        
        Args:
            df: Pandas DataFrame
            table: Table name
            if_exists: What to do if table exists ('fail', 'replace', 'append')
        """
        from sqlalchemy import create_engine
        
        engine = create_engine(
            f"postgresql://{self.connection_params['user']}:{self.connection_params['password']}"
            f"@{self.connection_params['host']}:{self.connection_params['port']}"
            f"/{self.connection_params['dbname']}"
        )
        
        df.to_sql(table, engine, if_exists=if_exists, index=False)
        logger.info(f"Wrote {len(df)} rows to {table}")
    
    def write_spark_dataframe(self, df: DataFrame, table: str, mode: str = 'overwrite'):
        """
        Write Spark DataFrame to PostgreSQL.
        
        Args:
            df: Spark DataFrame
            table: Table name
            mode: Write mode ('overwrite', 'append', 'ignore', 'error')
        """
        jdbc_url = (
            f"jdbc:postgresql://{self.connection_params['host']}:{self.connection_params['port']}"
            f"/{self.connection_params['dbname']}"
        )
        
        properties = {
            "user": self.connection_params['user'],
            "password": self.connection_params['password'],
            "driver": "org.postgresql.Driver"
        }
        
        df.write \
            .format("jdbc") \
            .option("url", jdbc_url) \
            .option("dbtable", table) \
            .option("mode", mode) \
            .options(**properties) \
            .save()
        
        logger.info(f"Wrote Spark DataFrame to {table}")
    
    def execute_query(self, query: str) -> List[tuple]:
        """
        Execute SQL query and return results.
        
        Args:
            query: SQL query string
            
        Returns:
            List of tuples with query results
        """
        with self.get_connection() as conn:
            with conn.cursor() as cur:
                cur.execute(query)
                results = cur.fetchall()
                logger.info(f"Query executed, returned {len(results)} rows")
                return results
    
    def truncate_table(self, table: str):
        """
        Truncate a table.
        
        Args:
            table: Table name
        """
        with self.get_connection() as conn:
            with conn.cursor() as cur:
                cur.execute(f"TRUNCATE TABLE {table}")
                conn.commit()
                logger.info(f"Table {table} truncated")


if __name__ == '__main__':
    logging.basicConfig(level=logging.INFO)
    
    # Example usage
    writer = PostgresWriter()
    writer.create_gold_tables()
