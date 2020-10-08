# BitwardenRS Backup

Docker containers for [bitwarden_rs](https://github.com/dani-garcia/bitwarden_rs) backup to remote.

- [Docker Hub](https://hub.docker.com/r/ttionya/bitwardenrs-backup)
- [GitHub](https://github.com/ttionya/BitwardenRS-Backup)

## Feature

This tool supports backing up the following files or directories.

- `db.sqlite3`
- `config.json`
- `attachments` (directory)

## Usage

> **Important:** We assume you already read the `bitwarden_rs` [documentation](https://github.com/dani-garcia/bitwarden_rs/wiki).

We upload the backup files to the storage system by [Rclone](https://rclone.org/).

Visit [GitHub](https://github.com/rclone/rclone) for more storage system tutorials. Different systems get tokens differently.

You can get the token by the following command.

```shell
docker run --rm -it --mount source=bitwardenrs-rclone-data,target=/config/ ttionya/bitwardenrs-backup:latest rclone config
```

After setting, check the configuration content by the following command.

```shell
docker run --rm -it --mount source=bitwardenrs-rclone-data,target=/config/ ttionya/bitwardenrs-backup:latest rclone config show

# Microsoft Onedrive Example
# [YouRemoteName]
# type = onedrive
# token = {"access_token":"access token","token_type":"token type","refresh_token":"refresh token","expiry":"expiry time"}
# drive_id = driveid
# drive_type = personal
```

Note that you need to set the environment variable `RCLONE_REMOTE_NAME` to a remote name like `YouRemoteName`.

### Automatic Backups

Make sure that your bitwarden_rs container is named `bitwardenrs` otherwise you have to replace the container name in the `--volumes-from` section of the docker run call.

Start backup container with default settings (automatic backup at 5 minute every hour)

```shell
docker run -d \
  --restart=always \
  --name bitwardenrs_backup \
  --volumes-from=bitwardenrs \
  --mount source=bitwardenrs-rclone-data,target=/config/ \
  -e RCLONE_REMOTE_NAME="YouRemoteName"
  ttionya/bitwardenrs-backup:latest
```

### Use Docker Compose

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

## Environment Variables

**Note:** All environment variables have default values, and you can use the docker image without setting environment variables.

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
docker run --rm -it -e MAIL_SMTP_VARIABLES='<your smtp variables>' ttionya/bitwardenrs-backup:latest mail <mail send to>

# Or

docker run --rm -it -e MAIL_SMTP_VARIABLES='<your smtp variables>' -e MAIL_TO='<mail send to>' ttionya/bitwardenrs-backup:latest mail
```

## License

MIT
