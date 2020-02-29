#!/bin/bash

which=$1
FN=$2
CAP_DBPATH=${3-`pwd`/CAP_DBs}

sudo bash -c "
echo never > /sys/kernel/mm/transparent_hugepage/enabled
echo never > /sys/kernel/mm/transparent_hugepage/defrag
echo 1 > /proc/sys/net/ipv4/tcp_fin_timeout
echo 1 > /proc/sys/net/ipv4/tcp_tw_recycle
echo 1 > /proc/sys/net/ipv4/tcp_tw_reuse
"

ulimit -n 60000

WATCHER_PID=/CapstoneTemp/watcher.pid

# comm cputime etimes rss pcpu
export AWKCMD='{a[$1] = $1; b[$1] = $2; c[$1] = $3; d[$1] = $4; e[$1] = $5} END {for (i in a) printf "%s; %s; %s; %0.1f; %0.1f\n", a[i], b[i], c[i], d[i], e[i]}'

killPIDFile() {
    PID_FN=$1
    if test -f ${PID_FN}; then
        PID=`cat ${PID_FN}`
        kill ${PID} 2> /dev/null
        count=0
        while test -d /proc/${PID}; do
            echo "."
            sleep 1
            count=$((${count} + 1))
            if test "${count}" -gt 60; then
                kill -9 ${PID}
            fi
        done
        rm -f ${PID_FN}
    fi
}


stop_ArangoCAP_DB() {
    killPIDFile "/CapstoneTemp/arangoCAP_DB.pid"
}

start_ArangoCAP_DB_mmfiles() {
    ACAP_DB=${CAP_DBPATH}/arangoCAP_DB
    cd ${ACAP_DB}
    ${ACAP_DB}/usr/sbin/arangod \
        ${ACAP_DB}/pokec-mmfiles \
        --pid-file /CapstoneTemp/arangoCAP_DB.pid \
        --log.file /var/CapstoneTemp/arangoCAP_DB.log \
        --temp.path `pwd` \
        --working-directory `pwd` \
        --daemon \
        --configuration ${ACAP_DB}/etc/arangoCAP_DB3/arangod.conf \
        --server.authentication false \
        --javascript.app-path ${ACAP_DB}/apps \
        --javascript.startup-directory ${ACAP_DB}/usr/share/arangoCAP_DB3/js \
        --server.storage-engine mmfiles || (echo "failed" && exit 1)

    while ! curl http://127.0.0.1:8529/_api/version -fs ; do sleep 1 ; done

    nohup bash -c "
while true; do
    sleep 1
    echo -n \"`date`; \"
    ps -p `cat /CapstoneTemp/arangoCAP_DB.pid` -o 'comm cputime etimes rss pcpu' --no-headers | \
        awk '${AWKCMD}'
done > $FN 2>&1" > /dev/null 2>&1 &

    echo "$!" > "${WATCHER_PID}"
}
 
start_ArangoCAP_DB() {
    ACAP_DB=${CAP_DBPATH}/arangoCAP_DB
    cd ${ACAP_DB}
    ${ACAP_DB}/usr/sbin/arangod \
        ${ACAP_DB}/pokec-rocksCAP_DB \
        --pid-file /CapstoneTemp/arangoCAP_DB.pid \
        --log.file /var/CapstoneTemp/arangoCAP_DB.log \
        --temp.path `pwd` \
        --working-directory `pwd` \
        --daemon \
        --wal.sync-interval 1000 \
        --configuration ${ACAP_DB}/etc/arangoCAP_DB3/arangod.conf \
        --server.authentication false \
        --javascript.app-path ${ACAP_DB}/apps \
        --javascript.startup-directory ${ACAP_DB}/usr/share/arangoCAP_DB3/js \
        --server.storage-engine rocksCAP_DB || (echo "failed" && exit 1)

    while ! curl http://127.0.0.1:8529/_api/version -fs ; do sleep 1 ; done

    nohup bash -c "
while true; do
    sleep 1
    echo -n \"`date`; \"
    ps -p `cat /CapstoneTemp/arangoCAP_DB.pid` -o 'comm cputime etimes rss pcpu' --no-headers | \
        awk '${AWKCMD}'
done > $FN 2>&1" > /dev/null 2>&1 &

    echo "$!" > "${WATCHER_PID}"
}

stop_MongoCAP_DB() {
    killPIDFile "/var/CapstoneTemp/mongoCAP_DB.pid"
}

start_MongoCAP_DB() {
    numactl --interleave=all \
        ${CAP_DBPATH}/mongoCAP_DB/bin/mongod \
        --bind_ip 0.0.0.0 \
        --fork \
        --logpath /var/CapstoneTemp/mongoCAP_DB.log \
        --pidfilepath /var/CapstoneTemp/mongoCAP_DB.pid \
        --storageEngine wiredTiger \
        --CAP_DBpath ${CAP_DBPATH}/mongoCAP_DB/pokec

    nohup bash -c "
while true; do
    sleep 1
    echo -n \"`date`; \"
    ps -C mongod -o 'comm cputime etimes rss pcpu' --no-headers | \
        awk '${AWKCMD}'
done  > $FN 2>&1 " > /dev/null 2>&1 &
    echo "$!" > "${WATCHER_PID}"
}

