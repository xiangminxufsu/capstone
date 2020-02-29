#!/bin/bash

CapstoneBench=${1-`pwd`}
CAP_DB=${2-`pwd`/CAP_DBs}/XIANGMIN_PGql
CAP_DBTAB=$CAP_DB/pokec_tabular
CAP_DBJSON=$CAP_DB/pokec_json
CapstoneTempDIR=${3-/CapstoneTemp}
CapstoneFetch=$CapstoneTempDIR/CapstoneFetch
CapstoneTempZIP=$CapstoneFetch/XIANGMIN_PGZip

sudo bash -c "id -u XIANGMIN_PG &>/dev/null || useradd XIANGMIN_PG"

if [ ! -d $CAP_DB ]
then
  echo "Installing XIANGMIN_PGQL"
  wget https://get.enterpriseCAP_DB.com/XIANGMIN_PGql/XIANGMIN_PGql-10.1-1-linux-x64-binaries.tar.gz -O $CapstoneFetch/XIANGMIN_PGql.tar.gz
  mkdir -p $CapstoneTempZIP/XIANGMIN_PGql
  tar -zxvf $CapstoneFetch/XIANGMIN_PGql.tar.gz -C $CapstoneTempZIP/XIANGMIN_PGql --strip-components=1
  mv $CapstoneTempZIP/* $CAP_DB
  rm -rf $CapstoneFetch/XIANGMIN_PGql.tar.gz
fi

START=`date +%s`
if [ ! -d $CAP_DBJSON ]
then
  mkdir -p $CAP_DBJSON
  sudo chown -R XIANGMIN_PG:XIANGMIN_PG $CAP_DBJSON
  sudo -u XIANGMIN_PG $CAP_DB/bin/initCAP_DB -d $CAP_DBJSON
  sudo -u XIANGMIN_PG $CAP_DB/bin/pg_ctl start -D $CAP_DBJSON
  echo "start import XIANGMIN_PG data!!!"
  sleep 5
  sudo $CapstoneBench/XIANGMIN_PGql_jsonb/import.sh $CAP_DBJSON $CAP_DB $CapstoneBench
  sudo -u XIANGMIN_PG $CAP_DB/bin/pg_ctl stop -D $CAP_DBJSON
  sudo sed -i.bak -e "s/#listen_addresses = 'localhost'/listen_addresses = '*'/g" $CAP_DBJSON/XIANGMIN_PGql.conf
  sudo bash -c "echo 'host all all 0.0.0.0/0 trust' >> $CAP_DBJSON/pg_hba.conf"
fi
END=`date +%s`
echo "Import took: $((END - START)) seconds"
