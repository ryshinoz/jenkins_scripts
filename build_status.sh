#!/bin/bash

JENKINS_URL=""
API_TOKEN=""
USER=""
USER_TOKEN=""

BUILD_STATUS_SUCCESS="SUCCESS"
BUILD_STATUS_FAILURE="FAILURE"
BUILD_STATUS_UNSTABLE="UNSTABLE"

if [ $# -ne 2 ]; then
   echo "Usage: ./build_status.sh <job_name> <build_id>"
   exit 1
fi

JOB_NAME=$1
BUILD_ID=$2
BEFORE_BUILD_ID=1

if [ $BUILD_ID -ne 1 ]; then
   BEFORE_BUILD_ID=`expr ${BUILD_ID} - 1`
fi

# API TOKENなくてもいける、buildじゃないので
function getResult() {
    BUILD_ID=$1
    RESULT=`/usr/bin/wget -q --auth-no-challenge --http-user=${USER} --http-password=${USER_TOKEN} ${JENKINS_URL}/job/${JOB_NAME}/${BUILD_ID}/api/json?token=${API_TOKEN} -O - | /usr/local/bin/jq '.result'`
    echo ${RESULT//\"/}
}

BUILD_STATUS=`getResult ${BUILD_ID}`

if [ $BUILD_ID -eq 1 ]; then
    if [ "${BUILD_STATUS}" = "${BUILD_STATUS_FAILURE}" ]; then
        echo "Failure"
        exit 0
    fi
    if [ "${BUILD_STATUS}" = "${BUILD_STATUS_UNSTABLE}" ]; then
        echo "Unstable"
        exit 0
    fi
    if [ "${BUILD_STATUS}" = "${BUILD_STATUS_SUCCESS}" ]; then
        echo "Success"
        exit 0
    fi
    echo "Unknown"
    exit 0
fi

BEFORE_BUILD_STATUS=`getResult ${BEFORE_BUILD_ID}`

if [ "${BUILD_STATUS}" = "${BUILD_STATUS_FAILURE}" ]; then
   if [ "${BEFORE_BUILD_STATUS}" = "${BUILD_STATUS_FAILURE}" ]; then
      echo "Still Failing"
      exit 0
   fi
   echo "Failure"
   exit 0
fi

if [ "${BUILD_STATUS}" = "${BUILD_STATUS_UNSTABLE}" ]; then
  # ここは面倒くさいので省略
  echo "Unstable"
  exit 0
fi

if [ "${BUILD_STATUS}" = "${BUILD_STATUS_SUCCESS}" ]; then
   if [ "${BEFORE_BUILD_STATUS}" = "${BUILD_STATUS_FAILURE}" ]; then
      echo "Fixed"
      exit 0
   fi
   echo "Success"
   exit 0
fi

# Not Build Abortedなどは省略
echo "Unknown"
exit 0