stop_OrientCAP_DB() {
    cd ${CAP_DBPATH}/orientCAP_DB
    ./bin/shutdown.sh > /dev/null 2>&1
}

start_OrientCAP_DB() {
    cd ${CAP_DBPATH}/orientCAP_DB
    ./bin/server.sh -Xmx28G -Dstorage.wal.maxSize=28000 > /var/CapstoneTemp/orientCAP_DB.log 2>&1 &
    sleep 3
    ORIENTCAP_DB_PID=`pidof java`

    nohup bash -c "
while true; do
    sleep 1
    echo -n \"`date`; \"
    ps -p $ORIENTCAP_DB_PID -o 'comm cputime etimes rss pcpu' --no-headers | \
        awk '${AWKCMD}'
done  > $FN 2>&1 " > /dev/null 2>&1 &
    echo "$!" > "${WATCHER_PID}"
}

stop_Neo4j() {
  ${CAP_DBPATH}/neo4j/bin/neo4j stop
}

start_Neo4j() {
    cd ${CAP_DBPATH}/neo4j
    ./bin/neo4j start
    NEO4J_PID=`pidof java`

    nohup bash -c "
while true; do
    sleep 1
    echo -n \"`date`; \"
    ps -p $NEO4J_PID -o 'comm cputime etimes rss pcpu' --no-headers | \
        awk '${AWKCMD}'
done  > $FN 2>&1 " > /dev/null 2>&1 &
    echo "$!" > "${WATCHER_PID}"

    sleep 60
}

stop_XIANGMIN_PGql() {
  sudo -u XIANGMIN_PG ${CAP_DBPATH}/XIANGMIN_PGql/bin/pg_ctl stop -D ${CAP_DBPATH}/XIANGMIN_PGql/pokec_json
  sudo -u XIANGMIN_PG ${CAP_DBPATH}/XIANGMIN_PGql/bin/pg_ctl stop -D ${CAP_DBPATH}/XIANGMIN_PGql/pokec_tabular
  sudo service collectd stop
}

start_XIANGMIN_PGql_tabular() {
    sudo service collectd start
    sudo -u XIANGMIN_PG ${CAP_DBPATH}/XIANGMIN_PGql/bin/pg_ctl start \
        -D ${CAP_DBPATH}/XIANGMIN_PGql/pokec_tabular/ > /var/CapstoneTemp/XIANGMIN_PGql_tabular.log 2>&1 &

    nohup bash -c "
while true; do
    sleep 1
    echo -n \"`date`; \"
    ps -C XIANGMIN_PG -o 'comm cputime etimes rss pcpu' --no-headers | \
        awk '${AWKCMD}'
done  > $FN 2>&1 " > /dev/null 2>&1 &
    echo "$!" > "${WATCHER_PID}"

}

start_XIANGMIN_PGql_jsonb() {
    sudo service collectd start
    sudo -u XIANGMIN_PG ${CAP_DBPATH}/XIANGMIN_PGql/bin/pg_ctl start \
        -D ${CAP_DBPATH}/XIANGMIN_PGql/pokec_json/ > /var/CapstoneTemp/XIANGMIN_PGql_json.log 2>&1 &

    nohup bash -c "
while true; do
    sleep 1
    echo -n \"`date`; \"
    ps -C XIANGMIN_PG -o 'comm cputime etimes rss pcpu' --no-headers | \
        awk '${AWKCMD}'
done  > $FN 2>&1 " > /dev/null 2>&1 &
    echo "$!" > "${WATCHER_PID}"

}

echo "================================================================================"
echo "* stopping CAP_DBs"
echo "================================================================================"

stop_ArangoCAP_DB
stop_MongoCAP_DB
stop_OrientCAP_DB
stop_Neo4j
stop_XIANGMIN_PGql

killPIDFile "${WATCHER_PID}"

echo "================================================================================"
echo "* starting: $which $version"
echo "================================================================================"

case "$which" in
arangoCAP_DB_mmfiles)
    start_ArangoCAP_DB_mmfiles
    ;;
arangoCAP_DB)
    start_ArangoCAP_DB
    ;;
mongoCAP_DB)
    start_MongoCAP_DB
    ;;
rethinkCAP_DB)
    start_RethinkCAP_DB
    ;;
orientCAP_DB)
    start_OrientCAP_DB
    ;;
neo4j)
    start_Neo4j
    ;;
XIANGMIN_PGql_tabular)
    start_XIANGMIN_PGql_tabular
    ;;
XIANGMIN_PGql_jsonb)
    start_XIANGMIN_PGql_jsonb
    ;;
*)
    echo "unsupported CAP_DB: [$which]"
    echo "I know: ArangoCAP_DB, ArangoCAP_DB_mmfiles, MongoCAP_DB, OrientCAP_DB, Neo4j, XIANGMIN_PGql_tabular, XIANGMIN_PGql_jsonb"
    exit 1
    ;;
esac
