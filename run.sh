#!/bin/bash

#format with shfmt

# TODO DONE check container is running
# TODO DONE would you stop a running container
# TODO is port 53 free eg is used from dnsmasq

#set env
GIT_OWNER_NAME=$(git config user.name | tr '[:upper:]' '[:lower:]')
BASH_OWNER_NAME=$(id -u -n)
OWNER_NAME=${GIT_OWNER_NAME:-$BASH_OWNER_NAME}
CONTAINER_NAME=${CONTAINER_NAME:-c-docker-unbound}
IMAGES_NAME=${IMAGES_NAME:-i-docker-unbound}
TAG_NAME=${TAG_NAME:-latest}
SERVER_KEYS_DIR=unbound_control_keys
OUTPUT_UNBOND_CONTROL_SETUP=output_unbound-control-setup.txt
ROUTINGTABLE="TRANSDNS"

DNS_PORT=53
DNS_PROXY_PORT=53

#getopt
while getopts ":n" opt; do
    case $opt in
    n)
        echo "-n delete images " >&2
        CREATE_NEW_IMAGES=yes
        ;;
    \?)
        echo "Invalid option: -$OPTARG" >&2
        exit 0
        ;;
    esac
done

#exit on error
set -e




start_routing () {
  # Add a new route table that routes everything marked through the new container
  # workaround boot2docker issue #367
  # https://github.com/boot2docker/boot2docker/issues/367
  [ -d /etc/iproute2 ] || sudo mkdir -p /etc/iproute2
  if [ ! -e /etc/iproute2/rt_tables ]; then
    if [ -f /usr/local/etc/rt_tables ]; then
      sudo ln -s /usr/local/etc/rt_tables /etc/iproute2/rt_tables
    elif [ -f /usr/local/etc/iproute2/rt_tables ]; then
      sudo ln -s /usr/local/etc/iproute2/rt_tables /etc/iproute2/rt_tables
    fi
  fi
  ([ -e /etc/iproute2/rt_tables ] && grep -q $ROUTINGTABLE /etc/iproute2/rt_tables) \
    || sudo sh -c "echo '1	$ROUTINGTABLE' >> /etc/iproute2/rt_tables"
  ip rule show | grep -q $ROUTINGTABLE \
    || sudo ip rule add from all fwmark 0x1 lookup $ROUTINGTABLE
  sudo ip route add default via "${IPADDR}" dev docker0 table $ROUTINGTABLE
  # Mark packets to port 80 and 443 external, so they route through the new
  # route table
  
  #SAVE org 
  #COMMON_RULES="-t mangle -I PREROUTING -p tcp -i docker0 ! -s ${IPADDR}
  #  -j MARK --set-mark 1"
  
  COMMON_RULES="-t nat -A OUTPUT -p udp --dport ${DNS_PORT} -j DNAT --to ${IPADDR}:${DNS_PROXY_PORT}"
  echo "Redirecting DNS to docker-"
  sudo iptables $COMMON_RULES 
   
   #TODO OLD start
   # if [ "$WITH_SSL" = 'yes' ]; then
   #   echo "Redirecting DNS to $CONTAINER_NAME"
   #   sudo iptables $COMMON_RULES --dport 443
  # else
  #    echo "Not redirecting HTTPS. To enable, re-run with the argument 'ssl'"
  #    echo "CA certificate will be generated anyway, but it won't be used"
  # fi
  
  # TODO OLD end
  # Exemption rule to stop docker from masquerading traffic routed to the
  # transparent proxy
  sudo iptables -t nat -I POSTROUTING -o docker0 -s 172.17.0.0/16 -j ACCEPT
}

stop_routing () {
    # Remove iptables rules.
    set +e
    ip route show table $ROUTINGTABLE | grep -q default \
        && sudo ip route del default table $ROUTINGTABLE
    while true; do
        #SAVE org
        #rule_num=$(sudo iptables -t mangle -L PREROUTING -n --line-numbers \
        #    | grep -E 'MARK.*172\.17.*tcp \S+ MARK set 0x1' \
        #    | awk '{print $1}' \
        #    | head -n1)

           rule_num=$(sudo iptables -t nat -L OUTPUT -n --line-numbers \
            | grep -E "${IPADDR}:${DNS_PROXY_PORT}" \
            | awk '{print $1}' \
            | head -n1) 
        [ -z "$rule_num" ] && break
        #SAVE org
        #sudo iptables -t mangle -D PREROUTING "$rule_num"
        sudo iptables -t nat  -D OUTPUT "$rule_num"
    done
    sudo iptables -t nat -D POSTROUTING -o docker0 -s 172.17.0.0/16 -j ACCEPT 2>/dev/null
    set -e
}




