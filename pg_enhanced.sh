#!/bin/bash
# pg_enhanced.sh

CONTAINER=pg_demo
USER=demo
DB=write_amp_demo

echo "=== PostgreSQL Write Amplification Test ==="
echo "Version: $(docker exec $CONTAINER psql -U $USER -d $DB -t -c 'SELECT version()' | xargs)"
echo "Config: wal_level=$(docker exec $CONTAINER psql -U $USER -d $DB -t -c 'SHOW wal_level' | xargs)"

# Before
START_LSN=$(docker exec $CONTAINER psql -U $USER -d $DB -t -c "SELECT pg_current_wal_lsn()" | xargs)
START_TIME=$(date +%s.%N)

# Update
docker exec $CONTAINER psql -U $USER -d $DB -c "\timing on" -c "UPDATE rides_pg SET status = CASE WHEN status = 'ongoing' THEN 'completed' ELSE 'ongoing' END WHERE ride_id <= 50000;"

# After
END_LSN=$(docker exec $CONTAINER psql -U $USER -d $DB -t -c "SELECT pg_current_wal_lsn()" | xargs)
END_TIME=$(date +%s.%N)

# Calculate
WAL_BYTES=$(docker exec $CONTAINER psql -U $USER -d $DB -t -c "SELECT pg_wal_lsn_diff('$END_LSN', '$START_LSN')" | xargs)
DURATION=$(echo "$END_TIME - $START_TIME" | bc)

echo "WAL Generated: $WAL_BYTES bytes"
echo "Duration: $DURATION seconds"
echo "Bytes per row: $(echo "scale=2; $WAL_BYTES / 50000" | bc)"
