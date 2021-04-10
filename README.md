# BitwardenRS Backup

[![Docker Image Version (latest by date)](https://img.shields.io/docker/v/ttionya/bitwardenrs-backup?label=Version&logo=docker)](https://hub.docker.com/r/ttionya/bitwardenrs-backup/tags) [![Docker Pulls](https://img.shields.io/docker/pulls/ttionya/bitwardenrs-backup?label=Docker%20Pulls&logo=docker)](https://hub.docker.com/r/ttionya/bitwardenrs-backup) [![GitHub](https://img.shields.io/github/license/ttionya/BitwardenRS-Backup?label=License&logo=github)](https://github.com/ttionya/BitwardenRS-Backup/blob/master/LICENSE)

[README](README.md) | [中文文档](README_zh.md)

Docker containers for [bitwarden_rs](https://github.com/dani-garcia/bitwarden_rs) backup to remote.

- [Docker Hub](https://hub.docker.com/r/ttionya/bitwardenrs-backup)
- [GitHub](https://github.com/ttionya/BitwardenRS-Backup)



## Feature

This tool supports backing up the following files or directories.

- `db.sqlite3`
- `config.json`
- `rsa_key*` (multiple files)
- `attachments` (directory)
- `sends` (directory)



## Usage

> **Important:** We assume you already read the `bitwarden_rs` [documentation](https://github.com/dani-garcia/bitwarden_rs/wiki).

### Backup

We upload the backup files to the storage system by [Rclone](https://rclone.org/).

Visit [GitHub](https://github.com/rclone/rclone) for more storage system tutorials. Different systems get tokens differently.

You can get the token by the following command.

```shell
docker run --rm -it \
  --mount type=volume,source=bitwardenrs-rclone-data,target=/config/ \
  ttionya/bitwardenrs-backup:latest \
  rclone config
```

After setting, check the configuration content by the following command.

```shell
docker run --rm -it \
  --mount type=volume,source=bitwardenrs-rclone-data,target=/config/ \
  ttionya/bitwardenrs-backup:latest \
  rclone config show

# Microsoft Onedrive Example
# [YouRemoteName]
# type = onedrive
# token = {"access_token":"access token","token_type":"token type","refresh_token":"refresh token","expiry":"expiry time"}
# drive_id = driveid
# drive_type = personal
```

Note that you need to set the environment variable `RCLONE_REMOTE_NAME` to a remote name like `YouRemoteName`.

#### Automatic Backups

Make sure that your bitwarden_rs container is named `bitwarden` otherwise you have to replace the container name in the `--volumes-from` section of the docker run call.

By default the data folder for bitwarden_rs is `/data`, you need to explicitly specify the data folder using the environment variable `DATA_DIR`.

Start the backup container with default settings. (automatic backup at 5 minute every hour)

```shell
docker run -d \
  --restart=always \
  --name bitwardenrs_backup \
  --volumes-from=bitwarden \
  --mount type=volume,source=bitwardenrs-rclone-data,target=/config/ \
  -e RCLONE_REMOTE_NAME="YouRemoteName" \
  -e DATA_DIR="/data" \
  ttionya/bitwardenrs-backup:latest
```

#### Use Docker Compose

Download `docker-compose.yml` to you machine, edit environment variables and start it. You need to go to the directory where the `docker-compose.yml` file is saved.

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

### Restore

> **Important:** Restore will overwrite the existing files.

You need to stop the Docker container before the restore.

Because the host's files are not accessible in the Docker container, you need to map the directory where the backup files that need to be restored are located to the docker container.

And go to the directory where your backup files are located.

If you are using automatic backups, please confirm the bitwarden_rs volume and replace the `--mount` `source` section. Also don't forget to use the environment variable `DATA_DIR` to specify the data directory (`-e DATA_DIR="/data"`).

```shell
docker run --rm -it \
  --mount type=volume,source=bitwardenrs-data,target=/bitwarden/data/ \
  --mount type=bind,source=$(pwd),target=/bitwarden/restore/ \
  ttionya/bitwardenrs-backup:latest restore \
  [OPTIONS]
```

See [Options](#options) for options information.

#### Options

<details>
<summary>You have the compressed file named <code>backup</code></summary>

##### --zip-file

You need to use this option to specify the `backup` compressed package.

Make sure the file name in the compressed package has not been changed.

##### -p / --password

THIS IS INSECURE!

If the `backup` compressed package has a password, you can use this option to set the password to extract it.

If not, the password will be asked for interactively.

</details>

<details>
<summary>You have multiple independent backup files</summary>

##### --db-file

You need to use this option to specify the `db.sqlite3` file.

##### --config-file

You need to use this option to specify the `config.json` file.

##### --rsakey-file

You need to use this option to specify the `rsakey.tar` file.

##### --attachments-file

You need to use this option to specify the `attachments.tar` file.

##### --sends-file

You need to use this option to specify the `sends.tar` file.

</details>



## Environment Variables

> **Note:** All environment variables have default values, and you can use the docker image without setting environment variables.

#### RCLONE_REMOTE_NAME

Rclone remote name, you can name it yourself.

Default: `BitwardenBackup`

#### RCLONE_REMOTE_DIR

Folder for storing backup files in the storage system.

Default: `/BitwardenBackup/`

#### CRON

Schedule run backup script, based on Linux `crond`. You can test the rules [here](https://crontab.guru/#5_*_*_*_*).

Default: `5 * * * *` (run the script at 5 minute every hour)

#### ZIP_ENABLE

Compress the backup file as Zip archive. When set to `'FALSE'`, only upload `.sqlite3` files without compression.

Default: `TRUE`

#### ZIP_PASSWORD

Set your password to encrypt Zip archive. Note that the password will always be used when compressing the backup file.

Default: `WHEREISMYPASSWORD?`

#### ZIP_TYPE

Because the `zip` format is less secure, we offer archives in `7z` format for those who seek security.

It should be noted that the password for bitwardenrs is encrypted before it is sent to the server. The server does not have plaintext passwords, so the `zip` format is good enough for basic encryption needs.

Default: `zip` (only support `zip` and `7z` format)

#### BACKUP_KEEP_DAYS

Only keep last a few days backup files in the storage system. Set to `0` to keep all backup files.

Default: `0`

#### BACKUP_FILE_DATE_SUFFIX

Each backup file is suffixed by default with `%Y%m%d`. If you back up your vault multiple times a day that suffix is not unique anymore.
This environment variable allows you to append that date (`%Y%m%d${BACKUP_FILE_DATE_SUFFIX}`) suffix in order to create a unique backup name.

Note that only numbers, upper and lower case letters, `-`, `_`, `%` are supported.

Please use the [date man page](https://man7.org/linux/man-pages/man1/date.1.html) for the format notation.

Default: `''`

#### TIMEZONE

You should set the available timezone name.

Here is timezone list at [wikipedia](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones).

Default: `UTC`

#### MAIL_SMTP_ENABLE

The tool uses [heirloom-mailx](https://www.systutorials.com/docs/linux/man/1-heirloom-mailx/) to send mail.

Default: `FALSE`

#### MAIL_SMTP_VARIABLES

Because the configuration for sending emails is too complicated, we allow you to configure it yourself.

**We will set the subject according to the usage scenario, so you should not use the `-s` option.**

When testing, we will add the `-v` option to display detailed information.

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

See [here](https://www.systutorials.com/sending-email-from-mailx-command-in-linux-using-gmails-smtp/) for more information.

#### MAIL_TO

Who will receive the notification email.

#### MAIL_WHEN_SUCCESS

Send email when backup is successful.

Default: `TRUE`

#### MAIL_WHEN_FAILURE

Send email when backup fails.

Default: `TRUE`

#### DATA_DIR

The folder where bitwarden_rs stores its data.

When using `Docker Compose`, you don't need to change it, but when using automatic backup, you need to change it to `/data`.

Default: `/bitwarden/data`

<details>
<summary>Other environment variables</summary>

> **You don't need to change these environment variables unless you know what you're doing.**

#### DATA_DB

Set the sqlite database file path.

Default: `${DATA_DIR}/db.sqlite3`

#### DATA_RSAKEY

Set the rsa_key file path.

Default: `${DATA_DIR}/rsa_key`

#### DATA_ATTACHMENTS

Set the attachment folder path.

Default: `${DATA_DIR}/attachments`

#### DATA_SENDS

Set the sends folder path.

Default: `${DATA_DIR}/sends`

</details>



## Use `.env` file

If you prefer to use env file instead of environment variables, you can map the env file containing the environment variables to the `/.env` file in the container.

```shell
docker run -d \
  --mount type=bind,source=/path/to/env,target=/.env \
  ttionya/bitwardenrs-backup:latest
```



## Docker Secrets

As an alternative to passing sensitive information via environment variables, `_FILE` may be appended to the previously listed environment variables, causing the initialization script to load the values for those variables from files present in the container. In particular, this can be used to load passwords from Docker secrets stored in `/run/secrets/<secret_name>` files.

```shell
docker run -d \
  -e ZIP_PASSWORD_FILE=/run/secrets/zip-password \
  ttionya/bitwardenrs-backup:latest
```



## About Priority

We will use the environment variables first, then the contents of the file ending in `_FILE` as defined by the environment variables, followed by the contents of the file ending in `_FILE` as defined in the `.env` file, and finally the `.env` file values.



## Mail Test

You can use the following command to test the mail sending. Remember to replace your smtp variables.

```shell
docker run --rm -it -e MAIL_SMTP_VARIABLES='<your smtp variables>' ttionya/bitwardenrs-backup:latest mail <mail send to>

# Or

docker run --rm -it -e MAIL_SMTP_VARIABLES='<your smtp variables>' -e MAIL_TO='<mail send to>' ttionya/bitwardenrs-backup:latest mail
```



## License

MIT
