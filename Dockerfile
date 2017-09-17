FROM centos:7
MAINTAINER "Mitsuru Nakakawaji" <mitsuru@procube.jp>
ENV NGINX_VERSION "1.12.1-1"
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
COPY shibboleth.spec.patch /tmp/buffer/
RUN groupadd -g 111 builder
RUN useradd -g builder -u 111 builder
ENV HOME /home/builder
WORKDIR ${HOME}
USER builder
RUN mkdir ${HOME}/srpms \
    && cd srpms \
    && wget http://download.opensuse.org/repositories/security:/shibboleth/CentOS_CentOS-6/src/shibboleth-2.6.0-2.2.src.rpm \
    && rpm -ivh shibboleth-2.6.0-2.1.src.rpm
RUN cd rpmbuild/SPECS \
    && patch -p 1 shibboleth.spec < /tmp/buffer/shibboleth.spec.patch
COPY build.sh .
CMD ["/bin/bash","./build.sh"]
