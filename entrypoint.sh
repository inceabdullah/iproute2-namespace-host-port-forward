#!/bin/bash

PROGNAME=$0
for i in "$@"
do
case $i in
    -n=*|--ns=*)
    NS="${i#*=}"
    echo -e "NS: ${NS}"
    ;;
    -h=*|--host-port=*)
    HOST_PORT="${i#*=}"
    echo -e "HOST_PORT: ${HOST_PORT}"    
    ;;
    --host-host=*)
    HOST_HOST="${i#*=}"
    echo -e "HOST_HOST: ${HOST_HOST}"    
    ;;
    --ns-port=*)
    NS_PORT="${i#*=}"
    echo -e "NS_PORT: ${NS_PORT}"    
    ;;
    --destination-host=*)
    DESTINATION_HOST="${i#*=}"
    echo -e "DESTINATION_HOST: ${DESTINATION_HOST}"    
    ;;
    --destination-port=*)
    DESTINATION_PORT="${i#*=}"
    echo -e "DESTINATION_PORT: ${DESTINATION_PORT}"    
    ;;
    --destination-to=*)
    DESTINATION_TO="${i#*=}"
    echo -e "DESTINATION_TO: ${DESTINATION_TO}"    
    ;;
    --help)
    HELP=1
    ;;
    *)
            # unknown option
    ;;
esac
done

if [ -z "$1" ]
then
cat << EOF >&2
Usage: ns-host-forward --help

EOF
exit 0
fi

if [ ! -z "$HELP" ]
then
cat << EOF >&2
Usage: ns-host-forward [--host-host=HOST] [-h|--host-port=PORT] [-n|--ns=net-1] [--ns-port=PORT]

Example
ns-host-forward --host-host=192.168.2.106 --host-port=5900 --ns=net-1 --ns-port=5900
EOF
exit 0
fi

if [ -z "$HOST_HOST" ]
then
    HOST_HOST="0.0.0.0"
fi

NETNS_COMMAND_PREFIX="ip netns exec ${NS} "


if [ -z "$NS" ]
then
    NETNS_COMMAND_PREFIX=""
else
    DESTINATION_HOST="0.0.0.0"
    DESTINATION_PORT="${NS_PORT}"
fi

echo "\$@: $@"
if [ "$DESTINATION_TO" == "ns" ]; then
        UNIX_FILE="/tmp/socket_${HOST_HOST}_${HOST_PORT}_${NS}_${NS_PORT}_${DESTINATION_TO}"
        echo "$UNIX_FILE"
        socat -lf/dev/null unix-listen:\"${UNIX_FILE}\",fork,reuseaddr TCP:${HOST_HOST}:${HOST_PORT} &
        ip netns exec ${NS} socat -lf/dev/null tcp-listen:${NS_PORT},fork,reuseaddr unix-connect:\"${UNIX_FILE}\"
else
    bash -c "socat tcp-listen:${HOST_PORT},fork,reuseaddr exec:'${NETNS_COMMAND_PREFIX}socat STDIO \"tcp-connect:${DESTINATION_HOST}:${DESTINATION_PORT}\"',nofork"
fi


