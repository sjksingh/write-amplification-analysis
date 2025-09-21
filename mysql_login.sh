#!/bin/bash
# login to MySQL shell inside Docker

CONTAINER=mysql_demo
USER=demo
PASS=demo
DB=write_amp_demo

echo "=== MySQL Shell ==="
docker exec -it $CONTAINER mysql -u$USER -p$PASS -D $DB
