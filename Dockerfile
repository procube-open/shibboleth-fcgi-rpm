FROM centos:7
MAINTAINER "Mitsuru Nakakawaji" <mitsuru@procube.jp>
RUN groupadd -g 111 builder
RUN useradd -g builder -u 111 builder
ENV HOME /home/builder
WORKDIR ${HOME}
ENV SHIBBOLETH_VERSION "2.6.0-2.2"
RUN yum -y update \
    && yum -y install unzip wget sudo lsof openssh-clients telnet bind-utils tar tcpdump vim initscripts \
         gcc openssl-devel zlib-devel pcre-devel lua lua-devel rpmdevtools make deltarpm \
         systemd-devel chrpath doxygen unixODBC-devel httpd-devel xerces-c-devel gcc-c++ boost-devel
ADD shibboleth.repo /etc/yum.repos.d
RUN yum -y install libxml-security-c-devel libxmltooling-devel libsaml-devel liblog4shib-devel \
       xmltooling-schemas opensaml-schemas memcached-devel memcached libmemcached libmemcached-devel
RUN yum -y install epel-release
RUN yum -y install fcgi-devel
RUN mkdir -p /tmp/buffer
RUN mkdir -p /tmp/rpms
RUN yumdownloader --destdir /tmp/rpms libcurl-openssl liblog4shib1 libsaml8 libsaml9 libxml-security-c17 \
     libxmltooling6 libxmltooling7 opensaml-schemas xmltooling-schemas
COPY shibboleth.spec.patch /tmp/buffer/
USER builder
RUN mkdir -p ${HOME}/rpmbuild/{BUILD,RPMS,SOURCES,SPECS,SRPMS}
RUN echo "%_topdir %(echo ${HOME})/rpmbuild" > ${HOME}/.rpmmacros
RUN mkdir ${HOME}/srpms \
    && cd srpms \
    && wget http://download.opensuse.org/repositories/security:/shibboleth/CentOS_7/src/shibboleth-${SHIBBOLETH_VERSION}.src.rpm \
    && rpm -ivh shibboleth-${SHIBBOLETH_VERSION}.src.rpm
RUN cd rpmbuild/SPECS \
    && patch -p 1 shibboleth.spec < /tmp/buffer/shibboleth.spec.patch
COPY build.sh .
CMD ["/bin/bash","./build.sh"]
