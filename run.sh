#!/bin/bash

# TODO check container is running
# TODO ask stop conainer 
# TODO is port 53 free eg is used from dnsmasq

GIT_OWNER_NAME=$(git config user.name| tr '[:upper:]' '[:lower:]')
BASH_OWNER_NAME=$(id -u -n)
OWNER_NAME=${GIT_OWNER_NAME:-BASH_OWNER_NAME}
CONTAINER_NAME=${CONTAINER_NAME:-c-unbound-docker}
IMAGES_NAME=${IMAGES_NAME:-i-unbound-docker}
TAG_NAME=${TAG_NAME:-latest}

if  docker images ${OWNER_NAME}/${IMAGES_NAME}:${TAG_NAME} | grep -q ${OWNER_NAME}/${IMAGES_NAME}; then
  echo "exists"
else
  echo "doesn't exist"
echo " build first "

read -r -p "Are you sure? [y/N] " response
case "$response" in [yY][eE][sS]|[yY]) 
      echo "start build" 
      echo "docker build --tag ${OWNER_NAME}/${IMAGES_NAME} --file current/Dockerfile ."
      docker build --tag ${OWNER_NAME}/${IMAGES_NAME} --file current/Dockerfile $(pwd)/current
        ;;
    *)
        echo " do nothing  ciao"
	exit 0
        ;;
esac

fi


# check created container and if availble deleted 
# we want use always new container
# TODO is that stupid ??? 
docker ps -a| grep ${CONTAINER_NAME} | awk '{print $1}' | xargs --no-run-if-empty docker rm

#start container
docker run --name ${CONTAINER_NAME}  -d -p 53:53/udp \
-v $(pwd)/a-records.conf:/opt/unbound/etc/unbound/a-records.conf:ro \
${OWNER_NAME}/${IMAGES_NAME}:${TAG_NAME}
