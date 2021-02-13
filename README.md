# EteBase Backup

[![Docker Image Version (latest by date)](https://img.shields.io/docker/v/karbon15/etebase-backup?label=Version&logo=docker)](https://hub.docker.com/r/karbon15/etebase-backup/tags) [![Docker Pulls](https://img.shields.io/docker/pulls/karbon15/etebase-backup?label=Docker%20Pulls&logo=docker)](https://hub.docker.com/r/karbon15/etebase-backup) [![GitHub](https://img.shields.io/github/license/karbon16/EteBase-Backup?label=License&logo=github)](https://github.com/karbon15/EteBase-Backup/blob/master/LICENSE)

Docker containers for [etebase server](https://github.com/etesync/server) backup to remote.

- [Docker Hub](https://hub.docker.com/r/karbon15/etebase-backup)
- [GitHub](https://github.com/karbon15/EteBase-Backup)



## Feature

This tool supports backing up the following files or directories.

- `db.sqlite3`
- `etebase-server.ini`
- `media` (directory)
- `secret.txt`


## Usage

> **Important:** We assume you already read the `etebase` [documentation](https://github.com/etesync/server/wiki).

### Backup

We upload the backup files to the storage system by [Rclone](https://rclone.org/).

Visit [GitHub](https://github.com/rclone/rclone) for more storage system tutorials. Different systems get tokens differently.

You can get the token by the following command.

```shell
docker run --rm -it \
  --mount type=volume,source=etebase-rclone-data,target=/config/ \
  karbon15/etebase-backup:latest \
  rclone config
```

After setting, check the configuration content by the following command.

```shell
docker run --rm -it \
  --mount type=volume,source=etebase-rclone-data,target=/config/ \
  karbon15/etebase-backup:latest \
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

Make sure that your etebase container is named `etebase` otherwise you have to replace the container name in the `--volumes-from` section of the docker run call.

Start backup container with default settings (automatic backup at 5 minute every hour)

```shell
docker run -d \
  --restart=always \
  --name etebase_backup \
  --volumes-from=etebase \
  --mount type=volume,source=etebase-rclone-data,target=/config/ \
  -e RCLONE_REMOTE_NAME="YouRemoteName"
  karbon15/etebase-backup:latest
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

If you are using automatic backups, please confirm the etebase volume and replace the `--mount` `source` section.

```shell
docker run --rm -it \
  --mount type=volume,source=etebase-data,target=/etebase/data/ \
  --mount type=bind,source=$(pwd),target=/etebase/restore/ \
  karbon15/etebase-backup:latest restore \
  [OPTIONS]
```

See [Options](#options) for options information.

#### Options

##### --db-file

If you didn't set the `ZIP_ENABLE` environment variable to `TRUE` when you backed up the file, you need to use this option to specify the `db.sqlite3` file.

##### --config-file

If you didn't set the `ZIP_ENABLE` environment variable to `TRUE` when you backed up the file, you need to use this option to specify the `etebase-server.ini` file.

##### --media-file

If you didn't set the `ZIP_ENABLE` environment variable to `TRUE` when you backed up the file, you need to use this option to specify the `attachments.tar` file.

##### --secret-file

If you didn't set the `ZIP_ENABLE` environment variable to `TRUE` when you backed up the file, you need to use this option to specify the `secret.txt` file.


##### --zip-file

If you set the `ZIP_ENABLE` environment variable to `TRUE` when you backed up the file, you need to use this option to specify the `backup-etebase.zip` file.

Make sure the file name in the zip file has not been changed.

##### -p / --password

THIS IS INSECURE!

If the `backup-etebase.zip` file has a password, you can use this option to set the password to unzip it.

If not, the password will be asked for interactively.



## Environment Variables

> **Note:** All environment variables have default values, and you can use the docker image without setting environment variables.

#### RCLONE_REMOTE_NAME

Rclone remote name, you can name it yourself.

Default: `EtebaseBackup`

#### RCLONE_REMOTE_DIR

Folder for storing backup files in the storage system.

Default: `/EtebaseBackup/`

#### CRON

Schedule run backup script, based on Linux `crond`. You can test the rules [here](https://crontab.guru/#5_*_*_*_*).

Default: `5 * * * *` (run the script at 5 minute every hour)

#### ZIP_ENABLE

Compress the backup file as Zip archive. When set to `'FALSE'`, only upload `.sqlite3` files without compression.

Default: `TRUE`

#### ZIP_PASSWORD

Set your password to encrypt Zip archive. Note that the password will always be used when compressing the backup file.

Default: `WHEREISMYPASSWORD?`

#### BACKUP_KEEP_DAYS

Only keep last a few days backup files in the storage system. Set to `0` to keep all backup files.

Default: `0`

#### TIMEZONE

You should set the available timezone name. Currently only used in mail.

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



## Mail Test

You can use the following command to test the mail sending. Remember to replace your smtp variables.

```shell
docker run --rm -it -e MAIL_SMTP_VARIABLES='<your smtp variables>' karbon15/etebase-backup:latest mail <mail send to>

# Or

docker run --rm -it -e MAIL_SMTP_VARIABLES='<your smtp variables>' -e MAIL_TO='<mail send to>' karbon15/etebase-backup:latest mail
```



## License

MIT
