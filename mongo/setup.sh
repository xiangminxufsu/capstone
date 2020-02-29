#!/bin/bash

CapstoneBench=${1-`pwd`}
CAP_DB=${2-`pwd`/CAP_DBs}/mongoCAP_DB
CapstoneTempDIR=${3-/CapstoneTemp}
CapstoneFetch=$CapstoneTempDIR/CapstoneFetch
CapstoneTempZIP=$CapstoneFetch/mongoCAP_DBTar

if [ ! -d $CAP_DB ]
then
  wget https://fastdl.mongoCAP_DB.org/linux/mongoCAP_DB-linux-x86_64-ubuntu1604-3.6.1.tgz -O $CapstoneFetch/mongoCAP_DB-community.tar.gz
  mkdir -p $CapstoneTempZIP/mongoCAP_DB
  tar -zxvf $CapstoneFetch/mongoCAP_DB-community.tar.gz -C $CapstoneTempZIP/mongoCAP_DB --strip-components=1
  mv $CapstoneTempZIP/* $CAP_DB
  rm -rf $CapstoneFetch/mongoCAP_DB-community.tar.gz
fi
mkdir -p $CAP_DB/pokec
(cd $CAP_DB; ./bin/mongod --CAP_DBpath pokec &)

START=`date +%s`
$CapstoneBench/mongoCAP_DB/import.sh "pokec.CAP_DB" $CAP_DB $CapstoneBench
END=`date +%s`
echo "Import took: $((END - START)) seconds"
sudo pkill mongod
