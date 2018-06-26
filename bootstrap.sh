#!/bin/sh
source /etc/consulFunctions.sh

########### SIGTERM handler ############
function _term() {
  echo "Stopping container."
  echo "SIGTERM received, shutting down h2!"
  /opt/h2/bin/dbmanager.sh shutdown 
}

########### SIGKILL handler ############
function _kill() {
   echo "SIGKILL received, shutting down h2!"
  /opt/h2/bin/dbmanager.sh shutdown 
}

# Set SIGTERM handler
trap _term SIGTERM

# Set SIGKILL handler
trap _kill SIGKILL



if [[ $1 == "-bash" ]]; then
  /bin/bash
else

  #service sshd start
  nohup /usr/sbin/sshd -D &
 
  # start h2
  /opt/h2/bin/dbmanager.sh startup 


  mkdir -p /export/h2 


  if [[ $1 == "-d" ]]; then
    while true; do sleep 1000; done
  fi
fi
