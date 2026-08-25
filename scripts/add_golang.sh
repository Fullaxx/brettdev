#!/bin/bash

set -e

GOVERS="1.27.0"
GOFILE="go${GOVERS}.linux-amd64.tar.gz"
GOURL="https://go.dev/dl/${GOFILE}"

GOSHA256=$(curl -fsSL "https://go.dev/dl/?mode=json&include=all" | jq -r --arg f "${GOFILE}" '.[].files[] | select(.filename==$f) | .sha256')
test -n "${GOSHA256}"

curl -fsSL -o "${GOFILE}" "${GOURL}"
echo "${GOSHA256}  ${GOFILE}" | sha256sum -c -

rm -rf /usr/local/go
tar -C /usr/local -xzf "${GOFILE}"
rm ${GOFILE}
