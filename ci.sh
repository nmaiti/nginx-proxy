#!/bin/bash 

###################################################################
# Script Name : ci.sh
# 
# Description :
#
# Args :
#
# Creation Date : 28-11-2020
# Last Modified :
# 
# Created By :  
###################################################################
#!/bin/bash

if [ "$TRAVIS_PULL_REQUEST" = "true" ] || [ "$TRAVIS_BRANCH" != "master" ]; then
  docker buildx build \
    --progress plain \
    --platform=linux/amd64,linux/386,linux/arm64,linux/arm/v7,linux/ppc64le \
    .
  exit $?
fi
echo $DOCKER_PASSWORD | docker login -u $DOCKER_USERID --password-stdin &> /dev/null
TAG="${TRAVIS_TAG:-latest}"
docker buildx build -f Dockerfile.alpine \
     --progress plain \
    --platform=linux/amd64,linux/386,linux/arm64,linux/arm/v7,linux/ppc64le \
	-t $DOCKER_USERID/$DOCKER_REPO:$TAG \
    --push \
    .
DOCKER_REPO2="${DOCKER_REPO}_ubuntu"
TAG2="ubuntu_${TAG}"
docker buildx build \
     --progress plain \
    --platform=linux/amd64,linux/386,linux/arm64,linux/arm/v7,linux/ppc64le \
	-t $DOCKER_USERID/$DOCKER_REPO:$TAG2 \
    --push \
    .

