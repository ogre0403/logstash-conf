#!/bin/bash

LS_HOME=/opt/logstash
BASEDIR=$(dirname $0)
SERVER_LIST=$(cat ${BASEDIR}/Braavos.hosts |grep hc|awk '{print $2}')
FORWARDER=hcjnc118

USER=root


if [ "$#" -eq 0 ]; then
    echo "no logstash operation, EXIT"
    echo "useage: ./logstash-launcher.sh  [start|stop]"
    exit 0
fi

if [ "$1" == start ]; then
    # START all forward logstash in host which are listed in Braavos.hosts
    for h in $SERVER_LIST; do
        isexist=`ssh $USER@$h "ps aux |grep java" | grep "system-log.conf"` 
        if [[ -z "$isexist" ]]; then
            echo "start logstash agent in $h"
            ssh  -f $USER@$h "$LS_HOME/bin/logstash agent -f $LS_HOME/system-log.conf" > /dev/null 2>&1
        else
            echo logstash already running in $h
        fi 
    done

    # START forward logstash in host which execute launcher script
    isexist=`ssh $USER@$FORWARDER "ps aux |grep java" | grep "forward.conf"` 
    if [[ -z "$isexist" ]]; then
        echo "start forward agent in $HOSTNAME"
        ssh -f $USER@$FORWARDER "$LS_HOME/bin/logstash agent -f $LS_HOME/forward.conf" > /dev/null 2>&1
    else
        echo forward agent already running $HOSTNAME
    fi 
fi

if [ "$1" == stop ]; then
    # STOP all forward logstash in host which are listed in Braavos.hosts
    for h in $SERVER_LIST; do
        TMP=`ssh $USER@$h "ps aux |grep java" | grep "system-log.conf"` 
        logPID=`echo $TMP | awk '{print $2}'`
        if [[ -n "$logPID" ]]; then
            echo "kill logstash agent ($logPID) on $h"
            ssh $USER@$h " kill $logPID"
            echo ""
        else
            echo logstash already shutdown in $h
        fi
    done
    
    #STOP forward logstash in host which execute launcher script
    TMP=`ssh $USER@$FORWARDER "ps aux |grep java" | grep "forward.conf"` 
    logPID=`echo $TMP | awk '{print $2}'` 
    if [[ -n "$logPID" ]]; then
        echo "kill forward agent ($logPID) on $FORWARDER"
        ssh $USER@$FORWARDER " kill $logPID"
    else
        echo logstash already shutdown in $h
    fi
fi

