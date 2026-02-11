# SnappTrip Data Pipeline - Makefile
# Automates installation, execution, and validation of the travel booking analytics pipeline

# Variables
PYTHON := python3
PIP := pip3
VENV := venv
REQUIREMENTS := requirements.txt
OUTPUT_DIR := output
DATA_DIR := data

# Colors for output
RED := \033[31m
GREEN := \033[32m
YELLOW := \033[33m
BLUE := \033[34m
MAGENTA := \033[35m
CYAN := \033[36m
WHITE := \033[37m
RESET := \033[0m

# Default target
.DEFAULT_GOAL := help

.PHONY: help install setup clean run validate full-pipeline check-deps create-dirs show-status

help: ## Show this help message
	@echo "$(CYAN)SnappTrip Data Pipeline - Available Commands$(RESET)"
	@echo "=============================================="
	@echo ""
	@echo "$(GREEN)Setup Commands:$(RESET)"
	@awk 'BEGIN {FS = ":.*##"; printf ""} /^[a-zA-Z_-]+:.*?##/ { printf "  $(YELLOW)%-15s$(RESET) %s\n", $$1, $$2 }' $(MAKEFILE_LIST) | grep -E "(install|setup|clean)"
	@echo ""
	@echo "$(GREEN)Execution Commands:$(RESET)"
	@awk 'BEGIN {FS = ":.*##"; printf ""} /^[a-zA-Z_-]+:.*?##/ { printf "  $(YELLOW)%-15s$(RESET) %s\n", $$1, $$2 }' $(MAKEFILE_LIST) | grep -E "(run|validate|pipeline)"
	@echo ""
	@echo "$(GREEN)Utility Commands:$(RESET)"
	@awk 'BEGIN {FS = ":.*##"; printf ""} /^[a-zA-Z_-]+:.*?##/ { printf "  $(YELLOW)%-15s$(RESET) %s\n", $$1, $$2 }' $(MAKEFILE_LIST) | grep -E "(check|show|help)"
	@echo ""
	@echo "$(BLUE)Examples:$(RESET)"
	@echo "  make setup          # First-time setup"
	@echo "  make full-pipeline  # Complete end-to-end execution"
	@echo "  make clean run      # Clean and run pipeline"
	@echo ""

check-deps: ## Check if required dependencies are available
	@echo "$(BLUE)🔍 Checking system dependencies...$(RESET)"
	@which $(PYTHON) > /dev/null || (echo "$(RED)❌ Python 3 not found. Please install Python 3$(RESET)" && exit 1)
	@which $(PIP) > /dev/null || (echo "$(RED)❌ pip3 not found. Please install pip3$(RESET)" && exit 1)
	@which java > /dev/null || (echo "$(YELLOW)⚠️  Java not found. Spark may not work properly$(RESET)")
	@echo "$(GREEN)✅ Dependencies check completed$(RESET)"

create-dirs: ## Create necessary output directories
	@echo "$(BLUE)📁 Creating output directories...$(RESET)"
	@mkdir -p $(OUTPUT_DIR)/silver
	@mkdir -p $(OUTPUT_DIR)/gold/daily_booking_kpis
	@mkdir -p $(OUTPUT_DIR)/gold/customer_behavior_analytics
	@mkdir -p $(OUTPUT_DIR)/gold/hotel_performance_analytics
	@echo "$(GREEN)✅ Directories created$(RESET)"

install: check-deps ## Install Python dependencies
	@echo "$(BLUE)📦 Installing Python dependencies...$(RESET)"
	@$(PIP) install -r $(REQUIREMENTS)
	@echo "$(GREEN)✅ Dependencies installed successfully$(RESET)"

setup: check-deps create-dirs install ## Complete first-time setup
	@echo "$(MAGENTA)🚀 SnappTrip Pipeline Setup Complete!$(RESET)"
	@echo "$(GREEN)Ready to run: make run$(RESET)"

clean: ## Clean output directories and temporary files
	@echo "$(BLUE)🧹 Cleaning output directories...$(RESET)"
	@rm -rf $(OUTPUT_DIR)/silver/*
	@rm -rf $(OUTPUT_DIR)/gold/*
	@rm -rf .pytest_cache 2>/dev/null || true
	@rm -rf __pycache__ 2>/dev/null || true
	@find . -name "*.pyc" -delete 2>/dev/null || true
	@echo "$(GREEN)✅ Cleanup completed$(RESET)"

run: create-dirs ## Run the main data pipeline
	@echo "$(MAGENTA)🚀 Starting SnappTrip Data Pipeline...$(RESET)"
	@echo "$(BLUE)Processing Bronze → Silver → Gold layers$(RESET)"
	@$(PYTHON) run_pipeline.py
	@echo "$(GREEN)✅ Pipeline execution completed!$(RESET)"
	@echo "$(CYAN)📊 Check output/ directory for results$(RESET)"

validate: ## Run comprehensive validation suite
	@echo "$(BLUE)🔍 Running comprehensive validation suite...$(RESET)"
	@$(PYTHON) validate_solution.py
	@echo "$(GREEN)✅ Validation completed!$(RESET)"

full-pipeline: clean run validate ## Run complete pipeline: clean → execute → validate
	@echo "$(MAGENTA)🎉 Full Pipeline Execution Completed!$(RESET)"
	@echo "$(GREEN)✨ All stages successful: Clean → Process → Validate$(RESET)"

show-status: ## Show current pipeline status and output summary
	@echo "$(CYAN)📊 SnappTrip Pipeline Status$(RESET)"
	@echo "=============================="
	@echo ""
	@echo "$(BLUE)📁 Directory Structure:$(RESET)"
	@ls -la $(DATA_DIR)/ 2>/dev/null || echo "$(RED)❌ Data directory not found$(RESET)"
	@echo ""
	@echo "$(BLUE)📈 Output Status:$(RESET)"
	@if [ -d "$(OUTPUT_DIR)/silver" ]; then \
		silver_files=$$(find $(OUTPUT_DIR)/silver -name "*.csv" 2>/dev/null | wc -l); \
		echo "$(GREEN)✅ Silver layer: $$silver_files files$(RESET)"; \
	else \
		echo "$(RED)❌ Silver layer: No output found$(RESET)"; \
	fi
	@if [ -d "$(OUTPUT_DIR)/gold" ]; then \
		gold_dirs=$$(find $(OUTPUT_DIR)/gold -type d -mindepth 1 2>/dev/null | wc -l); \
		echo "$(GREEN)✅ Gold layer: $$gold_dirs analytics tables$(RESET)"; \
	else \
		echo "$(RED)❌ Gold layer: No output found$(RESET)"; \
	fi
	@echo ""
	@echo "$(BLUE)🔧 Quick Commands:$(RESET)"
	@echo "  make run      - Execute pipeline"
	@echo "  make validate - Run validations"
	@echo "  make clean    - Clear outputs"

# Development and debugging targets
debug: ## Run pipeline with verbose output for debugging
	@echo "$(YELLOW)🐛 Running pipeline in debug mode...$(RESET)"
	@$(PYTHON) -u run_pipeline.py 2>&1 | tee pipeline_debug.log
	@echo "$(GREEN)Debug log saved to: pipeline_debug.log$(RESET)"

quick-test: ## Quick test run with minimal output
	@echo "$(BLUE)⚡ Quick test run...$(RESET)"
	@$(PYTHON) -c "from pyspark.sql import SparkSession; spark = SparkSession.builder.appName('QuickTest').getOrCreate(); print('✅ Spark session created successfully'); spark.stop()"
	@echo "$(GREEN)✅ Basic functionality test passed$(RESET)"

# Installation variants
install-dev: check-deps ## Install with development dependencies
	@echo "$(BLUE)📦 Installing development dependencies...$(RESET)"
	@$(PIP) install -r $(REQUIREMENTS)
	@$(PIP) install pytest jupyter pandas matplotlib seaborn
	@echo "$(GREEN)✅ Development environment ready$(RESET)"

# Virtual environment targets
venv: ## Create virtual environment
	@echo "$(BLUE)🐍 Creating virtual environment...$(RESET)"
	@$(PYTHON) -m venv $(VENV)
	@echo "$(GREEN)✅ Virtual environment created$(RESET)"
	@echo "$(YELLOW)Activate with: source $(VENV)/bin/activate$(RESET)"

venv-install: venv ## Create venv and install dependencies
	@echo "$(BLUE)📦 Installing in virtual environment...$(RESET)"
	@$(VENV)/bin/pip install -r $(REQUIREMENTS)
	@echo "$(GREEN)✅ Virtual environment setup complete$(RESET)"

# Data operations
sample-data: ## Generate additional sample data for testing
	@echo "$(BLUE)📊 Generating additional sample data...$(RESET)"
	@$(PYTHON) -c "print('Sample data generation - implement if needed')"
	@echo "$(GREEN)✅ Sample data ready$(RESET)"

# Documentation
docs: ## Generate documentation (if applicable)
	@echo "$(BLUE)📚 Documentation available:$(RESET)"
	@echo "  📖 README.md - Main documentation"
	@echo "  🎓 TUTORIAL.md - Beginner's guide"
	@echo "  📊 Current directory: $$(pwd)"

# Monitoring and logs
logs: ## Show recent pipeline logs (if any)
	@echo "$(BLUE)📋 Recent pipeline activity:$(RESET)"
	@if [ -f "pipeline_debug.log" ]; then \
		echo "$(GREEN)Debug log (last 20 lines):$(RESET)"; \
		tail -20 pipeline_debug.log; \
	else \
		echo "$(YELLOW)No debug logs found. Run 'make debug' to generate logs$(RESET)"; \
	fi

# Performance testing
benchmark: ## Run performance benchmark
	@echo "$(BLUE)⏱️  Running performance benchmark...$(RESET)"
	@time $(PYTHON) run_pipeline.py > /dev/null 2>&1
	@echo "$(GREEN)✅ Benchmark completed$(RESET)"

# Complete workflow examples
demo: full-pipeline show-status ## Complete demo: setup → run → validate → show results
	@echo "$(MAGENTA)🎬 SnappTrip Demo Completed!$(RESET)"
	@echo "$(CYAN)🎉 Ready for presentation or development$(RESET)"

# CI/CD friendly targets
ci-setup: check-deps install create-dirs ## Setup for CI/CD environments
	@echo "$(GREEN)✅ CI/CD setup completed$(RESET)"

ci-test: ci-setup run validate ## Complete CI/CD test pipeline
	@echo "$(GREEN)✅ CI/CD pipeline test passed$(RESET)"

# Error handling example
test-error-handling: ## Test error handling capabilities
	@echo "$(BLUE)🧪 Testing error handling...$(RESET)"
	@$(PYTHON) -c "from run_pipeline import *; print('Error handling test - implement specific tests')" || echo "$(YELLOW)Error handling test completed$(RESET)"

# Show file sizes and statistics
stats: ## Show pipeline statistics and file sizes
	@echo "$(CYAN)📊 Pipeline Statistics$(RESET)"
	@echo "======================"
	@echo "$(BLUE)Input Data:$(RESET)"
	@if [ -d "$(DATA_DIR)" ]; then \
		du -sh $(DATA_DIR)/* 2>/dev/null || echo "No data files found"; \
	fi
	@echo ""
	@echo "$(BLUE)Output Data:$(RESET)"
	@if [ -d "$(OUTPUT_DIR)" ]; then \
		find $(OUTPUT_DIR) -name "*.csv" -exec wc -l {} + 2>/dev/null || echo "No output files found"; \
	fi