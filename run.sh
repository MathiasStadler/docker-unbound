#!/bin/bash




# TODO check container is running
# TODO ask stop conainer 
# TODO is port 53 free eg is used from dnsmasq


#set env
GIT_OWNER_NAME=$(git config user.name| tr '[:upper:]' '[:lower:]')
BASH_OWNER_NAME=$(id -u -n)
OWNER_NAME=${GIT_OWNER_NAME:-BASH_OWNER_NAME}
CONTAINER_NAME=${CONTAINER_NAME:-c-docker-unbound}
IMAGES_NAME=${IMAGES_NAME:-i-docker-unbound}
TAG_NAME=${TAG_NAME:-latest}


#getopt
while getopts ":n" opt; do
  case $opt in
    n)
      echo "-n delete images " >&2
      CREATE_NEW_IMAGES=yes;
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 0
      ;;
  esac
done


#exit on error
set -e

checkRunningContainerAndStop() {
if docker ps |grep -q ${OWNER_NAME}/${IMAGES_NAME}; then
echo "$(docker ps | grep ${OWNER_NAME}/${IMAGES_NAME}|wc -l ) running Container found ... $(docker ps |grep  ${OWNER_NAME}/${IMAGES_NAME}|awk '{print $1}')"
echo "stopping container now ..."
docker ps |grep  ${OWNER_NAME}/${IMAGES_NAME}|awk '{print $1}' | xargs --no-run-if-empty docker stop
else
echo "No container ${OWNER_NAME}/${IMAGES_NAME} running!...OK"
fi
}

checkImagesAndBuildNewIfNecessary() {

  if [ "$CREATE_NEW_IMAGES" = 'yes' ]; then
    #check images is advaible 
    if  docker images ${OWNER_NAME}/${IMAGES_NAME}:${TAG_NAME} | grep -q ${OWNER_NAME}/${IMAGES_NAME}; then
      echo "Delete current images  ${OWNER_NAME}/${IMAGES_NAME}:${TAG_NAME} "
      docker rmi ${OWNER_NAME}/${IMAGES_NAME}:${TAG_NAME} 
    else 
      echo "Images ${OWNER_NAME}/${IMAGES_NAME}:${TAG_NAME} no found...OK"
      echo "Nothing to do !...OK"
    fi 
  fi

  if  docker images ${OWNER_NAME}/${IMAGES_NAME}:${TAG_NAME} | grep -q ${OWNER_NAME}/${IMAGES_NAME}; then
    echo "Iamges ${OWNER_NAME}/${IMAGES_NAME}:${TAG_NAME} exists...OK"
  else
    echo "Iamges ${OWNER_NAME}/${IMAGES_NAME}:${TAG_NAME} doesn't exist"
    read -r -p "Would you like build this images now ? [y/N]" response
      case "$response" in [yY][eE][sS]|[yY]) 
        echo "start build images ${OWNER_NAME}/${IMAGES_NAME} " 
        echo "docker build --tag ${OWNER_NAME}/${IMAGES_NAME} --file current/Dockerfile ."
        docker build --tag ${OWNER_NAME}/${IMAGES_NAME} --file current/Dockerfile $(pwd)/current
         ;;
        *)
          echo "Without the images can you not start the docker container!"
          echo "Rerun the script and choise yes for build the images ...ciao"
	        exit 0
        ;;
      esac
    fi
}


deleteOldContainerAndDelete() {

# check created container and if availble deleted 
# we want use always new container
# TODO is that stupid ??? 

echo "We would start always a new Container"
echo "Check old container availble .."


if docker ps -a| grep ${CONTAINER_NAME}; then
  echo "$(docker ps -a| grep ${CONTAINER_NAME}|wc -l ) ${CONTAINER_NAME} container found"
  echo "we delete the container now ... "
    docker ps -a| grep ${CONTAINER_NAME} | awk '{print $1}' | xargs --no-run-if-empty docker rm
      if docker ps -a| grep ${CONTAINER_NAME}; then
        echo " Error we could't delete the container ${CONTAINER_NAME} ...Not OK"
        exit 1;
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
    CID=$(docker run --name ${CONTAINER_NAME}  -d -p 53:53/udp \
    -v $(pwd)/a-records.conf:/opt/unbound/etc/unbound/a-records.conf:ro \
    ${OWNER_NAME}/${IMAGES_NAME}:${TAG_NAME} )

    #give docker few seconds
    sleep 2
    
    if docker ps | grep  ${OWNER_NAME}/${IMAGES_NAME} | grep ${CONTAINER_NAME} | grep -q ${TAG_NAME} ; then 
      echo "Container ${OWNER_NAME}/${CONTAINER_NAME}:${TAG_NAME} with $(echo ${CID} | head -c 10 ) running...Ok"
    else
      echo "Error container no comming up...Not Ok"
    fi 
}



stopContainer() {
echo "stop conatiner ${CONTAINER_NAME}"
set +e
sudo docker rm -fv ${CID} >/dev/null 2>&1
set -e

}


interrupted () {
  echo 'Interrupted, cleaning up...'
  trap - INT
  stopContainer
  kill -INT $$
}
 
terminated () {
  echo 'Terminated, cleaning up...'
  trap - TERM
  stopContainer
  kill -TERM $$
}



run(){
echo "... run "
checkRunningContainerAndStop
checkImagesAndBuildNewIfNecessary
deleteOldContainerAndDelete
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
