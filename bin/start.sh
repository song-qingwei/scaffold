#!/usr/bin/env bash

# 项目名称
# shellcheck disable=SC2154
SERVER_NAME="${project.artifactId}"

# jar名称
JAR_NAME="${project.build.finalName}.jar"

# 进入bin目录
cd "$(dirname "$0")" || exit

# 返回到上一级项目根目录路径
cd .. || exit

# `pwd` 执行系统命令并获得结果
DEPLOY_DIR=$(pwd)

# 外部配置文件绝对目录,如果是目录需要/结尾，也可以直接指定文件
# 如果指定的是目录,spring则会读取目录中的所有配置文件
CONF_DIR=$DEPLOY_DIR/config

# 获取应用的端口号
SERVER_PORT=$(sed -nr '/port: [0-9]+/ s/.*port: +([0-9]+).*/\1/p' config/application.yml)

PID=$(ps -ef | grep java | grep "$CONF_DIR" |awk '{print $2}')

if [ "$1" == "status" ]; then
  if [ -n "$PID" ]; then
    echo "The $SERVER_NAME is running...!"
    echo "PID: $PID"
    exit 0
  else
    echo "The $SERVER_NAME is stopped!"
    exit 0
  fi
fi

# 检测服务是否已启动
if [ -n "$PID" ]; then
  echo "ERROR: The $SERVER_NAME already started!"
  echo "PID: $PID"
  exit 1
fi

# 检测端口是否被占用
if [ -n "$SERVER_PORT" ]; then
  SERVER_PORT_COUNT=$(netstat -tln | grep -c "$SERVER_PORT")
  if [ "$SERVER_PORT_COUNT" -gt 0 ]; then
    echo "ERROR: The $SERVER_NAME port $SERVER_PORT already used!"
    exit 1
  fi
fi

# 项目日志输出绝对路径
LOGS_DIR=$DEPLOY_DIR/logs

# 如果logs文件夹不存在,则创建文件夹
if [ ! -d "$LOGS_DIR" ]; then
  mkdir "$LOGS_DIR"
fi

STDOUT_FILE=$LOGS_DIR/catalina.log

# JVM Configuration模式
JAVA_OPTS=" -Djava.awt.headless=true -Djava.net.preferIPv4Stack=true "

# 检测是否开启远程调试功能
JAVA_DEBUG_OPTS=""
if [ "$1" == "debug" ]; then
  echo "INFO: The $SERVER_NAME DEBUG mode is started, port is 8000!"
  JAVA_DEBUG_OPTS=" -Xdebug -Xnoagent -Djava.compiler=NONE -Xrunjdwp:transport=dt_socket,address=8000,server=y,suspend=n "
fi

# 检测是否开启JMX功能,使jvisualvm能够连接JVM
JAVA_JMX_OPTS=""
if [ "$1" == "jmx" ]; then
  if [ -z "$2" ]; then
    echo "ERROR: Please enter this $SERVER_NAME IP!"
    exit 0
  fi
  echo "INFO: The $SERVER_NAME JMX mode is started, IP is $2, port is 1099!"
  JAVA_JMX_OPTS=" -Djava.rmi.server.hostname=$2 -Dcom.sun.management.jmxremote.port=1099 -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.authenticate=false "
fi

# 内存、GC配置参数
JAVA_MEM_OPTS=""
BITS=$(java -version 2>&1 | grep -i 64-bit)
if [ -n "$BITS" ]; then
  JAVA_MEM_OPTS=" -server -Xmx512m -Xms512m -Xmn256m -XX:PermSize=128m -Xss256k -XX:+DisableExplicitGC -XX:+UseConcMarkSweepGC -XX:+CMSParallelRemarkEnabled -XX:+UseCMSCompactAtFullCollection -XX:LargePageSizeInBytes=128m -XX:+UseFastAccessorMethods -XX:+UseCMSInitiatingOccupancyOnly -XX:CMSInitiatingOccupancyFraction=70 "
else
  JAVA_MEM_OPTS=" -server -Xms512m -Xmx512m -XX:PermSize=128m -XX:SurvivorRatio=2 -XX:+UseParallelGC "
fi

# 加载外部log4j2文件的配置
LOG_IMPL_FILE=log4j2.xml
LOGGING_CONFIG=""
if [ -f "$CONF_DIR/$LOG_IMPL_FILE" ]; then
  LOGGING_CONFIG="-Dlogging.config=$CONF_DIR/$LOG_IMPL_FILE"
fi
CONFIG_FILES=" -Dlogging.file.path=$LOGS_DIR $LOGGING_CONFIG -Dspring.config.location=$CONF_DIR/ "
echo -e "Starting the $SERVER_NAME ..."
# shellcheck disable=SC2086
nohup java $JAVA_OPTS $JAVA_MEM_OPTS $JAVA_DEBUG_OPTS $JAVA_JMX_OPTS $CONFIG_FILES -jar $DEPLOY_DIR/lib/$JAR_NAME > $STDOUT_FILE 2>&1 &

CHECK_COUNT=0
COUNT=0
while [ $COUNT -lt 1 ]; do
  echo -e ".\c"
  sleep 1
  ((CHECK_COUNT++)) || true
  if [ "$CHECK_COUNT" -gt 20 ];then
    echo -e "\nERROR: The $SERVER_NAME start failed, Please open $STDOUT_FILE to view the error log"
    exit 1
  fi
  if [ -n "$SERVER_PORT" ]; then
    COUNT=$(netstat -an | grep -c "$SERVER_PORT")
  else
    COUNT=$(ps -ef | grep java | grep "$DEPLOY_DIR" | awk '{print $2}' | wc -l)
  fi
  if [ "$COUNT" -gt 0 ]; then
    break
  fi
done

echo "OK!"
PID="$(ps -ef | grep java | grep "$DEPLOY_DIR" | awk '{print $2}')"
echo "PID: $PID"
echo "STDOUT: $STDOUT_FILE"
