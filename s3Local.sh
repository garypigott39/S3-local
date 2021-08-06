#!/bin/bash

#---------------------------------------------------------------------------------------
# @file
# Work around for MINIO inside lando not working for me, this will start
# minio inside docker (with persistent storage) and then will enable me to
# connect to it from my Lando build.
#
# This isn't an ideal solution but I'm giving up with identifying the problem
# cause...
#
# That is documented in the docs folder herein.
#
# Called as:
#
#    s3Local.sh [start/stop/url/status/credentials]  -- default value: start
#
# @see https://docs.min.io/docs/minio-docker-quickstart-guide.html
#---------------------------------------------------------------------------------------

NAME=s3.local
DATA=/var/www/html/TES/s3.local/data
MINIO_ROOT_USER="admin"
MINIO_ROOT_PASSWORD="admin"

#---------------------------------------------------------------------------------------

function fatal() {
  echo
  echo "##### Oops: $*"
  echo
  exit 999
}

#---------------------------------------------------------------------------------------

function getIds() {
  ids=`docker ps -a 2> /dev/null | awk -vname=${NAME} '$NF == name {print $1}'`
  echo $ids
}

#---------------------------------------------------------------------------------------

function getStatus() {
  ids=`getIds`
  if [[ ! "$ids" ]]
  then
    echo "Not running"
  else
    echo "Running"
  fi
}

#---------------------------------------------------------------------------------------

function showCredentials() {
  echo
  echo "Status: `getStatus`"
  echo
  echo "Credentials: ${MINIO_ROOT_USER}/${MINIO_ROOT_PASSWORD}"
  echo "URL: http://${NAME}:9091"
  echo
}

#---------------------------------------------------------------------------------------

function showHelp() {
  echo
  echo "Call as:"
  echo "  s3Local.sh [start/stop/url/status/credentials/help]  -- default value: start"
  echo
}

#---------------------------------------------------------------------------------------

function showStatus() {
  echo
  echo `getStatus`
  echo
}

#---------------------------------------------------------------------------------------

function showUrl() {
  echo
  echo "http://${NAME}:9091  (`getStatus`)"
  echo
}

#---------------------------------------------------------------------------------------

function startContainers() {
  docker run \
    -d \
    -p 9090:9090 \
    -p 9091:9091 \
    --add-host ${NAME}:127.0.0.1 \
    --name ${NAME} \
    -v ${DATA}:/data \
    -e "MINIO_ROOT_USER=${MINIO_ROOT_USER}" \
    -e "MINIO_ROOT_PASSWORD=${MINIO_ROOT_PASSWORD}" \
    minio/minio server /data --console-address ":9091"
  if [[ $? -ne 0 ]]
  then
    fatal "Unable to start containers"
  fi
}

#---------------------------------------------------------------------------------------

function stopContainers() {
  status=`getStatus`
  if [[ "$status" != "Running" ]]
  then
    fatal "Containers are not running"
  else
    echo "##### Stopping containers"
    ids=`getIds`
    if [[ "$ids" ]]
    then
      docker stop ${ids}
      docker rm ${ids}
    fi
  fi
}

#---------------------------------------------------------------------------------------

# What action?
action="${1:-start}"
if [[ "$action" == "help" ]]
then
  showHelp
elif [[ "$action" == "credentials" ]]
then
  showCredentials
elif [[ "$action" == "url" ]]
then
  showUrl
elif [[ "$action" == "status" ]]
then
  showStatus
elif [[ "$action" == "stop" ]]
then
  stopContainers
elif [[ "$action" != "start" ]]
then
  fatal "Invalid action specified"
elif [[ `getStatus` == "Running" ]]
then
  showUrl
else
  startContainers
  sleep 1
  showCredentials
fi
