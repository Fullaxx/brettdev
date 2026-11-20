#!/bin/bash

set -e

#for BASEIMAGE in `grep '^FROM' Dockerfile | awk '{print $2}'`; do
#  docker pull ${BASEIMAGE}
#done

git pull

docker build -t "ghcr.io/fullaxx/brettdev:24.04" .

docker build -t "ghcr.io/fullaxx/brettdev-full:24.04" -f Dockerfile.full .
