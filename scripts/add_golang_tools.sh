#!/bin/bash

set -e

go install github.com/go-delve/delve/cmd/dlv@v1.27.1
go install github.com/golangci/golangci-lint/v2/cmd/golangci-lint@v2.13.1
go install golang.org/x/tools/cmd/goimports@v0.49.0
go install golang.org/x/vuln/cmd/govulncheck@v1.7.0
go clean -cache
