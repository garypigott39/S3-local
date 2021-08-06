#!/bin/bash

#------------------------------------------------------------------------------
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
#    s3Local.sh [start/stop/url]  -- default value: start
#
# @see https://docs.min.io/docs/minio-docker-quickstart-guide.html
#------------------------------------------------------------------------------

NAME=s3.local
DATA=/var/www/html/TES/s3.local/data
MINIO_ROOT_USER="admin"
MINIO_ROOT_PASSWORD="admin"

if [[ "$1" == "stop" ]]
then
  echo
  echo "Stopping associated containers"
  echo
  #
  ids=`docker ps -a 2> /dev/null | awk -vname=${NAME} '$NF == name {print $1}'`
  if [[ "$ids" ]]
  then
    docker stop ${ids}
    docker rm ${ids}
  fi
  exit
elif [[ "$1" == "url" ]]
then
  echo
  echo "Credentials: ${MINIO_ROOT_USER}/${MINIO_ROOT_PASSWORD}"
  echo
  echo "URL: http://${NAME}:9091"
  exit
fi

# Else... start it
clear
echo
echo "Name: ${NAME}"
echo "USER: ${MINIO_ROOT_USER}"
echo "PASSWORD: ${MINIO_ROOT_PASSWORD}"
echo
echo "URL: http://${NAME}:9091"
echo

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
