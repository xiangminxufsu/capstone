#!/bin/bash

CAP_DBPATH=${1-`pwd`/CAP_DBs}

sudo bash -c "
echo never > /sys/kernel/mm/transparent_hugepage/enabled
echo never > /sys/kernel/mm/transparent_hugepage/defrag
echo 1 > /proc/sys/net/ipv4/tcp_fin_timeout
echo 1 > /proc/sys/net/ipv4/tcp_tw_recycle
echo 1 > /proc/sys/net/ipv4/tcp_tw_reuse
"

WATCHER_PID=/CapstoneTemp/watcher.pid
export AWKCMD='{a[$1] = $1; b[$1] = $2; c[$1] = $3; d[$1] = $4}END{for (i in a)printf "%s, %s, %s, %0.1f\n", a[i], b[i], c[i], d[i]}'

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
 
stop_MongoCAP_DB() {
    killPIDFile "/var/CapstoneTemp/mongoCAP_DB.pid"
}

stop_OrientCAP_DB() {
    cd ${CAP_DBPATH}/orientCAP_DB
    ./bin/shutdown.sh > /dev/null 2>&1
}

stop_Neo4j() {
    ${CAP_DBPATH}/neo4j/bin/neo4j stop
}

stop_XIANGMIN_PGql() {
    sudo -u XIANGMIN_PG ${CAP_DBPATH}/XIANGMIN_PGql/bin/pg_ctl stop -D ${CAP_DBPATH}/XIANGMIN_PGql/pokec_json
    sudo -u XIANGMIN_PG ${CAP_DBPATH}/XIANGMIN_PGql/bin/pg_ctl stop -D ${CAP_DBPATH}/XIANGMIN_PGql/pokec_tabular
    sudo service collectd stop
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
