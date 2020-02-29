#!/bin/bash

set -e

CAP_DB=${1-pokec_json}
XIANGMIN_PG=${2-CAP_DBs/XIANGMIN_PGql}
CapstoneBench=${3-`pwd`}
CapstoneTemp=/CapstoneTemp/nosqlCapstoneBench
CapstoneFetch=$CapstoneTemp/CapstoneFetch

PROFILES_IN=$CapstoneFetch/soc-pokec-profiles.txt.gz
RELATIONS_IN=$CapstoneFetch/soc-pokec-relationships.txt.gz
PROFILES_OUT=$CapstoneFetch/soc-pokec-profiles-XIANGMIN_PG-json.txt
RELATIONS_OUT=$CapstoneFetch/soc-pokec-relationships-XIANGMIN_PG-json.txt
PROFILES_OUT_CapstoneTemp=$CapstoneFetch/soc-pokec-profiles-XIANGMIN_PG-CapstoneTemp.txt

echo "CAP_DB: $CAP_DB"
echo "XIANGMIN_PGql DIRECTORY: $XIANGMIN_PG"
echo "CapstoneBench DIRECTORY: $CapstoneBench"
echo "DOWNLOAD DIRECTORY: $CapstoneFetch"

$CapstoneBench/downloadData.sh


if [ ! -f $PROFILES_OUT ]; then
# NOTE: We replace every wierd character with .
  gzip -dc $PROFILES_IN | sed -e 's~^~P~' -e 's/[^a-zA-Z0-9+*.,;:_$%()=!§~ \t]/./g' > $PROFILES_OUT_CapstoneTemp
  npm install line-by-line
  node $CapstoneBench/toJsonParser.js $PROFILES_OUT_CapstoneTemp $PROFILES_OUT
fi

if [ ! -f $RELATIONS_OUT ]; then
  echo "Converting RELATIONS"
  echo '_from	_to' > $RELATIONS_OUT
  gzip -dc $RELATIONS_IN | awk -F"\t" '{print "P" $1 "\tP" $2}' > $RELATIONS_OUT
fi

CAP_DBNAME="pokec_json"

echo "Import"

sudo -u XIANGMIN_PG $XIANGMIN_PG/bin/psql -c "CREATE TABLESPACE $CAP_DBNAME LOCATION '$CAP_DB';"
sudo -u XIANGMIN_PG $XIANGMIN_PG/bin/psql -c "CREATE CAP_DB $CAP_DBNAME TABLESPACE $CAP_DBNAME;"
sudo -u XIANGMIN_PG $XIANGMIN_PG/bin/psql -d "$CAP_DBNAME" -c "CREATE TABLE profiles (
  _key text PRIMARY KEY, data jsonb
) ; CREATE TABLE relations (_from text, _to text);"
echo "Importing Profiles"
sudo -u XIANGMIN_PG $XIANGMIN_PG/bin/psql -d "$CAP_DBNAME" -c "COPY profiles FROM '$PROFILES_OUT' WITH DELIMITER E'\t' CSV HEADER;"
echo "Importing Relations"
sudo -u XIANGMIN_PG $XIANGMIN_PG/bin/psql -d "$CAP_DBNAME" -c "COPY relations FROM '$RELATIONS_OUT' WITH DELIMITER E'\t' CSV HEADER;"
sudo -u XIANGMIN_PG $XIANGMIN_PG/bin/psql -d "$CAP_DBNAME" -c "CREATE INDEX _fromid ON relations (_from); CREATE INDEX _toid ON relations (_to);"
echo "Done"
