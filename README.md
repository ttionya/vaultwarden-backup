# vaultwarden backup

[![Docker Image Version (latest by date)](https://img.shields.io/docker/v/ttionya/vaultwarden-backup?label=Version&logo=docker)](https://hub.docker.com/r/ttionya/vaultwarden-backup/tags) [![Docker Pulls](https://img.shields.io/docker/pulls/ttionya/vaultwarden-backup?label=Docker%20Pulls&logo=docker)](https://hub.docker.com/r/ttionya/vaultwarden-backup) [![GitHub](https://img.shields.io/github/license/ttionya/vaultwarden-backup?label=License&logo=github)](https://github.com/ttionya/vaultwarden-backup/blob/master/LICENSE)

README | [中文文档](README_zh.md)

Docker containers for [vaultwarden](https://github.com/dani-garcia/vaultwarden) (formerly known as **`bitwarden_rs`**) backup to remote.

- [Docker Hub](https://hub.docker.com/r/ttionya/vaultwarden-backup)
- [GitHub Packages](https://github.com/ttionya/vaultwarden-backup/pkgs/container/vaultwarden-backup)
- [GitHub](https://github.com/ttionya/vaultwarden-backup)

<br>



## Feature

This tool supports backing up the following files or directories.

- `db.sqlite3` (for SQLite database)
- `db.dump` (for PostgreSQL database)
- `db.sql` (for MySQL / MariaDB database)
- `config.json`
- `rsa_key*` (multiple files)
- `attachments` (directory)
- `sends` (directory)

And the following ways of notifying backup results are supported.

- Ping (send on completion, start, success, or failure)
- Mail (SMTP based, send on success and on failure)

<br>



## Usage

> **Important:** We assume you already read the `vaultwarden` [documentation](https://github.com/dani-garcia/vaultwarden/wiki).

### Configure Rclone (⚠️ MUST READ ⚠️)

> **For backup, you need to configure Rclone first, otherwise the backup tool will not work.**
>
> **For restore, it is not necessary.**

We upload the backup files to the storage system by [Rclone](https://rclone.org/).

Visit [GitHub](https://github.com/rclone/rclone) for more storage system tutorials. Different systems get tokens differently.

#### Configure and Check

You can get the token by the following command.

```shell
docker run --rm -it \
  --mount type=volume,source=vaultwarden-rclone-data,target=/config/ \
  ttionya/vaultwarden-backup:latest \
  rclone config
```

**We recommend setting the remote name to `BitwardenBackup`, otherwise you need to specify the environment variable `RCLONE_REMOTE_NAME` as the remote name you set.**

After setting, check the configuration content by the following command.

```shell
docker run --rm -it \
  --mount type=volume,source=vaultwarden-rclone-data,target=/config/ \
  ttionya/vaultwarden-backup:latest \
  rclone config show

# Microsoft Onedrive Example
# [BitwardenBackup]
# type = onedrive
# token = {"access_token":"access token","token_type":"token type","refresh_token":"refresh token","expiry":"expiry time"}
# drive_id = driveid
# drive_type = personal
```

<br>



### Backup

#### Use Docker Compose (Recommend)

If you are a new user or are rebuilding vaultwarden, it is recommended to use the `docker-compose.yml` from the project.

Download `docker-compose.yml` to you machine, edit environment variables and start it.

You need to go to the directory where the `docker-compose.yml` file is saved.

```shell
# Start
docker-compose up -d

# Stop
docker-compose stop

# Restart
docker-compose restart

# Remove
docker-compose down
```

#### Automatic Backups

If you have a running vaultwarden but don't want to use `docker-compose.yml`, we also provide a backup method for you.

Make sure that your vaultwarden container is named `vaultwarden` otherwise you have to replace the container name in the `--volumes-from` section of the docker run call.

By default the data folder for vaultwarden is `/data`, you need to explicitly specify the data folder using the environment variable `DATA_DIR`.

Start the backup container with default settings. (automatic backup at 5 minute every hour)

```shell
docker run -d \
  --restart=always \
  --name vaultwarden_backup \
  --volumes-from=vaultwarden \
  --mount type=volume,source=vaultwarden-rclone-data,target=/config/ \
  -e DATA_DIR="/data" \
  ttionya/vaultwarden-backup:latest
```

<br>



### Restore

> **Important:** Restore will overwrite the existing files.

You need to stop the Docker container before the restore.

You also need to download the backup files to your local machine.

Because the host's files are not accessible in the Docker container, you need to map the directory where the backup files that need to be restored are located to the docker container.

**And go to the directory where your backup files to be restored are located.**

If you use the `docker-compose.yml` provided with this project, you can use the following command.

```shell
docker run --rm -it \
  --mount type=volume,source=vaultwarden-data,target=/bitwarden/data/ \
  --mount type=bind,source=$(pwd),target=/bitwarden/restore/ \
  ttionya/vaultwarden-backup:latest restore \
  [OPTIONS]
```

If you are using "automatic backups", please confirm the vaultwarden volume and replace the `--mount` `source` section.

Also don't forget to use the environment variable `DATA_DIR` to specify the data directory (`-e DATA_DIR="/data"`).

```shell
docker run --rm -it \
  \ # If you are mapping the local folder to a docker container, like `vw-data`
  --mount type=bind,source="the absolution path to your local folder",target=/data/ \
  \ # If you are using docker volume
  --mount type=volume,source="docker volume name",target=/data/ \
  --mount type=bind,source=$(pwd),target=/bitwarden/restore/ \
  -e DATA_DIR="/data" \
  ttionya/vaultwarden-backup:latest restore \
  [OPTIONS]
```

See [Options](#options) for options information.

#### Options

##### -f / --force-restore

For restore without asking for confirmation.

USE WITH CAUTION!!

<details>
<summary><strong>※ You have the compressed file named <code>backup</code></strong></summary>

##### --zip-file \<file>

You need to use this option to specify the `backup` compressed package.

Make sure the file name in the compressed package has not been changed.

##### -p / --password

THIS IS INSECURE!

If the `backup` compressed package has a password, you can use this option to set the password to extract it.

If not, the password will be asked for interactively.

</details>

<details>
<summary><strong>※ You have multiple independent backup files</strong></summary>

##### --db-file \<file>

You need to use this option to specify the `db.*` file.

##### --config-file \<file>

You need to use this option to specify the `config.json` file.

##### --rsakey-file \<file>

You need to use this option to specify the `rsakey.tar` file.

##### --attachments-file \<file>

You need to use this option to specify the `attachments.tar` file.

##### --sends-file \<file>

You need to use this option to specify the `sends.tar` file.

</details>

<br>



## Environment Variables

> **Note:** All environment variables have default values, you can use the docker image without setting any environment variables.

#### RCLONE_REMOTE_NAME

The name of the Rclone remote, which needs to be consistent with the remote name in the rclone config.

You can view the current remote name with the following command.

```shell
docker run --rm -it \
  --mount type=volume,source=vaultwarden-rclone-data,target=/config/ \
  ttionya/vaultwarden-backup:latest \
  rclone config show

# [BitwardenBackup] <- this
# ...
```

Default: `BitwardenBackup`

#### RCLONE_REMOTE_DIR

The folder where backup files are stored in the storage system.

Default: `/BitwardenBackup/`

#### RCLONE_GLOBAL_FLAG

Rclone global flags, see [flags](https://rclone.org/flags/).

**Do not add flags that will change the output, such as `-P`, which will affect the deletion of outdated backup files.**

Default: `''`

#### CRON

Schedule to run the backup script, based on [`supercronic`](https://github.com/aptible/supercronic). You can test the rules [here](https://crontab.guru/#5_*_*_*_*).

Default: `5 * * * *` (run the script at 5 minute every hour)

#### ZIP_ENABLE

Pack all backup files into a compressed file. When set to `'FALSE'`, each backup file will be uploaded independently.

Default: `TRUE`

#### ZIP_PASSWORD

The password for the compressed file. Note that the password will always be used when packing the backup files.

Default: `WHEREISMYPASSWORD?`

#### ZIP_TYPE

Because the `zip` format is less secure, we offer archives in `7z` format for those who seek security.

It should be noted that the password for vaultwarden is encrypted before it is sent to the server. The server does not have plaintext passwords, so the `zip` format is good enough for basic encryption needs.

Default: `zip` (only support `zip` and `7z` formats)

#### BACKUP_KEEP_DAYS

Only keep last a few days backup files in the storage system. Set to `0` to keep all backup files.

Default: `0`

#### BACKUP_FILE_SUFFIX

Each backup file is suffixed by default with `%Y%m%d`. If you back up your vault multiple times a day, that suffix is not unique anymore. This environment variable allows you to append a unique suffix to that date to create a unique backup name.

You can use any character except for `/` since it cannot be used in Linux file names.

This environment variable combines the functionalities of [`BACKUP_FILE_DATE`](#backup_file_date) and [`BACKUP_FILE_DATE_SUFFIX`](#backup_file_date_suffix), and has a higher priority. You can directly use this environment variable to control the suffix of the backup files.

Please use the [date man page](https://man7.org/linux/man-pages/man1/date.1.html) for the format notation.

Default: `%Y%m%d`

#### TIMEZONE

Set your timezone name.

Here is timezone list at [wikipedia](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones).

Default: `UTC`

#### DISPLAY_NAME

A custom name to identify your vaultwarden instance in notifications and logs.

This doesn't affect functionality, it only affects the display in the notification title and partial log output.

Default: `vaultwarden`

#### DATA_DIR

This folder stores the data of vaultwarden.

When using `Docker Compose`, this does not need to be changed. However, when using automatic backup, you need to change it to `/data`.

Default: `/bitwarden/data`

<strong>※ Please refer to the [`Notification`](#notification) section for notification-related environment variables.</strong>

<details>
<summary><strong>※ Other environment variables</strong></summary>

> **You don't need to change these environment variables unless you know what you are doing.**

#### BACKUP_FILE_DATE

You should use the [`BACKUP_FILE_SUFFIX`](#backup_file_suffix) environment variable instead.

Edit this environment variable only if you explicitly want to change the time prefix of the backup file (e.g. 20220101). **Incorrect configuration may result in the backup file being overwritten by mistake.**

Same rule as [`BACKUP_FILE_DATE_SUFFIX`](#backup_file_date_suffix).

Default: `%Y%m%d`

#### BACKUP_FILE_DATE_SUFFIX

You should use the [`BACKUP_FILE_SUFFIX`](#backup_file_suffix) environment variable instead.

Each backup file is suffixed by default with `%Y%m%d`. If you back up your vault multiple times a day, that suffix is not unique anymore.
This environment variable allows you to append a unique suffix to that date (`%Y%m%d${BACKUP_FILE_DATE_SUFFIX}`) to create a unique backup name.

Note that only numbers, upper and lower case letters, `-`, `_`, `%` are supported.

Please use the [date man page](https://man7.org/linux/man-pages/man1/date.1.html) for the format notation.

Default: `''`

#### DATA_DB

Set the path for the sqlite database file.

Default: `${DATA_DIR}/db.sqlite3`

#### DATA_RSAKEY

Set the path for the rsa_key file.

Default: `${DATA_DIR}/rsa_key`

#### DATA_ATTACHMENTS

Set the path for the attachment folder.

Default: `${DATA_DIR}/attachments`

#### DATA_SENDS

Set the path for the sends folder.

Default: `${DATA_DIR}/sends`

</details>

<br>



## Notification

### Ping

We provide functionality to send notifications when the backup is completed, started, successful, or failed.

**Using a [healthcheck.io](https://healthchecks.io/) address or other similar cron monitoring addresses is a good choice, and it is also recommended.** For more complex notification scenarios, you can use environment variables with the `_CURL_OPTIONS` suffix to set curl options. For example, you can add request headers, change the request method, etc.

For different notification scenarios, **the backup tool provides `%{subject}` and `%{content}` placeholders to replace the actual title and content**. You can use them in the following environment variables. Note that the title and content may contain spaces. For the four environment variables containing `_CURL_OPTIONS`, the placeholders will be directly replaced, retaining spaces. For other `PING_URL` environment variables, spaces will be replaced with `+` to comply with URL rules.

| Environment Variable                               | Trigger Status        | Test Identifier         | Description                                                          |
|------------------------------------|-------------|--------------|----------------------------------------------------------------------|
| PING_URL                           | completion (success or failure) | `completion` | The URL to which the request is sent after the backup is completed.  |
| PING_URL_CURL_OPTIONS              |             |  | Curl options used with `PING_URL`                                    |
| PING_URL_WHEN_START                | start          | `start` | The URL to which the request is sent when the backup starts.         |
| PING_URL_WHEN_START_CURL_OPTIONS   |             |  | Curl options used with `PING_URL_WHEN_START`                         |
| PING_URL_WHEN_SUCCESS              | success          | `success` | The URL to which the request is sent after the backup is successful. |
| PING_URL_WHEN_SUCCESS_CURL_OPTIONS |             |  | Curl options used with `PING_URL_WHEN_SUCCESS`                       |
| PING_URL_WHEN_FAILURE              | failure          | `failure` | The URL to which the request is sent after the backup fails.         |
| PING_URL_WHEN_FAILURE_CURL_OPTIONS |             |  | Curl options used with `PING_URL_WHEN_FAILURE`                       |

<br>



### Ping Test

You can use the following command to test the Ping sending.

The "test identifier" is the identifier in the table in the [previous section](#ping). You can use `completion`, `start`, `success`, or `failure`, which determines which set of environment variables to use.

```shell
docker run --rm -it \
  -e PING_URL='<your ping url>' \
  -e PING_URL_CURL_OPTIONS='<your curl options for PING_URL>' \
  -e PING_URL_WHEN_START='<your ping url>' \
  -e PING_URL_WHEN_START_CURL_OPTIONS='<your curl options for PING_URL_WHEN_START>' \
  -e PING_URL_WHEN_SUCCESS='<your ping url>' \
  -e PING_URL_WHEN_SUCCESS_CURL_OPTIONS='<your curl options for PING_URL_WHEN_SUCCESS>' \
  -e PING_URL_WHEN_FAILURE='<your ping url>' \
  -e PING_URL_WHEN_FAILURE_CURL_OPTIONS='<your curl options for PING_URL_WHEN_FAILURE>' \
  ttionya/vaultwarden-backup:latest ping <test identifier>
```

<br>



### Mail

Starting from v1.19.0, we will be using [`s-nail`](https://www.sdaoden.eu/code-nail.html) instead of [`heirloom-mailx`](https://www.systutorials.com/docs/linux/man/1-heirloom-mailx/) to send emails.

Please note that `heirloom-mailx` is a stub for `s-nail`, and most of its functionality is compatible. Therefore, you may not need to modify any environment variables for this change.

| Environment Variable | Default Value | Description                                                                                                           |
| --- | --- |-----------------------------------------------------------------------------------------------------------------------|
| MAIL_SMTP_ENABLE | `FALSE` | Enable sending mail.                                                                                                  |
| MAIL_SMTP_VARIABLES | | Mail sending options.                                                                                                 |
| MAIL_TO | | The recipient of the notification email.                                                                              |
| MAIL_WHEN_SUCCESS | `TRUE` | Send an email when the backup completes successfully.                                                                 |
| MAIL_WHEN_FAILURE | `TRUE` | Send an email if the backup fails.                                                                                    |
| MAIL_FORCE_THREAD | `FALSE` | Particularly useful when mail clients fail to group related messages in conversation view despite identical subjects. |

For `MAIL_SMTP_VARIABLES`, you need to configure the mail sending options yourself. **We will set the email subject based on the usage scenario, so you should not use the `-s` flag.**

```text
# My example:

# For Zoho
-S smtp-use-starttls \
-S smtp=smtp://smtp.zoho.com:587 \
-S smtp-auth=login \
-S smtp-auth-user=<my-email-address> \
-S smtp-auth-password=<my-email-password> \
-S from=<my-email-address>
```

Console showing warnings? Check [issue #177](https://github.com/ttionya/vaultwarden-backup/issues/117#issuecomment-1691443179) for more details.

For `MAIL_FORCE_THREAD`, particularly useful when receiving systems fail to properly aggregate messages into conversation threads. It supports three modes of operation:

1. `FALSE`: Default email sending behavior.
2. `TRUE`: Auto-generates RFC-compliant Message-ID to force thread creation. **Note: Container restarts invalidate thread associations. For persistence, mount the `/mail_parent_message_id` file or set the `MAIL_FORCE_THREAD` environment variable to the generated Message-ID.**
3. `Valid Message-ID string`: Uses specified Message-ID to associate with existing thread. Find it in the original email's Message-ID field.

When enabled, the system automatically adds required headers (`Message-ID`, `References`, `In-Reply-To`) to enforce proper thread association on the receiving end.

<br>



### Mail Test

You can use the following command to test mail sending. We will add the `-v` flag to display detailed information, so you do not need to set it again in `MAIL_SMTP_VARIABLES`.

```shell
docker run --rm -it -e MAIL_SMTP_VARIABLES='<your smtp variables>' ttionya/vaultwarden-backup:latest mail <mail send to>

# Or

docker run --rm -it -e MAIL_SMTP_VARIABLES='<your smtp variables>' -e MAIL_TO='<mail send to>' ttionya/vaultwarden-backup:latest mail
```

<br>



## Environment Variables Considerations

### Using `.env` file

If you prefer using an env file instead of environment variables, you can map the env file containing the environment variables to the `/.env` file in the container.

```shell
docker run -d \
  --mount type=bind,source=/path/to/env,target=/.env \
  ttionya/vaultwarden-backup:latest
```

**Please do not use the `--env-file` flag directly**; make sure to map the environment variables by mounting the file. The `--env-file` flag incorrectly handles quotes, which can lead to unexpected situations. For more information, please see [docker/cli#3630](https://github.com/docker/cli/issues/3630).

<br>



### Docker Secrets

As an alternative to passing sensitive information via environment variables, you can append `_FILE` to the previously listed environment variables. This causes the initialization script to load the values for those variables from files present in the container. In particular, this can be used to load passwords from Docker secrets stored in `/run/secrets/<secret_name>` files.

```shell
docker run -d \
  -e ZIP_PASSWORD_FILE=/run/secrets/zip-password \
  ttionya/vaultwarden-backup:latest
```

<br>



### About Priority

We look for environment variables in the following order:

1. Directly read the value of the environment variable
2. Read the content of the file pointed to by the environment variable ending in `_FILE`
3. Read the content of the file pointed to by the environment variable ending in `_FILE` in the `.env` file
4. Read the value of the environment variable in the `.env` file

Example:

```txt
# For 1
MY_ENV="example1"

# For 2
MY_ENV_FILE="/path/to/example2"

# For 3 (.env file)
MY_ENV_FILE="/path/to/example3" 

# For 4 (.env file)
MY_ENV="example4"
```

<br>



## Migration

**Unofficial Bitwarden compatible server written in Rust, formerly known as `bitwarden_rs`, has been renamed to `vaultwarden`. Consequently, this backup tool has also been renamed from `bitwardenrs-backup` to `vaultwarden-backup`.**

The old image can still be used, just **DEPRECATED**. Please migrate to the new image as soon as possible.

**Migration Instructions**

If you use automatic backups, you only need to replace the image with `ttionya/vaultwarden-backup`. Note the name of your volume.

If you use `docker-compose`, you need to update `bitwardenrs/server` to `vaultwarden/server` and `ttionya/bitwardenrs-backup` to `ttionya/vaultwarden-backup`.

We recommend re-downloading the [`docker-compose.yml`](./docker-compose.yml) file, updating your environment variables, and paying attention to the `volumes` section, which you may need to modify.

<br>



## Advance

- [Run as non-root user](docs/run-as-non-root-user.md)
- [Multiple remote destinations](docs/multiple-remote-destinations.md)
- [Manually trigger a backup](docs/manually-trigger-a-backup.md)
- [Using the PostgreSQL backend](docs/using-the-postgresql-backend.md)
- [Using the MySQL(MariaDB) backend](docs/using-the-mysql-or-mariadb-backend.md)

<br>



## Changelog

Check out the [CHANGELOG](CHANGELOG.md) file.

<br>



## Thanks

I am grateful for the OSS license provided by [JetBrains](https://www.jetbrains.com/).

<a href="https://jb.gg/OpenSource" target="_blank"><img src="https://resources.jetbrains.com/storage/products/company/brand/logos/jetbrains.svg" alt="JetBrains logo."></a>

<br>



## License

MIT
