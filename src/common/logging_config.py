"""
Logging Configuration for SnappTrip Data Platform

Provides structured logging with JSON formatting for Loki integration.
"""

import logging
import sys
from typing import Optional

from .config import config


def setup_logging(
    name: Optional[str] = None,
    level: Optional[str] = None
) -> logging.Logger:
    """
    Setup logging configuration
    
    Args:
        name: Logger name (defaults to root)
        level: Log level (defaults to config.monitoring.log_level)
        
    Returns:
        Configured logger
    """
    log_level = level or config.monitoring.log_level
    
    # Create logger
    logger = logging.getLogger(name)
    logger.setLevel(getattr(logging, log_level.upper()))
    
    # Remove existing handlers
    logger.handlers = []
    
    # Create console handler
    handler = logging.StreamHandler(sys.stdout)
    handler.setLevel(getattr(logging, log_level.upper()))
    
    # Create formatter
    formatter = logging.Formatter(
        '%(asctime)s - %(name)s - %(levelname)s - %(message)s',
        datefmt='%Y-%m-%d %H:%M:%S'
    )
    handler.setFormatter(formatter)
    
    # Add handler to logger
    logger.addHandler(handler)
    
    return logger
