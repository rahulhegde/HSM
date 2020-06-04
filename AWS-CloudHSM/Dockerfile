########## Build the pkcs11 proxy ##########
FROM registry.access.redhat.com/ubi8/ubi-minimal:8.2-267 as builder

ARG ARCH=amd64

# package installation 
ARG PKCS11_COMMIT_ID=2032875
ARG GCC_VERSION=8.3.1-5.el8.x86_64
ARG MAKE_VERSION=4.2.1-10.el8.x86_64
ARG CMAKE_VERSION=3.11.4-7.el8.x86_64
ARG GIT_VERSION=2.18.4-2.el8_2.x86_64
ARG OPENSSL_DEVEL_VERSION=1.1.1c-15.el8.x86_64
ARG LIBSECCOMP_DEVEL_VERSION=2.4.1-1.el8.x86_64

RUN microdnf install -y \
   git-${GIT_VERSION} \
   make-${MAKE_VERSION} \
   cmake-${CMAKE_VERSION} \
   openssl-devel-${OPENSSL_DEVEL_VERSION} \
   libseccomp-devel-${LIBSECCOMP_DEVEL_VERSION} \
   gcc-${GCC_VERSION};

RUN git clone https://github.com/SUNET/pkcs11-proxy && \
   cd pkcs11-proxy && \
   git checkout ${PKCS11_COMMIT_ID} && \
   cmake . && \
   make && \
   make install;

# proxy with CloudHSM client
FROM registry.access.redhat.com/ubi8/ubi-minimal:8.2-267
ARG ARCH=amd64

# required by compat-openssl
ARG MAKE_VERSION=4.2.1-10.el8.x86_64
# required by AWS Cloud HSM client Configure
ARG PYTHON3_VERSION=3.6.8-2.module+el8.1.0+3334+5cb623d7.x86_64
# required by AWS Cloud HSM client 
ARG LIBEDIT_VERSION=3.1-23.20170329cvs.el8.x86_64
ARG SHADOW_UTILS_VERSION=4.6-8.el8.x86_64
ARG NCURSES_COMPAT_LIBS_VERSION=6.1-7.20180224.el8.x86_64
ARG AWS_CLOUDHSM_CLIENT_VERSION=3.1.0-3.el7.x86_64
ARG AWS_CLOUDHSM_PKCS11_VERSION=3.1.0-3.el7.x86_64
# required by PKCS11 daemon
ARG LIBSECCOMP_VERSION=2.4.1-1.el8.x86_64
# required for process status monitoring
ARG PROCPS_NG_VERSION=3.3.15-1.el8.x86_64

EXPOSE 2345

RUN microdnf install -y \
   make-${MAKE_VERSION} \
   python36-${PYTHON3_VERSION} \
   libedit-${LIBEDIT_VERSION} \
   libseccomp-${LIBSECCOMP_VERSION} \
   ncurses-compat-libs-${NCURSES_COMPAT_LIBS_VERSION} \
   shadow-utils-${SHADOW_UTILS_VERSION} \
   procps-ng-${PROCPS_NG_VERSION}

# install dependencies not available in ubi stream and required by AWS PKCS11 library
RUN if [ "${ARCH}" == "amd64" ]; then ARCH="x86_64"; fi \
   && rpm -ivh https://kojipkgs.fedoraproject.org/packages/compat-openssl10/1.0.2o/5.fc30/${ARCH}/compat-openssl10-1.0.2o-5.fc30.${ARCH}.rpm;

# install AWS cloudhsm client
RUN rpm -ivh https://s3.amazonaws.com/cloudhsmv2-software/CloudHsmClient/EL7/cloudhsm-client-${AWS_CLOUDHSM_CLIENT_VERSION}.rpm \
    && rpm -ivh https://s3.amazonaws.com/cloudhsmv2-software/CloudHsmClient/EL7/cloudhsm-client-pkcs11-${AWS_CLOUDHSM_PKCS11_VERSION}.rpm;

# provide soft-links
RUN ln -sf /usr/lib64/libjson-c.so.4 /usr/lib64/libjson-c.so.2;
RUN ln -sf /usr/bin/python3 /usr/bin/python;

# copy daemon from builder
COPY --from=builder /usr/local/bin/pkcs11-daemon /usr/local/bin/pkcs11-daemon

# pkcs11-daemon listen port
ENV PKCS11_DAEMON_SOCKET tcp://0.0.0.0:2345
# pkcs11 library
ENV LIBRARY_LOCATION /opt/cloudhsm/lib/libcloudhsm_pkcs11.so

ENV AWSCLIENT_START_DELAY_SECS 0
ENV PROCESS_CHECK_SECS 60

# add entrypoint scripts
ADD docker_entrypoint.sh /usr/local/bin/docker_entrypoint.sh
ADD start_awshsmclient.sh /usr/local/bin/start_awshsmclient.sh
ADD start_pkcs11daemon.sh /usr/local/bin/start_pkcs11daemon.sh

ENTRYPOINT [ "/usr/local/bin/docker_entrypoint.sh" ]