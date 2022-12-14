# ------------------------------------------------------------------------------
# Pull base image
FROM fullaxx/ubuntu-desktop
MAINTAINER Brett Kuskie <fullaxx@gmail.com>

# ------------------------------------------------------------------------------
# Set environment variables
ENV DEBIAN_FRONTEND noninteractive
ENV LANG C
ENV TZ Etc/Zulu
ENV CHROMEURL "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"
ENV CHROMEDEB "/tmp/chrome.deb"
ENV QLIBCVERS "2.4.8"
ENV QLIBCURL "https://github.com/wolkykim/qlibc/archive/refs/tags/v${QLIBCVERS}.tar.gz"

# ------------------------------------------------------------------------------
# Install tools from ubuntu repo
RUN apt-get update && apt-get install -y --no-install-recommends \
apcalc apt-transport-https astyle \
bash-completion bluefish bridge-utils build-essential \
ca-certificates cgdb chaosreader cmake colordiff colortail cscope curl curlftpfs \
ddd diffstat dos2unix doxygen dtach eterm evince file firefox \
galculator gdb geany gedit gftp gimp git gkrellm gnupg2 \
hping3 htop hexcompare hexcurse hexdiff hexedit hexer \
iftop inetutils-traceroute iperf iproute2 iputils-ping kmod less lft lftp \
libcurl4-openssl-dev libczmq-dev libevent-dev libgcrypt20-dev \
libhiredis-dev libmicrohttpd-dev libnet1-dev libnet1-doc libpcap-dev \
libsqlite3-dev libssl-dev libxml2-dev libzmq3-dev \
libreoffice lsof man mc mosh most mtr-tiny \
nano ndiff nedit netcat net-tools nload nmap nmon \
openssh-client p0f p7zip-rar patch parallel psmisc rsync \
screen software-properties-common sqlite3 sshfs strace subversion sudo \
tcpdump tcptraceroute telnet terminator terminology tmux traceroute tree tzdata \
uftrace universal-ctags unzip valgrind vim vim-gtk3 wget wireshark \
xfe xterm yaru-theme-icon zip && \
apt-get clean && rm -rf /var/lib/apt/lists/* /var/tmp/* /tmp/*

# ------------------------------------------------------------------------------
# Install Chrome
RUN wget ${CHROMEURL} -O ${CHROMEDEB} && \
dpkg -i ${CHROMEDEB} || (set -e; apt-get update; apt-get install -f -y) && \
rm ${CHROMEDEB}

# ------------------------------------------------------------------------------
# Install VSCode
RUN wget -q https://packages.microsoft.com/keys/microsoft.asc -O- \
| apt-key --keyring /etc/apt/trusted.gpg.d/microsoft.gpg add - && \
echo "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" \
>/etc/apt/sources.list.d/vscode.list && \
apt-get update && apt-get install -y code libasound2 libgbm1 && \
apt-get clean && rm -rf /var/lib/apt/lists/* /var/tmp/* /tmp/*

# ------------------------------------------------------------------------------
# Install Eclipse
RUN ECLPKG="CPP" /app/scripts/install_eclipse.sh

# ------------------------------------------------------------------------------
# Install python modules and clean up
RUN apt-get update && \
    apt-get install -y --no-install-recommends build-essential gdb python3-pip tmux && \
    python3 -m pip install gdbfrontend matplotlib pandas pygments && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /var/tmp/* /tmp/*

# ------------------------------------------------------------------------------
# Install qlibc
RUN cd /tmp && \
    curl -L ${QLIBCURL} -o qlibc-${QLIBCVERS}.tar.gz && \
    tar xf qlibc-${QLIBCVERS}.tar.gz && cd qlibc-${QLIBCVERS} && \
    ./configure --prefix=/usr --libdir=/usr/lib64 && make && make install && \
    cd src && doxygen doxygen.conf && mkdir /usr/share/doc/qlibc-${QLIBCVERS} && \
    cd /tmp && cp -r qlibc-${QLIBCVERS}/doc/html /usr/share/doc/qlibc-${QLIBCVERS}/ && \
    rm -rf qlibc-${QLIBCVERS} qlibc-${QLIBCVERS}.tar.gz

# ------------------------------------------------------------------------------
# Install scripts and configuration files
COPY conf/menu.xml /usr/share/ubuntu-desktop/openbox/

# ------------------------------------------------------------------------------
# Adjust autostart
RUN echo "\nhsetroot -center /usr/share/backgrounds/hardy_wallpaper_uhd.png" >>/usr/share/ubuntu-desktop/openbox/autostart
RUN echo "\n# Set Keyboard Rate\nxset r rate 195 35" >>/usr/share/ubuntu-desktop/openbox/autostart

# ------------------------------------------------------------------------------
# Adjust bash prompt
COPY conf/dot_bashrc /usr/share/ubuntu-desktop/
RUN cat /usr/share/ubuntu-desktop/dot_bashrc >>/root/.bashrc

# ------------------------------------------------------------------------------
# Add configuration files for bluefish, geany, terminology
ADD personalization.tar /root/

# ------------------------------------------------------------------------------
# Expose ports
EXPOSE 5901

# ------------------------------------------------------------------------------
# Define default command
CMD ["/app/app.sh"]
