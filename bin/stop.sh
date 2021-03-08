#!/bin/bash

# 项目名称
# shellcheck disable=SC2154
APPLICATION="${project.artifactId}"

# 项目启动jar包名称
APPLICATION_JAR="${project.build.finalName}.jar"

# 通过项目名称查找到PID，然后kill -9 pid
# shellcheck disable=SC2009
PID=$(ps -ef | grep "${APPLICATION_JAR}" | grep -v grep | awk '{ print $2 }')
if [[ -z "$PID" ]]
then
    echo "${APPLICATION} is already stopped!"
else
    echo kill "${PID}"
    kill -9 "${PID}"
    echo "${APPLICATION} stopped successfully!"
fi