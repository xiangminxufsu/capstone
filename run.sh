#!/bin/bash

XIANGMIN_TEST_IP=${1-127.0.0.1}
XIANGMIN_LOOP_COUNT=${2-20}
CapstoneBench=${3-`pwd`}
CAP_DBPATH=${4-`pwd`/CAP_DBs}
XIANGMIN_USER=${5-ubuntu}

# ./runTest.sh arangoCAP_DB $XIANGMIN_TEST_IP $XIANGMIN_LOOP_COUNT $CapstoneBench $CAP_DBPATH $XIANGMIN_USER
# ./runTest.sh arangoCAP_DB_mmfiles $XIANGMIN_TEST_IP $XIANGMIN_LOOP_COUNT $CapstoneBench $CAP_DBPATH $XIANGMIN_USER
# ./runTest.sh neo4j $XIANGMIN_TEST_IP $XIANGMIN_LOOP_COUNT $CapstoneBench $CAP_DBPATH $XIANGMIN_USER
./runTest.sh XIANGMIN_PGql_jsonb $XIANGMIN_TEST_IP $XIANGMIN_LOOP_COUNT $CapstoneBench $CAP_DBPATH $XIANGMIN_USER
# ./runTest.sh XIANGMIN_PGql_tabular $XIANGMIN_TEST_IP $XIANGMIN_LOOP_COUNT $CapstoneBench $CAP_DBPATH $XIANGMIN_USER
# ./runTest.sh mongoCAP_DB $XIANGMIN_TEST_IP $XIANGMIN_LOOP_COUNT $CapstoneBench $CAP_DBPATH $XIANGMIN_USER
