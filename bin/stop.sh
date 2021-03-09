#!/usr/bin/env bash

# 项目名称
# shellcheck disable=SC2154
SERVER_NAME="${project.artifactId}"

# 进入bin目录
cd "$(dirname "$0")" || exit

# 返回到上一级项目根目录路径
cd .. || exit

# `pwd` 执行系统命令并获得结果
DEPLOY_DIR="$(pwd)"

PID_LIST="$(ps -ef | grep java | grep "$DEPLOY_DIR" |awk '{print $2}')"

if [ -z "${PID_LIST}" ]; then
  echo "ERROR: The $SERVER_NAME does not started!"
  exit 1
fi

echo -e "Stopping the $SERVER_NAME ...\c"

for PID in ${PID_LIST}; do
  kill "${PID}" > /dev/null 2>&1
done

COUNT=0
while [ ${COUNT} -lt 1 ]; do
  echo -e ".\c"
  sleep 1
  COUNT=1
  for PID in ${PID_LIST}; do
    PID_EXIST="$(ps -f -p "${PID}" | grep java)"
    if [ -n "${PID_EXIST}" ]; then
      COUNT=0
      break
    fi
  done
done

echo "OK!"
echo "PID: ${PID_LIST}"