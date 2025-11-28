# DuckDB GTFS importer

This tool **imports [GTFS Schedule](https://gtfs.org/schedule/) data into a [DuckDB](https://duckdb.org) database using [`gtfs-via-duckdb`](https://github.com/public-transport/gtfs-via-duckdb)**. It allows running a production service (e.g. an API) on top of programmatically re-imported data from a periodically changing GTFS feed without downtime.

> [!TIP]
>
> This is a clone of [`postgis-gtfs-importer`](https://github.com/mobidata-bw/postgis-gtfs-importer), please refer to its docs for more information on how `duckdb-gtfs-importer` works.
>
> All `postgis-gtfs-importer` environment variables (e.g. `$GTFS_DOWNLOAD_URL` or `$GTFS_IMPORTER_DB_PREFIX`) should be supported, except the PostgreSQL-specific ones.


## Usage

```shell
mkdir gtfs
mkdir gtfs-tmp
docker run --rm -it \
	-v $PWD/gtfs:/var/gtfs \
	-v $PWD/gtfs-tmp:/tmp/gtfs \
	-e 'GTFS_DOWNLOAD_USER_AGENT=…' \
	-e 'GTFS_DOWNLOAD_URL=…' \
	-e 'GTFS_IMPORTER_VERBOSE=false' \
	-e 'GTFSTIDY_BEFORE_IMPORT=false' \
	ghcr.io/opendatavbb/duckdb-gtfs-importer
```


## Related

- [postgis-gtfs-importer](https://github.com/mobidata-bw/postgis-gtfs-importer) – Imports GTFS data into a PostGIS database, using gtfsclean & gtfs-via-postgres.
