#!/bin/bash

# create the AWS CloudHSM client config
/opt/cloudhsm/bin/configure -a ${CLOUDHSM_ENI_IP}

# start CloudHSM client
echo "[`date`] cloudHSM client starting..."
/opt/cloudhsm/bin/cloudhsm_client /opt/cloudhsm/etc/cloudhsm_client.cfg | tee /tmp/cloudhsm_client_start.log &

# wait for CloudHSM client to be ready
while true
do
    if grep 'Updating cluster to server version' /tmp/cloudhsm_client_start.log &> /dev/null
    then
        echo "[`date`] cloudHSM client start string found"
        
        # additional wait-time before CloudHSM client is advertised as available to PKCS11 daemon
        sleep ${AWSCLIENT_START_DELAY_SECS}
        break
    fi
    sleep 0.5
done

echo -e "[`date`] cloudHSM client started successfully"