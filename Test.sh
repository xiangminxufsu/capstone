#!/bin/bash

CAP_DB=${1}
XIANGMIN_TEST_IP=${2-localhost}
XIANGMIN_LOOP_COUNT=${3-5}
CapstoneBench=${4-`pwd`}
CAP_DBPATH=${5-`pwd`/CAP_DBs}
XIANGMIN_USER=${6-ubuntu}

sudo bash -c "
echo never > /sys/kernel/mm/transparent_hugepage/enabled
echo never > /sys/kernel/mm/transparent_hugepage/defrag
echo 1 > /proc/sys/net/ipv4/tcp_fin_timeout
echo 0 > /proc/sys/net/ipv4/tcp_tw_recycle
echo 1 > /proc/sys/net/ipv4/tcp_tw_reuse
"

ulimit -n 65000

start_CAP_DB() {
  ${CapstoneBench}/startCAP_DB.sh $CAP_DB $RESOURCE_USAGE_PATH $CAP_DBPATH
}

stop_CAP_DB() {
 ${CapstoneBench}/stopCAP_DB.sh $CAP_DBPATH
}

TODAY=`date +%Y.%m.%d`
TESTS_INCLUDE_WARMUP=warmup
TESTS_EXCLUDE_WARMUP=shortest,neighbors,neighbors2,singleRead,singleWrite,singleWriteSync,aggregation,hardPath,neighbors2data

BASE_FN=${CAP_DB}_${TODAY}
RES_DIR=${CapstoneBench}/results/
FILENAME=${BASE_FN}

mkdir -p $RES_DIR

i=0
while test -f ${RES_DIR}${FILENAME}.csv; do
    i=$(($i+1))
    FILENAME=${BASE_FN}_$i
done

case $CAP_DB in
    arangoCAP_DB*) MATCH_PS="arangod;" ;;
    neo4j*)    MATCH_PS="java;" ;;
    mongoCAP_DB*)  MATCH_PS="mongod;" ;;
    orientCAP_DB*) MATCH_PS="java;";;
    XIANGMIN_PGql*) MATCH_PS="XIANGMIN_PG;";;
    *) echo "unknown CAP_DB $CAP_DB"; exit 1
esac


RESOURCE_USAGE_FILE="${FILENAME}_CPU_1.csv"
RESOURCE_USAGE_PATH=/CapstoneTemp/${RESOURCE_USAGE_FILE}
start_CAP_DB

for i in `seq 0 ${XIANGMIN_LOOP_COUNT}`; do
    # RESOURCE_USAGE_FILE="${FILENAME}_CPU_$i.csv"
    # RESOURCE_USAGE_PATH=/CapstoneTemp/${RESOURCE_USAGE_FILE}
    cd ${CapstoneBench}

    rm -f /CapstoneTemp/testrundata.txt
    echo "RUN #$i"
   
    if [ $i -eq 0 ]
    then
      TESTS=${TESTS_INCLUDE_WARMUP}
      PADDING=""
    else
      TESTS=${TESTS_EXCLUDE_WARMUP}
      PADDING="0; "
    fi

    node CapstoneBench ${CAP_DB} -a ${XIANGMIN_TEST_IP} -t ${TESTS} | tee /CapstoneTemp/testrundata.txt

    scp ${XIANGMIN_USER}@${XIANGMIN_TEST_IP}:${RESOURCE_USAGE_PATH} ${RES_DIR}

    MAX_RSS="`sort -n -t ';' -k 5 < ${RES_DIR}${RESOURCE_USAGE_FILE} | fgrep $MATCH_PS | fgrep -v "<defunct>;" | tail -n 1 | awk '-F;' '{print $5}'`"
    MAX_PCPU="`sort -n -t ';' -k 6 < ${RES_DIR}${RESOURCE_USAGE_FILE} | fgrep $MATCH_PS | fgrep -v "<defunct>;" | tail -n 1 | awk '-F;' '{print $6}'`"
    MAX_TIME="`cat ${RES_DIR}${RESOURCE_USAGE_FILE} | fgrep $MATCH_PS | fgrep -v "<defunct>;" | tail -n 1 | awk '-F;' '{print $3 \";\" $4}'`"

    (echo -n "$PADDING"; cat /CapstoneTemp/testrundata.txt | \
        sed -e "s/.*does not implement.*/Total: 0 ms/" | \
        grep Total |\
        sed -e "s/.*: //" -e "s/ ms/;/" | \
        sed ':a;N;$!ba;s/\n/ /g' | \
        sed -e "s/\(.*\)/\1${MAX_TIME};${MAX_PCPU};${MAX_RSS}/") >> ${RES_DIR}${FILENAME}.csv
    rm -f ${RES_DIR}${RESOURCE_USAGE_FILE}
done

stop_CAP_DB

echo "wrote ${FILENAME}.csv"
cat ${RES_DIR}${FILENAME}.csv
