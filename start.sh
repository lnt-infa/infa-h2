#!/bin/sh
DOMAIN=node.lyon.infa.co
DNS_HOST=172.17.0.2
HOSTNAME="h2"
DOCKER_IMAGE=lntinfa/infa-h2
DATA_DIR=/home/docker-data/data


mkdir -p ${DATA_DIR}/${HOSTNAME}

# start the master
docker run -d --name ${HOSTNAME} -h ${HOSTNAME}.${DOMAIN} --dns=${DNS_HOST} --dns-search=${DOMAIN} -e UPDATE_DNS=true -v ${DATA_DIR}/${HOSTNAME}:/export ${DOCKER_IMAGE}
