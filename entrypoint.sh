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
    --container-host=*)
    CONTAINER_HOST="${i#*=}"
    echo -e "CONTAINER_HOST: ${CONTAINER_HOST}"    
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
    --forward-to=*)
    FORWARD_TO="${i#*=}"
    echo -e "FORWARD_TO: ${FORWARD_TO}"    
    ;;
    --container-id=*)
    CONTAINER_ID="${i#*=}"
    echo -e "CONTAINER_ID: ${CONTAINER_ID}"    
    ;;
    --container-port=*)
    CONTAINER_PORT="${i#*=}"
    echo -e "CONTAINER_PORT: ${CONTAINER_PORT}"    
    ;;
    --source-container-id=*)
    SOURCE_CONTAINER_ID="${i#*=}"
    echo -e "SOURCE_CONTAINER_ID: ${SOURCE_CONTAINER_ID}"    
    ;;
    --source-port=*)
    SOURCE_PORT="${i#*=}"
    echo -e "SOURCE_PORT: ${SOURCE_PORT}"    
    ;;
    --dest-container-id=*)
    DEST_CONTAINER_ID="${i#*=}"
    echo -e "DEST_CONTAINER_ID: ${DEST_CONTAINER_ID}"    
    ;;
    --dest-port=*)
    DEST_PORT="${i#*=}"
    echo -e "DEST_PORT: ${DEST_PORT}"    
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

if [ -z "$CONTAINER_HOST" ]
then
    CONTAINER_HOST="0.0.0.0"
fi

NETNS_COMMAND_PREFIX="ip netns exec ${NS} "


if [ -z "$NS" ]
then
    NETNS_COMMAND_PREFIX=""
else
    DESTINATION_HOST="0.0.0.0"
    DESTINATION_PORT="${NS_PORT}"
fi

# Get the IP address of the source Docker container
if [ ! -z "$SOURCE_CONTAINER_ID" ]; then
    SOURCE_DOCKER_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $SOURCE_CONTAINER_ID)
    echo -e "SOURCE_DOCKER_IP: ${SOURCE_DOCKER_IP}"
fi

# Get the IP address of the destination Docker container
if [ ! -z "$DEST_CONTAINER_ID" ]; then
    DEST_DOCKER_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $DEST_CONTAINER_ID)
    echo -e "DEST_DOCKER_IP: ${DEST_DOCKER_IP}"
fi

echo "\$@: $@"
if [ "$DESTINATION_TO" == "ns" ]; then
        UNIX_FILE="/tmp/socket_${HOST_HOST}_${HOST_PORT}_${NS}_${NS_PORT}_${DESTINATION_TO}"
        echo "$UNIX_FILE"
        socat -lf/dev/null unix-listen:\"${UNIX_FILE}\",fork,reuseaddr TCP:${HOST_HOST}:${HOST_PORT} &
        ip netns exec ${NS} socat -lf/dev/null tcp-listen:${NS_PORT},fork,reuseaddr unix-connect:\"${UNIX_FILE}\"
elif [ "$DESTINATION_TO" == "container" ]; then
        PATTERN="${HOST_HOST}_${HOST_PORT}_container_${CONTAINER_ID}_${CONTAINER_HOST}_${CONTAINER_PORT}_destination_${DESTINATION_TO}_forward_to_${FORWARD_TO}"
        # gettin docker PID
        CONTAINER_PID=`docker inspect -f '{{.State.Pid}}' ${CONTAINER_ID}`
        echo -e "${CONTAINER_ID}\t=>\t$CONTAINER_PID"

        # remove old namespace
        unlink /var/run/netns/${PATTERN} 2>/dev/null &

        # making ns with PID
        TARGET="/proc_host/${CONTAINER_PID}/ns/net"
        MOUNT_POINT="/var/run/netns/${PATTERN}"
        echo -e "TARGET:\t${TARGET}\MOUNT_POINT:\t${MOUNT_POINT}"

        mkdir -p /var/run/netns
        touch $MOUNT_POINT
        mount -o bind $TARGET $MOUNT_POINT

        UNIX_FILE="/tmp/socket_${PATTERN}"
        echo -e "Unix file:\t$UNIX_FILE"

        NS=$PATTERN
        NS_PORT=$CONTAINER_PORT
        
        socat -lf/dev/null unix-listen:\"${UNIX_FILE}\",fork,reuseaddr TCP:${HOST_HOST}:${HOST_PORT} &
        ip netns exec ${NS} socat -lf/dev/null tcp-listen:${NS_PORT},fork,reuseaddr unix-connect:\"${UNIX_FILE}\"
