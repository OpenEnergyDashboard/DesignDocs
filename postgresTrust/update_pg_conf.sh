#!/bin/bash

# Path to pg_hba.conf
echo "Please enter the path to your pg_hba.conf file:"
read PG_HBA_CONF



# Replace "trust" with "scram-sha-256" for all connections
sed -i '' 's/trust/scram-sha-256/g' "$PG_HBA_CONF"




# Restart PostgreSQL
restart_postgresql() {
    if type systemctl > /dev/null 2>&1; then
        systemctl restart postgresql.service
    elif type service > /dev/null 2>&1; then
        service postgresql restart
    elif type brew > /dev/null 2>&1; then
        brew services restart postgresql
    else
        echo "PostgreSQL restart command not found. Please restart PostgreSQL manually."
        return 1
    fi
}


restart_postgresql
