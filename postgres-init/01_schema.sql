CREATE TABLE rides_pg (
    ride_id BIGSERIAL PRIMARY KEY,
    driver_id INT NOT NULL,
    passenger_id INT NOT NULL,
    start_time TIMESTAMP NOT NULL DEFAULT now(),
    end_time TIMESTAMP,
    status VARCHAR(20) DEFAULT 'ongoing'
);

BEGIN;
INSERT INTO rides_pg (driver_id, passenger_id, status)
SELECT i % 1000, i % 5000, 'ongoing'
FROM generate_series(1,100000) AS i;
COMMIT;

CREATE INDEX idx_rides_driver_id ON rides_pg(driver_id);
CREATE INDEX idx_rides_status ON rides_pg(status);
