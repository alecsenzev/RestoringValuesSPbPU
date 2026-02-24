#!/usr/bin/env bash
set -e
mkdir -p /opt/restoringvalues/run

cd /opt/restoringvalues/current/app

rm -f /opt/restoringvalues/run/*.pid || true

start_bg() {
  local name="$1"; shift
  nohup python "$@" > "/opt/restoringvalues/run/${name}.log" 2>&1 &
  echo $! > "/opt/restoringvalues/run/${name}.pid"
}

start_bg simulator Simulator/simulator.py
sleep 1
start_bg reciever Reciever/reciever.py
start_bg business Business/business.py

touch /opt/restoringvalues/run/simulator.log \
      /opt/restoringvalues/run/reciever.log \
      /opt/restoringvalues/run/business.log

# стримим логи во stdout, чтобы контейнер жил
tail -n 0 -F /opt/restoringvalues/run/simulator.log \
          /opt/restoringvalues/run/reciever.log \
          /opt/restoringvalues/run/business.log
