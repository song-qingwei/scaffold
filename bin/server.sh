#!/usr/bin/env bash

# 进入bin目录
cd "$(dirname "$0")" || exit

# 启动脚本
start(){
  ./start.sh
}

# 停止脚本
stop(){
  ./stop.sh
}

# 重启脚本
restart(){
  ./stop.sh
  ./start.sh
}

# 运行状态
status(){
  ./start.sh status
}

# 调试模式启动
debug(){
  ./start.sh debug
}

# 调试模式启动
jmx(){
  ./start.sh jmx "$2"
}

# dump文件
dump(){
  ./dump.sh
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
    debug
    ;;
  jmx)
    jmx "$@"
    ;;
  dump)
    dump
    ;;
  *)
    echo $"Usage: $0 {start|stop|restart|status|debug|jmx -IP|dump}"
    exit 1
esac