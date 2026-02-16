#!/bin/bash

# SnappTrip Data Platform - Unified Environment Setup Script
# This script sets up the complete development environment with conda

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "=========================================="
echo "SnappTrip Data Platform"
echo "Environment Setup"
echo "=========================================="
echo ""

# Ensure conda is available
if ! command -v conda &> /dev/null; then
    echo "Initializing conda..."
    if [ -f ~/miniconda3/etc/profile.d/conda.sh ]; then
        source ~/miniconda3/etc/profile.d/conda.sh
    elif [ -f ~/anaconda3/etc/profile.d/conda.sh ]; then
        source ~/anaconda3/etc/profile.d/conda.sh
    else
        echo "❌ Error: Conda not found. Please install miniconda or anaconda first."
        echo "Download from: https://docs.conda.io/en/latest/miniconda.html"
        exit 1
    fi
fi

# Check if environment already exists
if conda env list | grep -q "^snapptrip "; then
    echo "ℹ️  Conda environment 'snapptrip' already exists."
    read -p "Do you want to recreate it? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Removing existing environment..."
        conda env remove -n snapptrip -y
    else
        echo "Skipping environment creation. Activating existing environment..."
        eval "$(conda shell.bash hook)"
        conda activate snapptrip
        echo "✅ Environment activated."
        echo ""
        echo "To install missing packages, run:"
        echo "  pip install -r requirements-core.txt"
        exit 0
    fi
fi

# Create conda environment
echo ""
echo "Step 1/5: Creating conda environment 'snapptrip' with Python 3.11..."
conda create -y -n snapptrip python=3.11 -c conda-forge

# Activate environment
echo ""
echo "Step 2/5: Activating environment..."
eval "$(conda shell.bash hook)"
conda activate snapptrip

# Install binary packages from conda-forge
echo ""
echo "Step 3/5: Installing binary packages from conda-forge..."
conda install -y -c conda-forge \
  pyspark=3.5 \
  pandas=2.1.4 \
  pyarrow=14.0.2 \
  numpy=1.26.2 \
  psycopg=3.3.2 \
  sqlalchemy=2.0.25 \
  kafka-python=2.0.2 \
  pytest=7.4.3 \
  pytest-cov \
  pytest-mock \
  black \
  flake8 \
  mypy \
  isort

# Install pip packages
echo ""
echo "Step 4/5: Installing pip packages..."
pip install --upgrade pip setuptools wheel
pip install confluent-kafka==2.3.0
pip install chispa==0.9.4
pip install great-expectations==0.18.8
pip install avro-python3==1.10.2
pip install python-dotenv==1.0.0
pip install pyyaml==6.0.1

# Install project in editable mode
echo ""
echo "Step 5/5: Installing project in editable mode..."
cd "$PROJECT_ROOT"
pip install -e .

echo ""
echo "=========================================="
echo "✅ Environment setup complete!"
echo "=========================================="
echo ""
echo "To activate the environment in the future, run:"
echo "  conda activate snapptrip"
echo ""
echo "To verify installation:"
echo "  python verify_setup.py"
echo ""
echo "To run tests:"
echo "  pytest tests/unit/ -v"
echo ""
echo "To start Docker services:"
echo "  make docker-up"
echo ""
