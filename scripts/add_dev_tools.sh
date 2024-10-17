#!/bin/bash

set -e

apt-get update

apt-get install -y --no-install-recommends \
apcalc \
apt-transport-https \
astyle \
bash-completion \
bluefish \
bridge-utils \
build-essential \
ca-certificates \
cgdb \
chaosreader \
cmake \
colordiff \
colortail \
cscope \
curl \
curlftpfs \
ddd \
diffstat \
dos2unix \
doxygen \
dtach \
eterm \
evince \
file \
firefox \
galculator \
gdb \
geany \
gedit \
gftp \
ghex \
gimp \
git \
gitk \
gkrellm \
gnupg2 \
hping3 \
htop \
hexcompare \
hexcurse \
hexdiff \
hexedit \
hexer \
iftop \
inetutils-traceroute \
iperf \
iproute2 \
iputils-ping \
jq \
kitty \
kmod \
lbzip2 \
less \
lft \
lftp \
lrzip \
libcurl4-openssl-dev \
libczmq-dev \
libevent-dev \
libgcrypt20-dev \
libhiredis-dev \
libmicrohttpd-dev \
libnet1-dev \
libnet1-doc \
libpcap-dev \
libsqlite3-dev \
libssl-dev \
libxml2-dev \
libzmq3-dev \
libreoffice \
lsof \
man \
mc \
mosh \
most \
mtr-tiny \
nano \
nbd-client \
ncdu \
ndiff \
nedit \
netcat \
net-tools \
nfdump \
ngrep \
nload \
nmap \
nmon \
ntopng \
nnn \
openssh-client \
p0f \
p7zip-rar \
patch \
parallel \
pbzip2 \
pigz \
pixz \
plzip \
psmisc \
pv \
rsync \
run-one \
sakura \
screen \
silversearcher-ag \
software-properties-common \
sqlite3 \
sshfs \
strace \
subversion \
sudo \
taskwarrior \
tcpdump \
tcpflow \
tcpstat \
tcptraceroute \
telnet \
terminator \
terminology \
thonny \
tmux \
traceroute \
tree \
tshark \
tzdata \
uftrace \
universal-ctags \
unzip \
valgrind \
vim \
vim-gtk3 \
wget \
wireshark \
xfe \
xterm \
xxhash \
yaru-theme-icon \
zip \
zlib1g-dev

ln -s /usr/bin/libreoffice /usr/bin/LO

apt-get clean

rm -rf /var/lib/apt/lists/* /var/tmp/* /tmp/*
