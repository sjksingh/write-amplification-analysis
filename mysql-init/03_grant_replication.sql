GRANT SUPER, REPLICATION CLIENT ON *.* TO 'demo'@'%';
GRANT SELECT ON performance_schema.* TO 'demo'@'%';
FLUSH PRIVILEGES;
