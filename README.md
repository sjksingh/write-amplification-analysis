# Write Amplification Analysis: PostgreSQL vs MySQL
## Reproducing Uber's Migration Decision with Measurable Data

[![Docker](https://img.shields.io/badge/Docker-Required-blue)](https://www.docker.com/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-17.6-blue)](https://www.postgresql.org/)
[![MySQL](https://img.shields.io/badge/MySQL-8.0.43-orange)](https://www.mysql.com/)

This repository provides a complete reproduction environment for measuring write amplification differences between PostgreSQL and MySQL architectures. Inspired by Uber's documented migration, we validate their claims with controlled testing.

## 🔍 Key Findings

| Database | Index Count | Bytes per Update | Write Amplification |
|----------|-------------|------------------|-------------------|
| PostgreSQL 17.6 | 3 indexes | 485 bytes | **8.09x** |
| PostgreSQL 17.6 | 6 indexes | 614 bytes | **10.24x** |
| MySQL 8.0 | Any indexes | 60 bytes | **1.0x (baseline)** |

**Bottom Line:** PostgreSQL generates **10x more replication data** than MySQL for indexed updates due to fundamental architectural differences.

## 🚀 Quick Start

### Prerequisites
- Docker and Docker Compose
- Enough resources

### Run Complete Test Suite
```bash
# Clone repository
git clone https://github.com/sjksingh/write-amplification-analysis.git
cd write-amplification-analysis

# Start test environment
docker-compose up -d

# Wait for databases to initialize (60 seconds)
sleep 60

# Run PostgreSQL test (3 indexes)
./scripts/pg_enhanced.sh

# Run MySQL test (3 indexes)  
./scripts/mysql_enhanced.sh

# Add additional indexes
./scripts/add_indexes.sh

# Test with 6 indexes
./scripts/pg_enhanced.sh
./scripts/mysql_enhanced.sh

# Generate comparison report
./scripts/analyze_results.sh
```

## 📊 Test Environment

### Database Configurations
```yaml
PostgreSQL 17.6:
  - wal_level: replica
  - shared_buffers: 256MB
  - max_wal_size: 1GB
  - Container: postgres:17.6

MySQL 8.0.43:
  - binlog_format: ROW
  - innodb_buffer_pool_size: 256MB
  - sync_binlog: 1
  - Container: mysql:8.0.43
```

### Test Schema
```sql
CREATE TABLE rides (
    ride_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    driver_id INTEGER NOT NULL,
    passenger_id INTEGER NOT NULL,
    start_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    end_time TIMESTAMP NULL,
    status VARCHAR(20) DEFAULT 'ongoing'
);

-- Base indexes (3 total)
CREATE INDEX idx_rides_driver_id ON rides(driver_id);
CREATE INDEX idx_rides_status ON rides(status);

-- Additional indexes for scaling test (6 total)
CREATE INDEX idx_start_time ON rides(start_time);
CREATE INDEX idx_end_time ON rides(end_time);
CREATE INDEX idx_composite ON rides(driver_id, passenger_id);
```

### Test Operation
```sql
-- Updates 50,000 rows (status column change)
UPDATE rides 
SET status = CASE 
    WHEN status = 'ongoing' THEN 'completed' 
    ELSE 'ongoing' 
END 
WHERE ride_id <= 50000;
```

## 🔧 Repository Structure

```
write-amplification-analysis/
├── docker-compose.yml          # Complete test environment
├── scripts/
│   ├── pg_enhanced.sh         # PostgreSQL measurement script
│   ├── mysql_enhanced.sh      # MySQL measurement script
│   ├── add_indexes.sh         # Add additional indexes
│   ├── analyze_results.sh     # Generate comparison report
│   └── cleanup.sh             # Reset test environment
├── postgres-init/
│   └── init.sql              # PostgreSQL schema and data
├── mysql-init/
│   └── init.sql              # MySQL schema and data
├── results/
│   └── sample_results.md     # Example test output
└── README.md                 # This file
```

## 📈 Understanding the Results

### PostgreSQL Measurement
```bash
# Script captures WAL (Write-Ahead Log) generation
START_LSN=$(psql -t -c "SELECT pg_current_wal_lsn()")
# Execute update
END_LSN=$(psql -t -c "SELECT pg_current_wal_lsn()")
WAL_BYTES=$(psql -t -c "SELECT pg_wal_lsn_diff('$END_LSN', '$START_LSN')")
```

### MySQL Measurement  
```bash
# Script captures binlog generation
START_POS=$(mysql -e 'SHOW MASTER STATUS\G' | grep Position)
# Execute update
END_POS=$(mysql -e 'SHOW MASTER STATUS\G' | grep Position)
BINLOG_BYTES=$((END_POS - START_POS))
```

### Why the Difference?

**PostgreSQL (Heap-Based):**
- Updates create new tuple versions (MVCC)
- ALL indexes must point to new heap locations
- Index count directly multiplies write volume

**MySQL (Clustered Index):**
- Secondary indexes contain primary key values
- Only changed-column indexes need updates  
- Index count has minimal impact

## 🎯 Production Implications

### When Write Amplification Matters
- **Write-heavy workloads** (>100K updates/hour)
- **Many indexes per table** (5+ indexes)
- **Multi-region replication** requirements
- **Cost-sensitive environments** (cloud bandwidth costs)

### Decision Framework
| Scenario | Indexes | Update Volume | Recommendation |
|----------|---------|---------------|----------------|
| Small Scale | <5 | <100K/hour | PostgreSQL advantages likely win |
| Medium Scale | 5-7 | 100K-1M/hour | **Evaluate both options** |
| Large Scale | 7+ | >1M/hour | **Strong case for MySQL** |

## 🔧 Customizing Tests

### Test Different Index Patterns
```bash
# Edit postgres-init/init.sql or mysql-init/init.sql
# Add your indexes:
CREATE INDEX idx_custom ON rides(your_column);

# Restart environment
docker-compose down && docker-compose up -d
```

### Test Different Update Patterns
```bash
# Edit scripts to test different scenarios:
# - Multi-column updates
# - Different batch sizes  
# - HOT vs non-HOT updates (PostgreSQL)
```

### Monitor Resource Usage
```bash
# View container resource usage
docker stats

# Monitor disk I/O
docker exec postgres iostat -x 1

# Check replication lag simulation
docker exec mysql mysqladmin processlist
```

## 📊 Sample Results

### PostgreSQL 17.6 with 6 Indexes
```
=== PostgreSQL Write Amplification Test ===
Version: PostgreSQL 17.6 (Debian 17.6-1.pgdg13+1)
Config: wal_level=replica
UPDATE 50000
Time: 693.139 ms
WAL Generated: 30,725,920 bytes
Bytes per row: 614.51
```

### MySQL 8.0 with 6 Indexes
```
=== MySQL Write Amplification Test ===
Version: 8.0.43
Binlog Format: ROW
UPDATE 50000  
Time: 908.213 ms
Binlog Generated: 3,013,534 bytes
Bytes per row: 60.27
```

**Result: 10.24x Write Amplification**