elif [ "$DESTINATION_TO" == "docker" ]; then
    # Get the PID of the source Docker container
    SOURCE_CONTAINER_PID=$(docker inspect -f '{{.State.Pid}}' $SOURCE_CONTAINER_ID)
    echo -e "${SOURCE_CONTAINER_ID}\t=>\t$SOURCE_CONTAINER_PID"

    # Get the PID of the destination Docker container
    DEST_CONTAINER_PID=$(docker inspect -f '{{.State.Pid}}' $DEST_CONTAINER_ID)
    echo -e "${DEST_CONTAINER_ID}\t=>\t$DEST_CONTAINER_PID"

    # Create a network namespace for the source Docker container
    SOURCE_PATTERN="source_${SOURCE_CONTAINER_ID}_${SOURCE_PORT}"

    SOURCE_TARGET="/proc_host/${SOURCE_CONTAINER_PID}/ns/net"
    SOURCE_MOUNT_POINT="/var/run/netns/${SOURCE_PATTERN}"
    mkdir -p /var/run/netns
        # remove old namespace
        unlink ${SOURCE_MOUNT_POINT} 2>/dev/null || true
    touch $SOURCE_MOUNT_POINT
    mount -o bind $SOURCE_TARGET $SOURCE_MOUNT_POINT

    # Create a network namespace for the destination Docker container
    DEST_PATTERN="dest_${DEST_CONTAINER_ID}"
    DEST_TARGET="/proc_host/${DEST_CONTAINER_PID}/ns/net"
    DEST_MOUNT_POINT="/var/run/netns/${DEST_PATTERN}"
    mkdir -p /var/run/netns
        # remove old namespace
        unlink ${DEST_MOUNT_POINT} 2>/dev/null || true   
    touch $DEST_MOUNT_POINT
    mount -o bind $DEST_TARGET $DEST_MOUNT_POINT

    # Use socat and ip netns to set up port forwarding between the source and destination Docker containers
    UNIX_FILE_SOURCE="/tmp/socket_${SOURCE_PATTERN}"
    UNIX_FILE_DEST="/tmp/socket_${DEST_PATTERN}"
    # echo ip netns exec ${DEST_PATTERN} socat -lf/dev/null unix-listen:\"${UNIX_FILE_DEST}\",fork,reuseaddr TCP:$HOST_HOST:$DEST_PORT &&
    ip netns exec ${DEST_PATTERN} socat -lf/dev/null unix-listen:\"${UNIX_FILE_DEST}\",fork,reuseaddr TCP:$HOST_HOST:$DEST_PORT &
    # echo ip netns exec ${SOURCE_PATTERN} socat -lf/dev/null tcp-listen:$SOURCE_PORT,fork,reuseaddr unix-connect:\"${UNIX_FILE_DEST}\" &&
    ip netns exec ${SOURCE_PATTERN} socat -lf/dev/null tcp-listen:$SOURCE_PORT,fork,reuseaddr unix-connect:\"${UNIX_FILE_DEST}\"
    # echo ""
else
    bash -c "socat tcp-listen:${HOST_PORT},fork,reuseaddr exec:'${NETNS_COMMAND_PREFIX}socat STDIO \"tcp-connect:${DESTINATION_HOST}:${DESTINATION_PORT}\"',nofork"
fi


#TODO docker to docker