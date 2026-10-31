#!/bin/bash

set -e

go install github.com/go-delve/delve/cmd/dlv@v1.27.1
go install github.com/golangci/golangci-lint/v2/cmd/golangci-lint@v2.14.0
go install github.com/goreleaser/nfpm/v2/cmd/nfpm@v2.48.0
go install github.com/rhysd/actionlint/cmd/actionlint@v1.7.12
go install golang.org/x/perf/cmd/benchstat@v0.0.0-20261009192801-be2c69fb417e
go install golang.org/x/tools/cmd/deadcode@v0.52.0
go install golang.org/x/tools/cmd/goimports@v0.49.0
go install golang.org/x/tools/cmd/stringer@v0.52.0
go install golang.org/x/vuln/cmd/govulncheck@v1.7.0
go clean -cache
