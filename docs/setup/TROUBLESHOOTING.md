# Troubleshooting Guide

## Common Issues and Solutions

### 1. Java Not Found (PySpark Tests)

#### Symptom
```
Unable to locate a Java Runtime.
PySparkRuntimeError: [JAVA_GATEWAY_EXITED] Java gateway process exited
```

#### Solution
PySpark requires Java. Install it:

```bash
# Quick install via script
./install_java.sh

# Or via Homebrew
brew install openjdk@11

# Or via conda
conda install -c conda-forge openjdk=11
```

**After installation, restart your terminal!**

Then run:
```bash
source ~/.zshrc
conda activate snapptrip
make test-unit
```

**See `JAVA_SETUP.md` for detailed instructions.**

---

### 2. Missing Python Packages

#### Symptom
```
ModuleNotFoundError: No module named 'chispa'
ModuleNotFoundError: No module named 'great_expectations'
```

#### Solution
```bash
conda activate snapptrip
pip install chispa==0.9.4 great-expectations==0.18.8
```

Or reinstall all packages:
```bash
conda activate snapptrip
pip install -r requirements-core.txt
pip install -e .
```

---

### 2. Conda Activation Fails

#### Symptom
```
conda: command not found
```

#### Solution
```bash
# Initialize conda
source ~/miniconda3/etc/profile.d/conda.sh

# Then activate
conda activate snapptrip
```

Add to your `~/.zshrc` or `~/.bashrc`:
```bash
# Initialize conda
if [ -f ~/miniconda3/etc/profile.d/conda.sh ]; then
    source ~/miniconda3/etc/profile.d/conda.sh
fi
```

---

### 3. Docker Daemon Not Running

#### Symptom
```
Cannot connect to the Docker daemon
Is the docker daemon running?
```

#### Solution

**For OrbStack:**
1. Open OrbStack app
2. Wait for startup
3. Verify: `docker ps`

**For Docker Desktop:**
1. Open Docker Desktop
2. Wait for "running" status
3. Verify: `docker ps`

**Alternative - Skip Docker:**
You can work without Docker:
```bash
# Run tests locally
conda activate snapptrip
pytest tests/unit/ -v

# Review code
cat src/silver/booking_state_reconciliation.py
```

---

### 4. Python Import Errors in Tests

#### Symptom
```
ImportError: cannot import name 'BookingStateReconciliation'
```

#### Solution
```bash
conda activate snapptrip

# Reinstall project in editable mode
pip install -e .

# Verify
python -c "from src.silver.booking_state_reconciliation import BookingStateReconciliation; print('✅ OK')"
```

---

### 5. Spark/PySpark Errors

#### Symptom
```
py4j.protocol.Py4JJavaError
java.lang.OutOfMemoryError
```

#### Solution
Set Spark memory limits:
```bash
export SPARK_DRIVER_MEMORY=4g
export SPARK_EXECUTOR_MEMORY=4g
```

Or edit `src/common/spark_session.py` to reduce memory usage.

---

### 6. Docker Compose Version Warning

#### Symptom
```
WARN: the attribute `version` is obsolete
```

#### Solution
This is just a warning and can be safely ignored. Docker Compose v2 no longer requires the `version` field.

---

### 7. Port Already in Use

#### Symptom
```
Error: port 8080 is already allocated
```

#### Solution
```bash
# Find process using the port
lsof -i :8080

# Kill the process
kill -9 <PID>

# Or use different ports in docker-compose.yml
```

---

### 8. HDFS Connection Errors

#### Symptom
```
ConnectionRefusedError: [Errno 61] Connection refused
```

#### Solution
```bash
# Wait for HDFS to fully start (takes 2-3 minutes)
sleep 180

# Check HDFS status
docker-compose -f docker/docker-compose.yml exec namenode hdfs dfsadmin -report

# Restart if needed
make docker-down
make docker-up
```

---

### 9. Kafka Connection Errors

#### Symptom
```
KafkaError: Broker not available
```

#### Solution
```bash
# Check Kafka is running
docker-compose -f docker/docker-compose.yml ps kafka

# Check logs
docker-compose -f docker/docker-compose.yml logs kafka

# Recreate topics
bash scripts/setup/init_kafka_topics.sh
```

---

### 10. Test Collection Errors

#### Symptom
```
ERROR collecting tests/unit/test_silver_reconciliation.py
```

#### Solution
```bash
# Clean Python cache
make clean

# Reinstall
conda activate snapptrip
pip install -e .

# Run specific test
pytest tests/unit/test_silver_reconciliation.py -v
```

---

## Quick Fixes

### Reset Everything
```bash
# Clean Python artifacts
make clean

# Recreate conda environment
conda deactivate
conda env remove -n snapptrip
./scripts/dev/setup_environment.sh

# Restart Docker
make docker-down
make docker-clean
make docker-up
```

### Verify Installation
```bash
conda activate snapptrip
python verify_setup.py
```

### Check Package Versions
```bash
conda activate snapptrip
pip list | grep -E "pyspark|pandas|kafka|chispa|great"
```

### Check Docker Status
```bash
docker ps                           # Running containers
docker-compose ps                   # Compose services
docker system df                    # Disk usage
docker-compose logs <service>       # Service logs
```

---

## Environment-Specific Issues

### macOS Apple Silicon (M1/M2/M3)

Some packages may have ARM compatibility issues. Solutions:
```bash
# Use conda for binary packages
conda install -c conda-forge <package>

# Or use Rosetta 2
arch -x86_64 pip install <package>
```

### macOS Intel

Should work without issues. If you encounter problems:
```bash
# Update Xcode Command Line Tools
xcode-select --install

# Update Homebrew
brew update && brew upgrade
```

### Linux

May need additional system packages:
```bash
# Ubuntu/Debian
sudo apt-get install build-essential libpq-dev

# CentOS/RHEL
sudo yum install gcc postgresql-devel
```

---

## Still Having Issues?

### Collect Diagnostic Information
```bash
# Python environment
python --version
which python
conda info --envs
conda list -n snapptrip

# Docker
docker --version
docker-compose --version
docker ps -a
docker system df

# System
uname -a
df -h
free -h  # Linux only
```

### Check Logs
```bash
# Python logs
cat logs/pipeline.log

# Docker logs
docker-compose -f docker/docker-compose.yml logs --tail=100

# Airflow logs
docker-compose -f docker/docker-compose.yml logs airflow-scheduler
```

### Clean Start
```bash
# Remove everything and start fresh
conda env remove -n snapptrip
make docker-down
docker system prune -a --volumes
rm -rf .pytest_cache htmlcov __pycache__

# Setup again
./scripts/dev/setup_environment.sh
make docker-up
```

---

## Getting Help

1. Check this troubleshooting guide
2. Review `docs/setup/GETTING_STARTED.md`
3. Check `IMPLEMENTATION_SUMMARY.md` for architecture details
4. Review relevant source code in `src/`
5. Check Docker logs for infrastructure issues

---

## Common Command Reference

```bash
# Environment
conda activate snapptrip              # Activate environment
conda deactivate                      # Deactivate environment
conda env list                        # List environments

# Development
pytest tests/unit/ -v                 # Run tests
make format                           # Format code
make lint                             # Lint code
make clean                            # Clean artifacts

# Docker
make docker-up                        # Start services
make docker-down                      # Stop services
make docker-logs                      # View logs
docker ps                             # List containers

# Debugging
python -c "import <module>"           # Test import
pip show <package>                    # Show package info
pip list | grep <package>             # Find package
```
