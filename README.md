# DuckDB GTFS importer

This tool **imports [GTFS Schedule](https://gtfs.org/schedule/) data into a [DuckDB](https://duckdb.org) database using [`gtfs-via-duckdb`](https://github.com/public-transport/gtfs-via-duckdb)**. It allows running a production service (e.g. an API) on top of programmatically re-imported data from a periodically changing GTFS feed without downtime.

> [!TIP]
>
> This is a clone of [`postgis-gtfs-importer`](https://github.com/mobidata-bw/postgis-gtfs-importer), please refer to its docs for more information on how `duckdb-gtfs-importer` works.
>
> All `postgis-gtfs-importer` environment variables (e.g. `$GTFS_DOWNLOAD_URL` or `$GTFS_IMPORTER_DB_PREFIX`) should be supported, except the PostgreSQL-specific ones.


## Usage

Configure `duckdb-gtfs-importer`'s behaviour using environment variables; Refer to the source code for more details. The most important variables are:

- `GTFS_DOWNLOAD_URL`: The URL to the GTFS dataset. Will be downloaded using [`curl-mirror`](https://gist.github.com/derhuerst/745cf09fe5f3ea2569948dd215bbfe1a).
- `GTFS_DOWNLOAD_USER_AGENT`: Sent as [`User-Agent`](https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Headers/User-Agent). Please set something meaningful to help the server's operators.
- `GTFSTIDY_BEFORE_IMPORT`: If the GTFS dataset should be [`gtfsclean`](https://github.com/public-transport/gtfsclean)-ed before import. Its behaviour can be further customised by several `GTFSTIDY_…` variables (refer to the source code).
- `GTFS_IMPORTER_DB_PREFIX`: The "base name" for the GTFS DuckDBs created. You need this if you want to import more than one different GTFS feed. For example, with `GTFS_IMPORTER_DB_PREFIX=vbb`, they will be named `vbb_$timestamp_$hash.gtfs.duckdb` and `vbb.gtfs.duckdb`.

### With Docker

Mount two directories into the container:
- the one containing the final imported GTFS DuckDB at `/var/gtfs`
- the one containing temporary files (e.g. downloaded GTFS datasets) at `/tmp/gtfs`

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

### Without Docker

The following tools need to be in your `$PATH`:
- the [`task` CLI](https://taskfile.dev/)
- [DuckDB](https://duckdb.org/)'s [`duckdb` CLI](https://duckdb.org/docs/stable/clients/cli/overview)
- [`curl-mirror`](https://gist.github.com/derhuerst/745cf09fe5f3ea2569948dd215bbfe1a), which needs [Node.js](https://nodejs.org)
- [`gtfs-via-duckdb`](https://npmjs.com/package/gtfs-via-duckdb), which needs [Node.js](https://nodejs.org)
- `unzip`, `sha256sum`, `touch`, `ln`

Run `duckdb-gtfs-importer` using the `task` CLI:

```shell
task \
	-t Taskfile.yml \
	-d path/to/gtfs/dir
```

### Windows

While [Task uses a portable shell and "core utils" on Windows](https://taskfile.dev/blog/windows-core-utils) to mimick the behaviour of UNIX/GNU tools, there are subtle but important differences between the [shims](https://en.wikipedia.org/wiki/Shim_(computing)) and their real counterpart. Therefore, `duckdb-gtfs-importer` will not work flawlessly on platforms like Windows.

For example, `duckdb-gtfs-importer` makes use of [`touch`](https://www.gnu.org/software/coreutils/manual/html_node/touch-invocation.html)'s `-h`/`--no-dereference` flag, which does not exist in the [`touch` used by Task](https://github.com/u-root/u-root/blob/a9c0bf61c74128eceaed057ee98f4068b603c5f9/pkg/core/touch/touch.go#L32-L37).


## Related

- [postgis-gtfs-importer](https://github.com/mobidata-bw/postgis-gtfs-importer) – Imports GTFS data into a PostGIS database, using gtfsclean & gtfs-via-postgres.
