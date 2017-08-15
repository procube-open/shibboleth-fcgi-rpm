#!/bin/bash
mkdir -p ./rpmbuild/{BUILD/x86_64,RPMS,SOURCES,SPECS,SRPMS}

rpmbuild -bb rpmbuild/SPECS/shibboleth.spec -with fastcgi
yumdownloader --destdir rpmbuild/RPMS/x86_64 libcurl-openssl liblog4shib1 libsaml8 libsaml9 libxml-security-c17 \
     libxmltooling6 libxmltooling7 opensaml-schemas xmltooling-schemas supervisor fcgi
