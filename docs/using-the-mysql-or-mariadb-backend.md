# Using the MySQL(MariaDB) backend

Now supports MySQL(MariaDB) backend.

<br>



## Environment Variables

#### DB_TYPE

Set to `mysql` switch to MySQL(MariaDB) database.

Default: `sqlite`

#### MYSQL_HOST

MySQL(MariaDB) host, **required**.

#### MYSQL_PORT

MySQL(MariaDB) port.

Default: `3306`

#### MYSQL_DATABASE

MySQL(MariaDB) database name.

Default: `vaultwarden`

#### MYSQL_USERNAME

MySQL(MariaDB) username.

Default: `vaultwarden`

#### MYSQL_PASSWORD

MySQL(MariaDB) password, **required**.

#### MYSQL_SSL

Enable SSL for connection.

No default value is set; it uses the default provided by `mariadb-dump`, and starting from version `10.11`, the default is `TRUE`.

#### MYSQL_SSL_VERIFY_SERVER_CERT

Verify server's certificate.

No default value is set; it uses the default provided by `mariadb-dump`, and starting from version `11.4`, the default is `TRUE`.

If you encounter any TLS-related connection errors, you can try disabling it by setting values such as `0` or `FALSE`.

#### MYSQL_SSL_CA

The path to the CA certificate for TLS connection (optional).

#### MYSQL_SSL_CERT

The path to the client certificate for TLS connection (optional).

#### MYSQL_SSL_KEY

The path to the client key for TLS connection (optional).

<br>



## Backup

Specify the above environment variables to switch to the MySQL(MariaDB) database.

<br>



## Restore

When restoring, also specify the above environment variables to switch to the MySQL(MariaDB) database.

1. Ensure that the database is accessible.

Perhaps you will use the `docker-compose up -d [services name]` command to start the database separately.

2. Verify that the `MYSQL_HOST` you are using is accessible to.

If your database is running in docker-compose, you need to find the corresponding network name via `docker network ls`  and add `--network=[name]` to the restore command to specify the network name.

3. Restore and restart the container.
