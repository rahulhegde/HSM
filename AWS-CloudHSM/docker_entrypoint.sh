#!/bin/bash

# Start the first process
/usr/local/bin/start_awshsmclient.sh
status=$?
if [ $status -ne 0 ]; then
  echo "Failed to start start_awshsmclient: $status"
  exit $status
fi

# Start the second process
/usr/local/bin/start_pkcs11daemon.sh "$@"
status=$?
if [ $status -ne 0 ]; then
  echo "Failed to start start_pkcs11daemon: $status"
  exit $status
fi

# Naive check runs checks once a minute to see if either of the processes exited.
# This illustrates part of the heavy lifting you need to do if you want to run
# more than one service in a container. The container exits with an error
# if it detects that either of the processes has exited.
# Otherwise it loops forever, waking up every 60 seconds
while sleep ${PROCESS_CHECK_SECS}; do
  ps aux |grep cloudhsm_client |grep -q -v grep
  PROCESS_1_STATUS=$?
  ps aux |grep pkcs11-daemon |grep -q -v grep
  PROCESS_2_STATUS=$?
  # If the greps above find anything, they exit with 0 status
  # If they are not both 0, then something is wrong
  if [ $PROCESS_1_STATUS -ne 0 -o $PROCESS_2_STATUS -ne 0 ]; then
    echo "[`date`] notation: running: 0, stopped: 1"
    echo "[`date`] one of the processes exited - cloud hsm client: $PROCESS_1_STATUS, pkcs11 daemon: $PROCESS_2_STATUS"
    exit 1
  fi
done