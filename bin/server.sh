#!/bin/bash

# 项目名称
# shellcheck disable=SC2154
SERVER_NAME="${project.artifactId}"
# jar名称
JAR_NAME="${project.build.finalName}.jar"

# 进入脚本目录
cd $(dirname "$0") || exit

# 返回到上一级项目根目录路径
cd .. || exit

# `pwd` 执行系统命令并获得结果
DEPLOY_DIR=$(pwd)

# 配置文件所在目录
CONFIG_DIR=$DEPLOY_DIR/config

# 获取应用配置的端口号
APPLICATION_FILE=application.yml
SERVER_PORT=$(sed -nr '/port: [0-9]+/ s/.*port: +([0-9]+).*/\1/p' config/$APPLICATION_FILE)

# 查询应用对应的进程ID
# shellcheck disable=SC2009
PID=$(ps -f | grep java | grep "$CONFIG_DIR" |awk '{print $2}')

# 项目日志输出绝对路径
LOG_DIR=$DEPLOY_DIR/logs

# 如果logs文件夹不存在,则创建文件夹
if [ ! -d "$LOG_DIR" ]; then
    mkdir "$LOG_DIR"
fi

# 控制台日志输出文件
STDOUT_FILE=$LOG_DIR/catalina.log

# JVM Configuration模式
JAVA_OPTS=" -Djava.awt.headless=true -Djava.net.preferIPv4Stack=true "

# 是否开启远程debug调试功能
JAVA_DEBUG_OPTS=""

# 是否开启JMX功能,使jvisualvm能够连接JVM
JAVA_JMX_OPTS=""

# 内存、GC配置参数
JAVA_MEM_OPTS=""

# 加载外部日志文件的配置
LOG_CONFIG_FILE=log4j2.xml

# 启动脚本
start(){
  check_pid
  check_port
  JAVA_VERSION=$(java -version 2>&1 | grep -i 64-bit)
  if [ -n "$JAVA_VERSION" ]; then
    JAVA_MEM_OPTS=" -server -Xmx512m -Xms512m -Xmn256m -XX:PermSize=128m -Xss256k -XX:+DisableExplicitGC -XX:+UseConcMarkSweepGC -XX:+CMSParallelRemarkEnabled -XX:+UseCMSCompactAtFullCollection -XX:LargePageSizeInBytes=128m -XX:+UseFastAccessorMethods -XX:+UseCMSInitiatingOccupancyOnly -XX:CMSInitiatingOccupancyFraction=70 "
  else
    JAVA_MEM_OPTS=" -server -Xms512m -Xmx512m -XX:PermSize=128m -XX:SurvivorRatio=2 -XX:+UseParallelGC "
  fi
  LOGGING_CONFIG=""
  if [ -f "$CONFIG_DIR/$LOG_CONFIG_FILE" ]; then
    LOGGING_CONFIG="-Dlogging.config=$CONFIG_DIR/$LOG_IMPL_FILE"
  fi
  LOGGING_PATH=" -Dlogging.path=$LOG_DIR $LOGGING_CONFIG -Dspring.config.location=$CONFIG_DIR/ "
  echo -e "Starting the $SERVER_NAME ..."
  # shellcheck disable=SC2086
  nohup java $JAVA_OPTS $JAVA_MEM_OPTS $JAVA_DEBUG_OPTS $JAVA_JMX_OPTS $LOGGING_PATH -jar $DEPLOY_DIR/lib/$JAR_NAME > $STDOUT_FILE 2>&1 &
}

# 停止脚本
stop(){
  echo ""
}

# 重启脚本
restart(){
  stop
  sleep 2
  start
}

# 运行状态
status(){
  echo ""
  if [ -n "$PID" ]; then
    echo "The $SERVER_NAME is running...!"
    echo "PID: $PID"
    exit 0
  else
    echo "The $SERVER_NAME is stopped!"
    exit 0
  fi
}

# dump文件
dump(){
  echo ""
}

# 开启远程debug模式
debug(){
  JAVA_DEBUG_OPTS=" -Xdebug -Xnoagent -Djava.compiler=NONE -Xrunjdwp:transport=dt_socket,address=8000,server=y,suspend=n "
  start
}

# 开启JMX功能,使jvisualvm能够连接JVM
jmx(){
  JAVA_JMX_OPTS=" -Djava.rmi.server.hostname=$2 -Dcom.sun.management.jmxremote.port=1099 -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.authenticate=false "
  start
}

# 检测服务是否已启动
check_pid(){
  if [ -n "$PID" ]; then
    echo "ERROR: The $SERVER_NAME already started!"
    echo "PID: $PID"
    exit 1
  fi
}

# 检测端口是否被占用
check_port(){
  if [ -n "$SERVER_PORT" ]; then
    SERVER_PORT_COUNT=$(netstat -tln | grep -c "$SERVER_PORT")
    if [ "$SERVER_PORT_COUNT" -gt 0 ]; then
      echo "ERROR: The $SERVER_NAME port $SERVER_PORT already used!"
        exit 1
    fi
  fi
}

check_result(){
  COUNT=0
  while [ $COUNT -lt 1 ]; do
    echo -e ".\c"
    sleep 1
    if [ -n "$SERVER_PORT" ]; then
      COUNT=$(netstat -an | grep -c "$SERVER_PORT")
    else
      # shellcheck disable=SC2009
      COUNT=$(ps -f | grep java | grep "$DEPLOY_DIR" | awk '{print $2}' | wc -l)
    fi
    if [ "$COUNT" -gt 0 ]; then
        break
    fi
  done
}

ok(){
  echo "OK!"
  # shellcheck disable=SC2009
  PID=$(ps -f | grep java | grep "$DEPLOY_DIR" | awk '{print $2}')
  echo "PID: $PID"
  echo "STDOUT: $STDOUT_FILE"
}

# See how we were called.
case "$1" in
  start)
    start
    ;;
  stop)
    stop
    ;;
  restart)
    restart
    ;;
  status)
    status
    ;;
  debug)
    start
    ;;
  jmx)
    start
    ;;
  *)
    echo $"Usage: $0 {start|stop|restart|status|debug|jmx IP|dump}"
    exit 1
esac