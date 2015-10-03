#!/bin/bash


LS_HOME=/opt/logstash

BASEDIR=$(dirname $0)
#SERVER_LIST=$(cat ${BASEDIR}/Braavos.hosts |grep TC|awk '{print $2}')
SERVER_LIST=(TCJN)
USER=hdadm
echo "Enter remote [$USER] sudo password": 
read -s SUDOPW

echo $SERVER_LIST


if [ "$#" -eq 0 ]; then
    echo "no logstash operation, EXIT"
    exit 0
fi

if [ "$1" == start ]; then
    for h in $SERVER_LIST; do
        #isexist=`ssh $USER@$h "echo $SUDOPW | sudo -S jps | grep jruby-complete"`
        isexist=`ssh $USER@$h "ps aux |grep java" | grep "system-log.conf"` 
        if [[ -z "$isexist" ]]; then
            echo "start logstash agent in $h"
            ssh -f $USER@$h "echo $SUDOPW | sudo -S $LS_HOME/bin/logstash agent -f $LS_HOME/system-log.conf" > /dev/null 2>&1
        else
            echo logstash already running in $h
        fi 
    done

    # TODO: START forward logstash in host which execute launcher script
    
fi


if [ "$1" == stop ]; then
    for h in $SERVER_LIST; do
        #TMP=`ssh $USER@$h "echo $SUDOPW | sudo -S jps | grep jruby-complete"` 
        TMP=`ssh $USER@$h "ps aux |grep java" | grep "system-log.conf"` 
        logPID=`echo $TMP | awk '{print $2}'`
        if [[ -n "$logPID" ]]; then
            echo "kill logstash agent ($logPID) on $h"
            ssh $USER@$h " echo $SUDOPW | sudo -S kill $logPID"
            echo ""
        else
            echo logstash already shutdown in $h
        fi
    done
    
    # TODO: STOP forward logstash in host which execute launcher script
fi

