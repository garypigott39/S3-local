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
#    s3Local.sh [start/stop/url/status/credentials]  -- default value: help
#
# @see https://docs.min.io/docs/minio-docker-quickstart-guide.html
#
# Note, add entry to /etc/hosts
#
# @TODO. stop = just stop, kill, restart
# @TODO. alias dps="docker ps -q | xargs docker inspect --format '{{ .Id }} - {{ .Name }} - {{ .NetworkSettings.IPAddress }}'"
# @see https://github.com/moby/moby/issues/8786
#---------------------------------------------------------------------------------------

NAME=s3.local
BASE=/var/www/html/TES/s3.local
DATA=${BASE}/data
#CERTS=${BASE}  # creates a "certs" folder if it doesnt already exist
API_PORT=9090
CONSOLE_PORT=9091

MINIO_ROOT_USER="admin"
MINIO_ROOT_PASSWORD="minio.admin"

#---------------------------------------------------------------------------------------

function fatal() {
  echo
  echo "##### Oops: $*"
  echo
  exit 999
}

#---------------------------------------------------------------------------------------

function getIds() {
  ids=`docker ps -a -f name=${NAME} | grep ${NAME} 2> /dev/null | awk '{print $1}'`
  echo $ids
}

#---------------------------------------------------------------------------------------

function getStatus() {
  status=`docker ps -a -f name=${NAME} | grep ${NAME} 2> /dev/null | awk '{print $7}'`
  if [[ ! "$status" ]]
  then
    echo "Not running/No container"
  elif [[ "$status" == "Up" ]]
  then
    echo "Running"
  elif [[ "$status" == "Exited" ]]
  then
    echo "Stopped"
  else
    echo "Unknown"
  fi
}

#---------------------------------------------------------------------------------------

function showCredentials() {
  echo
  echo "Status: `getStatus`"
  echo
  echo "Credentials: ${MINIO_ROOT_USER}/${MINIO_ROOT_PASSWORD}"
  #
  showUrl
}

#---------------------------------------------------------------------------------------

function showHelp() {
  echo
  echo "Start MINIO standalone instance in Docker. Called as:"
  echo
  echo "  s3Local.sh [start/stop/url/status/credentials/help]  -- default value: help"
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
  echo "API - http://${NAME}:${API_PORT}"
  echo "Console - http://${NAME}:${CONSOLE_PORT}  (`getStatus`)"
  echo
}

#---------------------------------------------------------------------------------------

function restartContainers() {
  ids=`getIds`
  if [[ "$ids" ]]
  then
    echo "##### Restarting containers"
    docker container restart ${ids}
  fi
}

#---------------------------------------------------------------------------------------

function startContainers() {
#    --add-host ${NAME}:127.0.0.1 \
#    -v ${CERTS}:/root/.minio \
  docker container run \
    -d \
    -p ${API_PORT}:${API_PORT} \
    -p ${CONSOLE_PORT}:${CONSOLE_PORT} \
    --name ${NAME} \
    -v ${DATA}:/data \
    -e "MINIO_ROOT_USER=${MINIO_ROOT_USER}" \
    -e "MINIO_ROOT_PASSWORD=${MINIO_ROOT_PASSWORD}" \
    minio/minio server /data --console-address ":${CONSOLE_PORT}"
  if [[ $? -ne 0 ]]
  then
    fatal "Unable to start containers"
  fi
}

#---------------------------------------------------------------------------------------

function stopContainers() {
  ids=`getIds`
  if [[ "$ids" ]]
  then
    echo "##### Stopping containers"
    docker container stop ${ids}
    docker container rm ${ids}
  fi
}

#---------------------------------------------------------------------------------------

# What action?
action="${1:-help}"
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
elif [[ `getStatus` == "Stopped" ]]
then
  restartContainers
  sleep 2
  showCredentials
else
  # Always stop/remove any container first
  stopContainers > /dev/null 2>&1
  #
  startContainers
  sleep 2
  showCredentials
fi
