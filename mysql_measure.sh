#!/bin/bash


CONTAINER=mysql_demo
USER=demo
PASS=demo
DB=write_amp_demo

# Run MySQL inside the container with password, suppressing warnings
MYSQL="docker exec -i $CONTAINER mysql -u$USER -p$PASS -D $DB --silent --skip-column-names -e"

echo "=== MySQL Write Amplification Test ==="
echo "Version: $($MYSQL 'SELECT VERSION();')"
echo "Binlog Format: $($MYSQL 'SELECT @@binlog_format;')"

# Before
START_POS=$($MYSQL "SHOW MASTER STATUS;" | awk '{print $2}')
START_TIME=$(date +%s.%N)

# Update
docker exec -i $CONTAINER mysql -u$USER -p$PASS -D $DB -e \
"UPDATE rides_mysql SET status = CASE WHEN status = 'ongoing' THEN 'completed' ELSE 'ongoing' END WHERE ride_id <= 50000;"

# After
END_POS=$($MYSQL "SHOW MASTER STATUS;" | awk '{print $2}')
END_TIME=$(date +%s.%N)

# Calculate
BINLOG_BYTES=$(echo "$END_POS - $START_POS" | bc)
DURATION=$(echo "$END_TIME - $START_TIME" | bc)

echo "Binlog Generated: $(printf "%'d" $BINLOG_BYTES) bytes"
echo "Duration: $DURATION seconds"
echo "Bytes per row: $(echo "scale=2; $BINLOG_BYTES / 50000" | bc)"
