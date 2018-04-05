#!/bin/bash -e

# This script sets up the user environment

#===============================================================================
# debugging
set -x

#===============================================================================
#TODO setup signal handler which shuts down posgresql and aiida.

# setup postgresql
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

mkdir /project/.postgresql
${PGBIN}/initdb -D /project/.postgresql
echo "unix_socket_directories = '/project/.postgresql'" >> /project/.postgresql/postgresql.conf
start_psql
psql -h localhost -d template1 -c "CREATE USER aiida WITH PASSWORD 'aiida_db_passwd';"
psql -h localhost -d template1 -c "CREATE DATABASE aiidadb OWNER aiida;"
psql -h localhost -d template1 -c "GRANT ALL PRIVILEGES ON DATABASE aiidadb to aiida;"

#===============================================================================
# environment
export PYTHONPATH=/project
export SHELL=/bin/bash

#===============================================================================
# setup AiiDA
aiida_backend=sqlalchemy

verdi setup                          \
  --non-interactive                 \
  --email discover@materialscloud.org     \
  --first-name Discover             \
  --last-name Section               \
  --institution Materialscloud      \
  --backend $aiida_backend          \
  --db_user aiida                   \
  --db_pass aiida_db_passwd         \
  --db_name aiidadb                 \
  --db_host localhost               \
  --db_port 5432                    \
  --repo /project/aiida_repository \
  default

verdi profile setdefault verdi default
verdi profile setdefault daemon default
bash -c 'echo -e "y\ndiscover@materialscloud.org" | verdi daemon configureuser'

# setup pseudopotentials
cd /opt/pseudos
for i in *; do
 verdi import $i
done

#===============================================================================
# create bashrc
cp -v /etc/skel/.bashrc /etc/skel/.bash_logout /etc/skel/.profile /project/
echo 'eval "$(verdi completioncommand)"' >> /project/.bashrc
echo 'export PYTHONPATH="/project"' >> /project/.bashrc


#===============================================================================
# generate ssh key
mkdir -p /project/.ssh
ssh-keygen -f /project/.ssh/id_rsa -t rsa -N ''

#===============================================================================
# setup AiiDA jupyter extension
mkdir -p /project/.ipython/profile_default/
echo "c = get_config()"                         > /project/.ipython/profile_default/ipython_config.py
echo "c.InteractiveShellApp.extensions = ["    >> /project/.ipython/profile_default/ipython_config.py
echo "  'aiida.common.ipython.ipython_magics'" >> /project/.ipython/profile_default/ipython_config.py
echo "]"                                       >> /project/.ipython/profile_default/ipython_config.py

#===============================================================================
# install/upgrade apps
mkdir /project/apps
touch /project/apps/__init__.py
git clone https://github.com/materialscloud-org/mc-home /project/apps/home

#EOF
