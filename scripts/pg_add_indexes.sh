#!/bin/bash
# Add 3 additional indexes to PostgreSQL rides_pg table

CONTAINER=pg_demo
USER=demo
DB=write_amp_demo

echo "=== Adding 3 more indexes to PostgreSQL rides_pg ==="

docker exec -it $CONTAINER psql -U $USER -d $DB -c "CREATE INDEX idx_start_time ON rides_pg(start_time);"
docker exec -it $CONTAINER psql -U $USER -d $DB -c "CREATE INDEX idx_end_time ON rides_pg(end_time);"
docker exec -it $CONTAINER psql -U $USER -d $DB -c "CREATE INDEX idx_composite ON rides_pg(driver_id, passenger_id);"

echo "=== Indexes after update ==="
docker exec -it $CONTAINER psql -U $USER -d $DB -c "\d+ rides_pg"