showAllUsedPort() {
    # from here
    # https://askubuntu.com/questions/699508/how-to-extract-mapped-ports-from-docker-pss-output
    sudo docker ps | awk -F" {2,}" 'END {print $6}'
}

createRemoteKeys() {

    echo "delete keys..."
    rm -rf *key *pem
    echo "create new keys..."
    if "$(pwd)"/unbound-control-setup.sh -d ${SERVER_KEYS_DIR} >/tmp/${OUTPUT_UNBOND_CONTROL_SETUP}; then
        echo "Keys generated...OK"
        rm -rf /tmp/${OUTPUT_UNBOND_CONTROL_SETUP}
    else
        echo "ERROR during execution"
        echo "Please see output file !!!...Not OK"
        cat /tmp/${OUTPUT_UNBOND_CONTROL_SETUP}
        exit 1
    fi
}

checkKeysForRemoteControl() {
    if ls -l | grep -q ${SERVER_KEYS_DIR}; then
        echo "Directory ${SERVER_KEYS_DIR} availble"
        #any files inside directory
        nItems="$(ls -1 --file-type ${SERVER_KEYS_DIR} | grep -v '/$' | wc -l)"
        if [ "${nItems}" = "0" ]; then
            echo "dir ${SERVER_KEYS_DIR} is empty, no files inside ..."
            createRemoteKeys
        else
            echo "=> ${SERVER_KEYS_DIR}"
            #nKeys="$(ls -l ${SERVER_KEYS_DIR}/*key | grep -c "${SERVER_KEYS_DIR}/*key")"
            nKeys="$(ls -1 --file-type ${SERVER_KEYS_DIR} | grep key| grep -v '/$' | wc -l)"
            echo "${nKeys}"
            if [ "${nKeys}" = "2" ]; then
                echo "${nKeys}/2 key fond...OK"
            else
                echo "${nKeys}/2 key fond...Not Ok"
                createRemoteKeys
            fi
            #nPems="$(ls -l ${SERVER_KEYS_DIR}/*pem | grep -c "${SERVER_KEYS_DIR}/*pem")"
            nPems="$(ls -1 --file-type ${SERVER_KEYS_DIR} | grep pem| grep -v '/$' | wc -l)"
            if [ "${nPems}" = "2" ]; then
                echo "${nPems}/ 2 key fond...OK"
            else
                echo "${nPems}/ 2 key fond...Not OK"
                createRemoteKeys
            fi
        fi
    else
        echo "Directory ${SERVER_KEYS_DIR} NOT availble, create new one..."
        mkdir -p ${SERVER_KEYS_DIR}
        touch .gitkeep
        createRemoteKeys
    fi
}

checkRunningContainerAndStop() {
    if docker ps | grep -q "${OWNER_NAME}/${IMAGES_NAME}"; then
        #TODO What is if we found more than container ?
        echo "$(docker ps | grep -c "${OWNER_NAME}/${IMAGES_NAME}") running Container found ... $(docker ps | grep "${OWNER_NAME}/${IMAGES_NAME}" | awk '{print $1}')"
        read -r -p "Would you like stop this container now ? Think on your Production  [y/N]" response
        case "$response" in [yY][eE][sS] | [yY])
            echo "stopping container now ..."
            docker ps | grep "${OWNER_NAME}/${IMAGES_NAME}" | awk '{print $1}' | xargs --no-run-if-empty docker stop >/dev/null
            ;;
        *)
            echo "A current conntainer is still running ..."
            docker ps | grep "${OWNER_NAME}/${IMAGES_NAME}" | grep "${CONTAINER_NAME}" | grep "${TAG_NAME}"
            echo "Have fun with it...ciao"
            exit 0
            ;;
        esac

    else

        echo "No container ${OWNER_NAME}/${IMAGES_NAME} running!...OK"
    fi
}

