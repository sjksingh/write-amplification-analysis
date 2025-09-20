CREATE TABLE rides_mysql (
    ride_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    driver_id INT NOT NULL,
    passenger_id INT NOT NULL,
    start_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    end_time TIMESTAMP NULL,
    status VARCHAR(20) DEFAULT 'ongoing'
);

USE write_amp_demo;

SET @rownum := 0;

INSERT INTO rides_mysql (driver_id, passenger_id, status)
SELECT seq % 1000, seq % 5000, 'ongoing'
FROM (
  SELECT @rownum := @rownum + 1 AS seq
  FROM information_schema.tables t1
  CROSS JOIN information_schema.tables t2
  CROSS JOIN information_schema.tables t3
) seqs
LIMIT 100000;

CREATE INDEX idx_rides_driver_id ON rides_mysql(driver_id);
CREATE INDEX idx_rides_status ON rides_mysql(status);
