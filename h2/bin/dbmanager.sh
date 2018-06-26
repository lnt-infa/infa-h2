#!/bin/sh
#---------------------------------------------------------------------------
#
# Usage:
# infaservice.sh [ startup | shutdown ]
#
#---------------------------------------------------------------------------

(
# Check the syntax
#
if [ "$1" = "startup" ]; then
  ACTION=start
elif [ "$1" = "shutdown" ]; then
  ACTION=stop
elif [ "$1" = "updateMRS" ]; then
  ACTION=updateMRSDB
else
  echo "Usage: dbmanager.sh [ startup | shutdown ]"
  exit 1
fi

# Set current directory to location of script
# Substitute symbolic link if any
if [ -z "${INFA_HOME}" ]; then
  CMD_FILE="$0"

  if [ -h "${CMD_FILE}" ]; then
    LS=`ls -ld "${CMD_FILE}"`
    LINK=`expr "${LS}" : '.*-> \(.*\)$'`
    if expr "${LINK}" : '.*/.*' > /dev/null; then
      CMD_FILE="${LINK}"
    else
      CMD_FILE=`dirname "${CMD_FILE}"`/"${LINK}"
    fi
  fi

  CMD_FILE_DIR=`dirname "${CMD_FILE}"`
  cd "${CMD_FILE_DIR}"
  CMD_FILE_DIR=`pwd`
  if [ -d ${CMD_FILE_DIR}/../.. ]; then
    cd ${CMD_FILE_DIR}/../..
    INFA_HOME=`pwd`
  fi
fi
CMD_FILE_DIR=${INFA_HOME}
cd "${CMD_FILE_DIR}"

#

#export INFA_HOME
#JAVA_HOME=${INFA_HOME}/java

export INFA_HOME=/opt
JAVA_HOME=/usr/java/default

#PMBUILD_PLATFORM=`head -1 ${INFA_HOME}/server/bin/pmplatform.env`
#export PMBUILD_PLATFORM
#case `uname` in
#    AIX)
#          JAVA_HOME=${INFA_JDK_HOME}
#      ;;
#    HP-UX)
#          JAVA_HOME=${INFA_JDK_HOME}
#      ;;
#esac

export JAVA_HOME
export _RUNJAVA="${JAVA_HOME}"/bin/java
#

# Add on extra jar files to CLASSPATH
CLASSPATH="${INFA_HOME}"/h2/bin/h2-1.3.169.jar;

INFA_H2_JAVA_OPTS="-Xmx512m ${INFA_H2_JAVA_OPTS} -XX:MaxPermSize=128m"
export INFA_H2_JAVA_OPTS

# Add -d64 option in case of HP-UX IPF
if [ `uname` = "HP-UX" ]; then
  if [ `uname -m` = "ia64" ]; then
    INFA_H2_JAVA_OPTS="${INFA_H2_JAVA_OPTS} -d64"
    export INFA_H2_JAVA_OPTS
  fi
fi
# Set up the 64 bit options and HeapDumpOnOutOfMemoryError flag for the Solaris x86 (amd64) platform
if [ `uname` = "SunOS" ]; then
  INFA_H2_JAVA_OPTS="${INFA_H2_JAVA_OPTS} -XX:+HeapDumpOnOutOfMemoryError"
  if [ `uname -m` = "i86pc" ]; then
    INFA_H2_JAVA_OPTS="${INFA_H2_JAVA_OPTS} -d64"
    export INFA_H2_JAVA_OPTS
  fi
fi

# Enable HeapDumpOnOutOfMemoryError flag for Linux platform
if [ `uname` = "Linux" ]; then
  INFA_H2_JAVA_OPTS="${INFA_H2_JAVA_OPTS} -XX:+HeapDumpOnOutOfMemoryError"
  export INFA_H2_JAVA_OPTS
fi

# Enable HeapDumpOnOutOfMemoryError flag for HP-UX platform
if [ `uname` = "HP-UX" ]; then
  INFA_H2_JAVA_OPTS="${INFA_H2_JAVA_OPTS} -XX:+HeapDumpOnOutOfMemoryError"
  export INFA_H2_JAVA_OPTS
fi

## Add -d64 for AIX.64 and Linux.IA.64
#if [ ${PMBUILD_PLATFORM} = "linux_ipf64" ]; then
#  INFA_H2_JAVA_OPTS="${INFA_H2_JAVA_OPTS} -d64"
#  export INFA_H2_JAVA_OPTS
#fi
#
#if [ ${PMBUILD_PLATFORM} = "linux64" ]; then
#  INFA_H2_JAVA_OPTS="${INFA_H2_JAVA_OPTS} -d64"
#  export INFA_H2_JAVA_OPTS
#fi
#
#if [ ${PMBUILD_PLATFORM} = "aix64" ]; then
#  INFA_H2_JAVA_OPTS="${INFA_H2_JAVA_OPTS} -Xdump:java:events=uncaught,filter=*OutOfMemoryError* -d64"
#  export INFA_H2_JAVA_OPTS
#fi

if [ -d /export ]; then
  USERDIR=/export/h2
else
  USERDIR=${INFA_HOME}/h2/bin
fi


# Execute the command
#
if [ "${ACTION}" = "start" ]; then
  echo "Starting H2 DB server"
  echo "Using INFA_HOME as CURRENT_DIR:     ${INFA_HOME}"
  { "${_RUNJAVA}" \
      -ea \
      -Duser.dir=${USERDIR} \
      -classpath "${CLASSPATH}" \
      ${INFA_H2_JAVA_OPTS} \
      org.h2.tools.Server -tcp -tcpAllowOthers -tcpPort 9092 -pg -pgDaemon -pgAllowOthers -pgPort 5435 & } 2> /dev/null &
  TESTCLASSPATH="${INFA_HOME}"/h2/bin/com.informatica.products.assembly-h2.jar:"${INFA_HOME}"/h2/bin/h2-1.3.169.jar
  "${_RUNJAVA}" -classpath "${TESTCLASSPATH}" com.informatica.h2check.H2ServerTest 9092
  INFA_DB_EX=$?
  if [ "${INFA_DB_EX}" = "1" ]; then
    echo "H2 Database Server did not start properly. Please check if the port allocated to the server is not being used by another process"
    exit ${INFA_DB_EX}
  fi
elif [ "${ACTION}" = "stop" ]; then
  { "${_RUNJAVA}" \
      -Duser.dir="${INFA_HOME}"/h2/bin \
      -classpath "${CLASSPATH}" \
      org.h2.tools.Server -tcpShutdown tcp://localhost:9092
      >>  "${INFA_HOME}"/h2/h2-shutdown.out 2>&1 &}
   echo "Stopping H2 DB Server"
elif [ "${ACTION}" = "updateMRSDB" ]; then
  { "${_RUNJAVA}" -classpath "${CLASSPATH}" org.h2.tools.RunScript -url "$2" -user $3 -password $4 -script "${INFA_HOME}"/h2/bin/update.sql &}
fi
)
