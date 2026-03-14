#!/bin/sh

# This script is used to start the import of kosmtik containers for the Docker development environment.
# You can read details about that in DOCKER.md

# Testing if database is ready
i=1
MAXCOUNT=60
DB_NAME=osm
echo "Waiting for PostgreSQL to be running"
while [ $i -le $MAXCOUNT ]
do
  pg_isready -q && echo "PostgreSQL running" && break
  sleep 2
  i=$((i+1))
done
test $i -gt $MAXCOUNT && echo "Timeout while waiting for PostgreSQL to be running"

case "$1" in
import)
  # Creating default database
  psql -c "SELECT 1 FROM pg_database WHERE datname = '$DB_NAME';" | grep -q 1 || createdb $DB_NAME && \
  psql -d $DB_NAME -c 'CREATE EXTENSION IF NOT EXISTS postgis;' && \
  psql -d $DB_NAME -c 'CREATE EXTENSION IF NOT EXISTS hstore;' && \

  # Creating default import settings file editable by user and passing values for osm2pgsql
  if [ ! -e ".env" ]; then
    cat > .env <<EOF
# Environment settings for importing to a Docker container database
PG_WORK_MEM=${PG_WORK_MEM:-256MB}
PG_MAINTENANCE_WORK_MEM=${PG_MAINTENANCE_WORK_MEM:-256MB}
CACHE=${CACHE:-4096}
THREADS=${THREADS:-8}
OSM2PGSQL_DATAFILE=${OSM2PGSQL_DATAFILE:-data.osm.pbf}
EOF
    chmod a+rw .env
    export CACHE=${CACHE:-4096}
    export THREADS=${THREADS:-8}
    export OSM2PGSQL_DATAFILE=${OSM2PGSQL_DATAFILE:-data.osm.pbf}
  fi

  echo "Importing data to a database: $OSM2PGSQL_DATAFILE using $CACHE cache and $THREADS threads"

  # Importing data to a database
  osm2pgsql \
  --cache $CACHE \
  --number-processes $THREADS \
  --hstore \
  --database $DB_NAME \
  --slim \
  -c \
  -G \
  --drop \
  $OSM2PGSQL_DATAFILE

    echo "INFO: Importing data done. Creating indexes..."
    psql -d $DB_NAME -f indexes.sql || exit 1

  # Run cyclosm-specific sql script
  psql --dbname=$DB_NAME --file=views.sql

  ;;

kosmtik)
  # Downloading needed shapefiles
  # python scripts/get-shapefiles.py -n

  # Creating default Kosmtik settings file
  if [ ! -e ".kosmtik-config.yml" ]; then
    cp /tmp/.kosmtik-config.yml .kosmtik-config.yml  
  fi
  export KOSMTIK_CONFIGPATH=".kosmtik-config.yml"

  cat project.mml.template | sed -e "s/\${THEME}/$THEME/g" > project-$THEME.mml

  # Starting Kosmtik
  kosmtik serve project-$THEME.mml --host 0.0.0.0 --port $PORT --style-id $THEME
  # It needs Ctrl+C to be interrupted
  ;;

# contours)
#   wget http://download.geofabrik.de/africa/tanzania.poly
#   phyghtmap --polygon=tanzania.poly -j 2 -s 10 -0 --source=view3 --max-nodes-per-tile=0 --max-nodes-per-way=0 --pbf
#   # Remove now useless files
#   rm -r hgt
#   rm *.poly
#   sudo -u postgres createdb data
#   sudo -u postgres psql data -c 'CREATE EXTENSION postgis;'
#   # Load the data into the contours database:
#   sudo -u postgres osm2pgsql --slim -d data --cache 5000 --style ./contours.style ./*.osm.pbf
#   ;;

# esac
