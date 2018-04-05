#!/bin/bash -e

#===============================================================================
# debuging
set -x


#===============================================================================
#TODO setup signal handler which shuts down posgresql and aiida.

# start or set up postgresql

PGBIN=/usr/lib/postgresql/9.6/bin

# helper function to start psql and wait for it
function start_psql {
   ${PGBIN}/pg_ctl -D /project/.postgresql -l /project/.postgresql/logfile start
   TIMEOUT=20
   until psql -h localhost template1 -c ";" || [ $TIMEOUT -eq 0 ]; do
      echo ">>>>>>>>> Waiting for postgres server, $((TIMEOUT--)) remaining attempts..."
      tail -n 50 /project/.postgresql/logfile
      sleep 1
   done
}

if [ ! -d /project/.postgresql ]; then
   mkdir /project/.postgresql
   ${PGBIN}/initdb -D /project/.postgresql
   echo "unix_socket_directories = '/project/.postgresql'" >> /project/.postgresql/postgresql.conf
   start_psql
   psql -h localhost -d template1 -c "CREATE USER aiida WITH PASSWORD 'aiida_db_passwd';"
   psql -h localhost -d template1 -c "CREATE DATABASE aiidadb OWNER aiida;"
   psql -h localhost -d template1 -c "GRANT ALL PRIVILEGES ON DATABASE aiidadb to aiida;"
else
   # Postgresql was probably not shutdown properly. Cleaning up the mess...
   echo "" > /project/.postgresql/logfile # empty log files
   rm -vf /project/.postgresql/.s.PGSQL.5432
   rm -vf /project/.postgresql/.s.PGSQL.5432.lock
   rm -vf /project/.postgresql/postmaster.pid
   #${PGBIN}/pg_ctl -D /project/.postgresql stop || true
   start_psql
fi
