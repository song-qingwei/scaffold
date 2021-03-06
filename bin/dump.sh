#!/usr/bin/env bash

# 项目名称
# shellcheck disable=SC2154
SERVER_NAME="${project.artifactId}"

# 进入bin目录
cd "$(dirname "$0")" || exit

# 返回到上一级项目根目录路径
cd .. || exit

# `pwd` 执行系统命令并获得结果
DEPLOY_DIR=$(pwd)

# 外部配置文件绝对目录,如果是目录需要/结尾，也可以直接指定文件
# 如果指定的是目录,spring则会读取目录中的所有配置文件
CONF_DIR=${DEPLOY_DIR}/config

PID_LIST="$(ps -ef | grep java | grep "${CONF_DIR}" | awk '{print $2}')"
if [ -z "${PID_LIST}" ]; then
  echo "ERROR: The ${SERVER_NAME} does not started!"
  exit 1
fi

LOGS_DIR=${DEPLOY_DIR}/logs
if [ ! -d "${LOGS_DIR}" ]; then
    mkdir "${LOGS_DIR}"
fi

DUMP_DIR=${LOGS_DIR}/dump
if [ ! -d "${DUMP_DIR}" ]; then
	mkdir "${DUMP_DIR}"
fi

DUMP_DATE=$(date +%Y%m%d%H%M%S)
DATE_DIR=${DUMP_DIR}/${DUMP_DATE}
if [ ! -d "${DATE_DIR}" ]; then
	mkdir "${DATE_DIR}"
fi

echo -e "Dumping the $SERVER_NAME ...\c"
for PID in ${PID_LIST} ; do
	jstack "${PID}" > "${DATE_DIR}/jstack-${PID}.dump" 2>&1
	echo -e ".\c"
	jinfo "${PID}" > "${DATE_DIR}/jinfo-${PID}.dump" 2>&1
	echo -e ".\c"
	jstat -gcutil "${PID}" > "${DATE_DIR}/jstat-gcutil-${PID}.dump" 2>&1
	echo -e ".\c"
	jstat -gccapacity "${PID}" > "${DATE_DIR}/jstat-gccapacity-${PID}.dump" 2>&1
	echo -e ".\c"
	jmap "${PID}" > "${DATE_DIR}/jmap-${PID}.dump" 2>&1
	echo -e ".\c"
	jmap -heap "${PID}" > "${DATE_DIR}/jmap-heap-${PID}.dump" 2>&1
	echo -e ".\c"
	jmap -histo "${PID}" > "${DATE_DIR}/jmap-histo-${PID}.dump" 2>&1
	echo -e ".\c"
	if [ -r /usr/sbin/lsof ]; then
	  /usr/sbin/lsof -p "${PID}" > "${DATE_DIR}/lsof-${PID}.dump"
	  echo -e ".\c"
	fi
done

if [ -r /bin/netstat ]; then
  /bin/netstat -an > "${DATE_DIR}/netstat.dump" 2>&1
  echo -e ".\c"
fi
if [ -r /usr/bin/iostat ]; then
  /usr/bin/iostat > "${DATE_DIR}/iostat.dump" 2>&1
  echo -e ".\c"
fi
if [ -r /usr/bin/mpstat ]; then
  /usr/bin/mpstat > "${DATE_DIR}/mpstat.dump" 2>&1
  echo -e ".\c"
fi
if [ -r /usr/bin/vmstat ]; then
  /usr/bin/vmstat > "${DATE_DIR}/vmstat.dump" 2>&1
  echo -e ".\c"
fi
if [ -r /usr/bin/free ]; then
  /usr/bin/free -t > "${DATE_DIR}/free.dump" 2>&1
  echo -e ".\c"
fi
if [ -r /usr/bin/sar ]; then
  /usr/bin/sar > "${DATE_DIR}/sar.dump" 2>&1
  echo -e ".\c"
fi
if [ -r /usr/bin/uptime ]; then
  /usr/bin/uptime > "${DATE_DIR}/uptime.dump" 2>&1
  echo -e ".\c"
fi

echo "OK!"
echo "DUMP: $DATE_DIR"