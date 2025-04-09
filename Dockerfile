FROM centos:7
MAINTAINER "Mitsuru Nakakawaji" <mitsuru@procube.jp>
RUN groupadd -g 111 builder
RUN useradd -g builder -u 111 builder
ENV HOME /home/builder
WORKDIR ${HOME}
ENV SHIBBOLETH_VERSION "3.5.0"
ARG SHIBBOLETH_SOURCE_TARBALL=shibboleth-sp-${SHIBBOLETH_VERSION}.tar.bz2
ARG SHIBBOLETH_DOWNLOAD_URL=https://shibboleth.net/downloads/service-provider/${SHIBBOLETH_VERSION}/${SHIBBOLETH_SOURCE_TARBALL}
RUN cat <<EOL > /etc/yum.repos.d/CentOS-Base.repo
[base]
name=CentOS-\$releasever - Base
baseurl=http://vault.centos.org/centos/\$releasever/os/\$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7

[updates]
name=CentOS-\$releasever - Updates
baseurl=http://vault.centos.org/centos/\$releasever/updates/\$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7

[extras]
name=CentOS-\$releasever - Extras
baseurl=http://vault.centos.org/centos/\$releasever/extras/\$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7

[centosplus]
name=CentOS-\$releasever - Plus
baseurl=http://vault.centos.org/centos/\$releasever/centosplus/\$basearch/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
EOL
RUN yum -y update \
    && yum -y install unzip wget sudo lsof openssh-clients telnet bind-utils tar tcpdump vim initscripts \
         gcc openssl-devel zlib-devel pcre-devel lua lua-devel rpmdevtools make deltarpm \
         systemd-devel chrpath doxygen unixODBC-devel httpd-devel gcc-c++ boost-devel cpio
ADD shibboleth.repo /etc/yum.repos.d
RUN yum -y install libxml-security-c-devel libxmltooling-devel libsaml-devel liblog4shib-devel \
       xmltooling-schemas opensaml-schemas memcached-devel memcached libmemcached libmemcached-devel
RUN yum -y install epel-release
RUN yum -y install fcgi-devel
RUN mkdir -p /tmp/buffer
RUN mkdir -p /tmp/rpms
RUN yumdownloader --destdir /tmp/rpms libcurl-openssl liblog4shib2 libsaml13 libsaml-devel libxml-security-c30 \
     libxmltooling11 opensaml-schemas xmltooling-schemas libxerces-c-3_3 libxmltooling-devel liblog4shib-devel \
     libxml-security-c-devel libxerces-c-devel libcurl-openssl-devel
USER builder
RUN mkdir -p ${HOME}/rpmbuild/{BUILD,RPMS,SOURCES,SPECS,SRPMS}
RUN echo "%_topdir %(echo ${HOME})/rpmbuild" > ${HOME}/.rpmmacros
RUN echo "Downloading Shibboleth source tarball..." \
    && wget -O /tmp/${SHIBBOLETH_SOURCE_TARBALL} ${SHIBBOLETH_DOWNLOAD_URL} \
    && echo "Moving source tarball to SOURCES..." \
    && mv /tmp/${SHIBBOLETH_SOURCE_TARBALL} ${HOME}/rpmbuild/SOURCES/ \
    && echo "Source preparation complete."
RUN yumdownloader --source shibboleth
RUN ls -l shibboleth*.src.rpm
RUN rpm -qpl shibboleth*.src.rpm | grep '\.spec$'
RUN rpm2cpio shibboleth*.src.rpm | cpio -iv --to-stdout *.spec > ${HOME}/rpmbuild/SPECS/shibboleth.spec \
    && rm -f shibboleth*.src.rpm
COPY --chown=builder:builder logger.patch ${HOME}/rpmbuild/SOURCES/
COPY --chown=builder:builder shibboleth.spec.patch ${HOME}/
RUN echo "Patching shibboleth.spec..." \
    && cd ${HOME}/rpmbuild/SPECS \
    && patch -p1 < ${HOME}/shibboleth.spec.patch \
    && echo "SPEC patching complete." \
    && cd ${HOME} \
    && rm ${HOME}/shibboleth.spec.patch
COPY build.sh .
CMD ["/bin/bash","./build.sh"]
