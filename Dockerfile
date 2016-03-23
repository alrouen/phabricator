FROM hachque/systemd-none


# Remove boot patching
RUN rm /etc/init.simple/00-patch

# Update images
RUN zypper --non-interactive up --force-resolution || true
RUN zypper --non-interactive up --force-resolution || true

# Install requirements
RUN zypper --non-interactive in --force-resolution git

# Install NodeJS + WebSockets module
RUN zypper --non-interactive ar http://download.opensuse.org/repositories/home:/marec2000:/nodejs/openSUSE_13.1/ nodejs
RUN zypper --gpg-auto-import-keys --non-interactive in --force-resolution nodejs-ws
RUN zypper --non-interactive rr nodejs

# Install requirements
RUN zypper --non-interactive in --force-resolution which python-Pygments nodejs ca-certificates ca-certificates-mozilla ca-certificates-cacert sudo mercurial

# The long line below is the expansion of the following shorter line.
# We track the long line explicitly so we can uninstall the packages only needed for building.
#RUN zypper --non-interactive install php5-devel php5-pear gcc autoconf make
RUN zypper --non-interactive install --force-resolution autoconf automake binutils cpp cpp48 gcc gcc48 glibc-devel libasan0 libatomic1 libcloog-isl4 libgomp1 libisl10 libitm1 libltdl7 libmpc3 libmpfr4 libpcre16-0 libpcrecpp0 libpcreposix0 libstdc++-devel libstdc++48-devel libtool libtsan0 libxml2-devel libxml2-tools linux-glibc-devel m4 make ncurses-devel pcre-devel php5-devel php5-pear php5-zlib pkg-config readline-devel tack xz-devel zlib-devel

# Now we don't need any of the build tools anymore, remove them.
#RUN zypper --non-interactive remove gcc autoconf automake
RUN zypper --non-interactive remove --force-resolution autoconf automake binutils cpp cpp48 gcc gcc48 glibc-devel libasan0 libatomic1 libcloog-isl4 libgomp1 libisl10 libitm1 libltdl7 libmpc3 libmpfr4 libpcre16-0 libpcrecpp0 libpcreposix0 libstdc++-devel libstdc++48-devel libtool libtsan0 libxml2-devel libxml2-tools linux-glibc-devel m4 ncurses-devel pcre-devel php5-devel php5-pear pkg-config readline-devel tack xz-devel zlib-devel

# Install a few extra things
RUN zypper --non-interactive install --force-resolution vim vim-data

# Force reinstall cronie
RUN zypper --non-interactive install -f cronie

# Remove cached things taht pecl left in /tmp/
RUN rm -rf /tmp/*

# Create nginx user and group
RUN echo "nginx:x:497:495:user for nginx:/var/lib/nginx:/bin/false" >> /etc/passwd
RUN echo "nginx:!:495:" >> /etc/group

# Add user
RUN echo "git:x:2000:2000:user for phabricator:/srv/phabricator:/bin/bash" >> /etc/passwd
RUN echo "wwwgrp-phabricator:!:2000:nginx" >> /etc/group

# Set up log folders for PHP
RUN mkdir -p /var/log/php
RUN chown -R git:wwwgrp-phabricator /var/log/php

# Set up the Phabricator code base
RUN mkdir /srv/phabricator
RUN chown git:wwwgrp-phabricator /srv/phabricator
USER git
WORKDIR /srv/phabricator
RUN git clone git://github.com/facebook/libphutil.git
RUN git clone git://github.com/facebook/arcanist.git
RUN git clone --progress git://github.com/facebook/phabricator.git
RUN git clone --progress git://github.com/PHPOffice/PHPExcel.git
USER root
WORKDIR /

# Expose Aphlict (notification server) on 843 and 22280
EXPOSE 843
EXPOSE 22280

# Add files
ADD 10-boot-conf /etc/init.simple/10-boot-conf
ADD 35-phd /etc/init.simple/35-phd
ADD 40-aphlict /etc/init.simple/40-aphlict
ADD 50-cronie /etc/init.simple/50-cronie

# [chmod] init scripts
RUN chmod -R 755 /etc/init.simple

# Move the default SSH to port 24
RUN echo "" >> /etc/ssh/sshd_config
RUN echo "Port 24" >> /etc/ssh/sshd_config

# Configure Phabricator SSH service
RUN mkdir /etc/phabricator-ssh
ADD sshd_config.phabricator /etc/phabricator-ssh/sshd_config.phabricator
ADD 45-phabricator-ssh /etc/init.simple/45-phabricator-ssh
ADD phabricator-ssh-hook.sh /etc/phabricator-ssh/phabricator-ssh-hook.sh
RUN chown root:root /etc/phabricator-ssh/*

# Workaround for https://gist.github.com/porjo/35ea98cb64553c0c718a
RUN chmod u+s /usr/sbin/postdrop
RUN chmod u+s /usr/sbin/postqueue

# Set /init as the default
CMD ["/init"]