checkImagesAndBuildNewIfNecessary() {
    if [ "$CREATE_NEW_IMAGES" = 'yes' ]; then
        #check images is advaible
        if docker images "${OWNER_NAME}/${IMAGES_NAME}:${TAG_NAME}" | grep -q "${OWNER_NAME}/${IMAGES_NAME}"; then
            echo "Delete current images  ${OWNER_NAME}/${IMAGES_NAME}:${TAG_NAME}"
            docker rmi "${OWNER_NAME}/${IMAGES_NAME}:${TAG_NAME}"
        else
            echo "Images ${OWNER_NAME}/${IMAGES_NAME}:${TAG_NAME} no found...OK"
            echo "Nothing to do !...OK"
        fi
    fi
    if docker images "${OWNER_NAME}/${IMAGES_NAME}:${TAG_NAME}" | grep -q "${OWNER_NAME}/${IMAGES_NAME}"; then
        echo "Images ${OWNER_NAME}/${IMAGES_NAME}:${TAG_NAME} exists...OK"
    else
        echo "Images ${OWNER_NAME}/${IMAGES_NAME}:${TAG_NAME} doesn't exist"
        read -r -p "Would you like build this images now ? [y/N]" response
        case "$response" in [yY][eE][sS] | [yY])
            echo "start build images ${OWNER_NAME}/${IMAGES_NAME} "
            echo "docker build --tag ${OWNER_NAME}/${IMAGES_NAME} --file current/Dockerfile ."
            docker build --tag "${OWNER_NAME}/${IMAGES_NAME}" --file current/Dockerfile "$(pwd)"/current
            ;;
        *)
            echo "Without the images can you not start the docker container!"
            echo "Rerun the script and choise yes for build the images ...ciao"
            exit 0
            ;;
        esac
    fi
}

delteOldContainer() {

    # check created contu
    # we want use always new container
    # TODO is that stupid ???

    echo "We would start always a new Container"
    echo "Check old container availble .."

    if docker ps -a | grep "${CONTAINER_NAME}"; then
        echo "$(docker ps -a | grep -c "${CONTAINER_NAME}") ${CONTAINER_NAME} container found"
        echo "We delete the container now ... "
        docker ps -a | grep "${CONTAINER_NAME}" | awk '{print $1}' | xargs --no-run-if-empty docker rm
        if docker ps -a | grep "${CONTAINER_NAME}"; then
            echo " Error we could't delete the container ${CONTAINER_NAME} ...Not OK"
            exit 1
        else
            echo "All ${CONTAINER_NAME} container deleted...OK"
        fi
    else
        echo "No ${CONTAINER_NAME} container found for deleted...OK"
    fi
}

runContainer() {
    echo "run container ..."
    echo "Used ${OWNER_NAME}/${IMAGES_NAME}:${TAG_NAME} to start new ${CONTAINER_NAME} container"
    #start container
    CID=$(docker run --name "${CONTAINER_NAME}" -d \
        -v "$(pwd)"/a-records.conf:/opt/unbound/etc/unbound/a-records.conf:ro \
        -v "$(pwd)"/root.hints:/opt/unbound/etc/unbound/root.hints:ro \
        -v "$(pwd)"/unbound_control_keys/unbound_server.key:/opt/unbound/etc/unbound/unbound_server.key:ro \
        -v "$(pwd)"/unbound_control_keys/unbound_server.pem:/opt/unbound/etc/unbound/unbound_server.pem:ro \
        -v "$(pwd)"/unbound_control_keys/unbound_control.key:/opt/unbound/etc/unbound/unbound_control.key:ro \
        -v "$(pwd)"/unbound_control_keys/unbound_control.pem:/opt/unbound/etc/unbound/unbound_control.pem:ro \
        "${OWNER_NAME}/${IMAGES_NAME}:${TAG_NAME}")

IPADDR=$(sudo docker inspect --format '{{ .NetworkSettings.IPAddress }}' ${CID})

start_routing

#-p 53:53/udp \
#-p 53:53/tcp \

    #only for convenience see README.md
    echo ${CID} >unbound_container.id

    #give docker few seconds
    sleep 2

    if docker ps | grep "${OWNER_NAME}/${IMAGES_NAME}" | grep "${CONTAINER_NAME}" | grep -q "${TAG_NAME}"; then
        echo "Container ${OWNER_NAME}/${CONTAINER_NAME}:${TAG_NAME} with $(echo "${CID}" | head -c 12) running...Ok"
    else
        echo "Error container no comming up...Not Ok"
    fi
}

stopContainer() {
    echo "stop conatiner ${CONTAINER_NAME}"
    set +e
    sudo docker rm -fv "${CID}" >/dev/null 2>&1
    set -e
    stop_routing

}

interrupted() {
    echo 'Interrupted, cleaning up...'
    trap - INT
    stopContainer
    kill -INT $$
}

terminated() {
    echo 'Terminated, cleaning up...'
    trap - TERM
    stopContainer
    kill -TERM $$
}

run() {
    echo "... run "
    checkKeysForRemoteControl
    checkRunningContainerAndStop
    delteOldContainer
    checkImagesAndBuildNewIfNecessary
    runContainer

    # Run at console, kill cleanly if ctrl-c is hit
    trap interrupted INT
    trap terminated TERM
    sudo docker logs -f "${CID}"
    echo 'Squid exited unexpectedly, cleaning up...'
    stopContainer

}

run
echo
