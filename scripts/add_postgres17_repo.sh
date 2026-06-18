#!/bin/bash

set -e

# Assume these are available
# apt-get install -y --no-install-recommends ca-certificates curl

install -m 0755 -d /usr/share/postgresql-common/pgdg
curl -o /usr/share/postgresql-common/pgdg/apt.postgresql.org.asc --fail \
  https://www.postgresql.org/media/keys/ACCC4CF8.asc

sh -c '. /etc/os-release && echo "deb [signed-by=/usr/share/postgresql-common/pgdg/apt.postgresql.org.asc] https://apt.postgresql.org/pub/repos/apt ${UBUNTU_CODENAME:-$VERSION_CODENAME}-pgdg main" \
  > /etc/apt/sources.list.d/pgdg.list'

apt-get update

apt-get install -y --no-install-recommends postgresql-client-17

apt-get clean
rm -rf /var/lib/apt/lists/* /var/tmp/* /tmp/*
