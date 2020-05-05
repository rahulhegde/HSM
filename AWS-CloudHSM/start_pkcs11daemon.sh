#!/bin/bash

# start the pkcs11 daemon
pkcs11-daemon /opt/cloudhsm/lib/libcloudhsm_pkcs11.so - &

echo -e "[`date`] pkcs11-daemon started successfully"