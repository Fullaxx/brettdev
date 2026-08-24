#!/bin/bash

set -e

#GOVERS="1.27.0"
#GOURL="https://go.dev/dl/go${GOVERS}.linux-amd64.tar.gz"

DLPATH=`curl https://go.dev/dl/ | grep 'download downloadBox' | grep linux-amd64 | awk -F\" '{print $4}'`
GOURL="https://go.dev${DLPATH}"

GOFILE="go.tar.gz"

wget ${GOURL} -O ${GOFILE}
rm -rf /usr/local/go
tar -C /usr/local -xzf ${GOFILE}
rm ${GOFILE}

ln -sf /usr/local/go/bin/go /usr/bin/go
ln -sf /usr/local/go/bin/gofmt /usr/bin/gofmt
