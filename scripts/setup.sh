#!/bin/bash

# SnappTrip Data Platform - Setup and Installation Scripts
# All setup scripts consolidated into one file

set -e

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}$1${NC}"
    echo -e "${GREEN}========================================${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Get the command
COMMAND=${1:-help}

case $COMMAND in
    setup-env)
        print_header "Setting up conda environment"
        
        # Initialize conda
        if ! command -v conda &> /dev/null; then
            echo "Initializing conda..."
            if [ -f ~/miniconda3/etc/profile.d/conda.sh ]; then
                source ~/miniconda3/etc/profile.d/conda.sh
            elif [ -f ~/anaconda3/etc/profile.d/conda.sh ]; then
                source ~/anaconda3/etc/profile.d/conda.sh
            else
                print_error "Conda not found"
                exit 1
            fi
        fi
        
        # Create environment
        echo "Creating conda environment 'snapptrip' with Python 3.11..."
        conda create -y -n snapptrip python=3.11 -c conda-forge
        
        eval "$(conda shell.bash hook)"
        conda activate snapptrip
        
        # Install packages
        echo "Installing packages from conda-forge..."
        conda install -y -c conda-forge \
            pyspark=3.5 pandas=2.1.4 pyarrow=14.0.2 numpy=1.26.2 \
            psycopg=3.3.2 sqlalchemy=2.0.25 kafka-python=2.0.2 \
            pytest=7.4.3 pytest-cov pytest-mock black flake8 mypy isort
        
        echo "Installing pip packages..."
        pip install --upgrade pip setuptools wheel
        pip install confluent-kafka==2.3.0 chispa==0.9.4 great-expectations==0.18.8 \
                    avro-python3==1.10.2 python-dotenv==1.0.0 pyyaml==6.0.1
        
        # Install project
        cd "$(dirname "$0")" || exit 1
        pip install -e .
        
        print_success "Environment setup complete!"
        echo "To activate: conda activate snapptrip"
        ;;
        
    install-java)
        print_header "Installing Java for PySpark"
        
        if command -v java &> /dev/null && java -version &> /dev/null 2>&1; then
            print_success "Java is already installed"
            java -version
            exit 0
        fi
        
        if ! command -v brew &> /dev/null; then
            print_error "Homebrew not found"
            echo "Install from: https://brew.sh"
            exit 1
        fi
        
        print_warning "Installing OpenJDK 11..."
        brew install openjdk@11
        
        echo 'export PATH="/opt/homebrew/opt/openjdk@11/bin:$PATH"' >> ~/.zshrc
        echo 'export JAVA_HOME="/opt/homebrew/opt/openjdk@11"' >> ~/.zshrc
        
        export PATH="/opt/homebrew/opt/openjdk@11/bin:$PATH"
        export JAVA_HOME="/opt/homebrew/opt/openjdk@11"
        
        print_success "Java installed!"
        java -version
        echo ""
        print_warning "Restart your terminal to apply changes, or run: source ~/.zshrc"
        ;;
        
    verify)
        print_header "Verifying environment setup"
        
        python verify_setup.py
        ;;
        
    help|*)
        echo "SnappTrip Data Platform - Setup Scripts"
        echo ""
        echo "Usage: $0 <command>"
        echo ""
        echo "Commands:"
        echo "  setup-env      Create conda environment and install all packages"
        echo "  install-java   Install OpenJDK 11 for PySpark"
        echo "  verify         Verify environment setup"
        echo "  help           Show this help message"
        echo ""
        echo "Quick start:"
        echo "  $0 setup-env"
        echo "  $0 install-java"
        echo "  conda activate snapptrip"
        echo "  $0 verify"
        ;;
esac
