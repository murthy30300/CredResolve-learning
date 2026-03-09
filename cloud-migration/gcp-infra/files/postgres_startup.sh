#!/bin/bash
# Startup script — installs PostgreSQL 14 and configures for DMS/CDC
set -e

apt-get update -y
apt-get install -y postgresql postgresql-contrib

# Configure PostgreSQL for logical replication (required for DMS CDC)
PG_CONF="/etc/postgresql/14/main/postgresql.conf"
PG_HBA="/etc/postgresql/14/main/pg_hba.conf"

sed -i "s/#wal_level = replica/wal_level = logical/" $PG_CONF
sed -i "s/#max_replication_slots = 10/max_replication_slots = 10/" $PG_CONF
sed -i "s/#max_wal_senders = 10/max_wal_senders = 10/" $PG_CONF

# Allow connections from entire VPC
echo "host all all 10.1.0.0/16 md5" >> $PG_HBA
echo "host replication all 10.1.0.0/16 md5" >> $PG_HBA

systemctl restart postgresql
systemctl enable postgresql

# Create DMS migration user
sudo -u postgres psql -c "CREATE ROLE dms_user WITH LOGIN PASSWORD 'DmsSecure@2024';"
sudo -u postgres psql -c "GRANT SELECT ON ALL TABLES IN SCHEMA public TO dms_user;"
sudo -u postgres psql -c "ALTER USER dms_user WITH REPLICATION;"

echo "PostgreSQL setup complete" >> /var/log/startup-script.log
