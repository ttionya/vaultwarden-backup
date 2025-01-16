# Using the PostgreSQL backend

Now supports PostgreSQL backend.

~~Because upstream Rclone image is based on `alpine 3.16`(and `linux/arm/v6` platform is based on `alpine 3.15`), it **only supports PostgreSQL 14 and previous versions**, see [Alpine 3.16 Packages](https://pkgs.alpinelinux.org/packages?name=postgresql*-client&branch=v3.16) and [Alpine 3.15 Packages](https://pkgs.alpinelinux.org/packages?name=postgresql*-client&branch=v3.15).~~

We support PostgreSQL 17 and previous versions.

If the `postgresql*-client` is not updated promptly, please create an issue to inform us.

<br>



## Environment Variables

#### DB_TYPE

Set to `postgresql` switch to PostgreSQL database.

Default: `sqlite`

#### PG_HOST

PostgreSQL host, **required**.

#### PG_PORT

PostgreSQL port.

Default: `5432`

#### PG_DBNAME

PostgreSQL database name.

Default: `vaultwarden`

#### PG_USERNAME

PostgreSQL username.

Default: `vaultwarden`

#### PG_PASSWORD

PostgreSQL password, **required**.

The login information will be saved in the `~/.pgpass` file.

<br>



## Backup

Specify the above environment variables to switch to the PostgreSQL database.

<br>



## Restore

When restoring, also specify the above environment variables to switch to the PostgreSQL database.

1. Ensure that the database is accessible.

Perhaps you will use the `docker-compose up -d [services name]` command to start the database separately.

2. Verify that the `PG_HOST` you are using is accessible to.

If your database is running in docker-compose, you need to find the corresponding network name via `docker network ls`  and add `--network=[name]` to the restore command to specify the network name.

3. Restore and restart the container.
