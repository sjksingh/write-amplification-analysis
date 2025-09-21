#!/bin/bash
# Add 3 additional indexes to MySQL rides_mysql table

CONTAINER=mysql_demo
USER=demo
PASS=demo
DB=write_amp_demo

echo "=== Adding 3 more indexes to MySQL rides_mysql ==="

docker exec -it $CONTAINER mysql -u$USER -p$PASS -D $DB -e "
ALTER TABLE rides_mysql
    ADD INDEX idx_start_time (start_time),
    ADD INDEX idx_end_time (end_time),
    ADD INDEX idx_composite (driver_id, passenger_id);
"

echo "=== Indexes after update ==="
docker exec -it $CONTAINER mysql -u$USER -p$PASS -D $DB -e "SHOW INDEX FROM rides_mysql;"
