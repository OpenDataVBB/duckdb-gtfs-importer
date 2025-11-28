# syntax=docker/dockerfile:1

# todo: pin alpine version?
FROM node:24-bookworm-slim

LABEL org.opencontainers.image.title="duckdb-gtfs-importer"
LABEL org.opencontainers.image.description="Imports GTFS data into a DuckDB database using gtfs-via-duckdb."
LABEL org.opencontainers.image.authors="Verkehrsverbund Berlin Brandenburg <info@vbb.de>, Jannis R <mail@jannisr.de>"
LABEL org.opencontainers.image.documentation="https://github.com/OpenDataVBB/duckdb-gtfs-importer"

WORKDIR /opt/duckdb-gtfs-importer

# todo: install curl-mirror
# todo; install gtfsclean
# todo: install DuckDB

ADD package.json ./
RUN --mount=type=cache,target=/tmp/node-compile-cache \
	--mount=type=cache,target=/root/.npm \
	npm install --omit dev && npm cache clean --force

ADD . .

WORKDIR /var/gtfs

# todo
