# syntax=docker/dockerfile:1

# As of `1.4.2`, we cannot copy the statically linked binary out of it.
# FROM docker.io/duckdb/duckdb:1.4.2

FROM golang:1-alpine AS gtfsclean

WORKDIR /app

# https://docs.docker.com/engine/reference/builder/#automatic-platform-args-in-the-global-scope
ARG TARGETOS
ARG TARGETARCH
ARG TARGETVARIANT

RUN apk add --no-cache git file

# https://github.com/public-transport/gtfsclean
# kept up-to-date by Renovate Bot
ARG GTFSCLEAN_GIT_REF=8a1a1ee8d37e57afb238302691574b6bae3f681b
RUN git clone -q --depth 1 --revision=${GTFSCLEAN_GIT_REF} https://github.com/public-transport/gtfsclean.git .

# golang:1-alpine sets $GOPATH to /go
RUN --mount=type=cache,id=go-cache,target=/go \
	--mount=type=cache,id=go-build-cache,target=/root/.go-build \
	set -eux -o pipefail; \
	[[ "$TARGETARCH" = 'arm64' && -n "$TARGETVARIANT" ]] && export GOARM="$TARGETVARIANT"; \
	env GOOS="$TARGETOS" GOARCH="$TARGETARCH" go build \
	&& ls -lh gtfsclean \
	&& file gtfsclean \
	&& ./gtfsclean --help 2>/dev/null

# todo: pin alpine version?
FROM node:24-bookworm-slim

LABEL org.opencontainers.image.title="duckdb-gtfs-importer"
LABEL org.opencontainers.image.description="Imports GTFS data into a DuckDB database using gtfs-via-duckdb."
LABEL org.opencontainers.image.authors="Verkehrsverbund Berlin Brandenburg <info@vbb.de>, Jannis R <mail@jannisr.de>"
LABEL org.opencontainers.image.documentation="https://github.com/OpenDataVBB/duckdb-gtfs-importer"

WORKDIR /opt/duckdb-gtfs-importer

# install curl & unzip (curl-mirror dependencies)
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
	--mount=type=cache,target=/var/lib/apt,sharing=locked \
	apt update && \
	apt install -y \
		curl \
		unzip

# install curl-mirror
# > Alas, there is no way to tell Node.js to interpret a file with an arbitrary extension as an ESM module. That’s why we have to use the extension .mjs. Workarounds are possible but complicated, as we’ll see later.
# https://exploringjs.com/nodejs-shell-scripting/ch_creating-shell-scripts.html#node.js-esm-modules-as-standalone-shell-scripts-on-unix
# > A script such as homedir.mjs does not need to be executable on Unix because npm installs it via an executable symbolic link […].
# https://exploringjs.com/nodejs-shell-scripting/ch_creating-shell-scripts.html#how-npm-installs-shell-scripts
ADD \
	--checksum=sha256:59bb1efdeef33ea380f1035fae0c3810a3063de2f400d0542695ab1bc8b9f95d \
	https://gist.github.com/derhuerst/745cf09fe5f3ea2569948dd215bbfe1a/raw/cefaf64e2dd5bfde30de12017c4823cdc89ac64c/mirror.mjs \
	/opt/curl-mirror.mjs
RUN \
	ln -s /opt/curl-mirror.mjs /usr/local/bin/curl-mirror && \
	chmod +x /usr/local/bin/curl-mirror

# install gtfsclean
COPY --from=gtfsclean /app/gtfsclean /usr/local/bin/gtfsclean
# smoke test
RUN gtfsclean --help >/dev/null

# install DuckDB
RUN \
	curl 'https://install.duckdb.org' -fsSL | sh && \
	mv /root/.duckdb/cli/latest/duckdb /usr/local/bin/duckdb && \
	duckdb --version
# smoke test
RUN duckdb --version

ADD package.json ./
RUN --mount=type=cache,target=/tmp/node-compile-cache \
	--mount=type=cache,target=/root/.npm \
	npm install --omit dev && npm cache clean --force

ADD . .

WORKDIR /var/gtfs

# todo
