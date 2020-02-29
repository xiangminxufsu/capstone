#!/bin/bash

CapstoneBench=${1-`pwd`}
CAP_DBPATH=${2-`pwd`/CAP_DBs}
CapstoneTemp=/CapstoneTemp/nosqlCapstoneBench
CapstoneFetch=$CapstoneTemp/CapstoneFetch

mkdir -p $CAP_DBPATH
mkdir -p $CapstoneFetch


## XIANGMIN_PGql
./XIANGMIN_PGql_jsonb/setup.sh $CapstoneBench $CAP_DBPATH $CapstoneTemp
# ./XIANGMIN_PGql_tabular/setup.sh $CapstoneBench $CAP_DBPATH $CapstoneTemp

## MongoCAP_DB
# ./mongoCAP_DB/setup.sh $CapstoneBench $CAP_DBPATH $CapstoneTemp
