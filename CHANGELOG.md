# Changelog

## v1.25.0 (20250802)

### Feature

- Add environment variable `MAIL_FORCE_THREAD` to control email threading (close [#210](https://github.com/ttionya/vaultwarden-backup/issues/210))

<br>



## v1.24.4 (20250712)

### Feature

- Update Dockerfile base image to `rclone/rclone:1.70.3`

<br>



## v1.24.3 (20250522)

### Feature

- Update Dockerfile base image to `rclone/rclone:1.69.3`

<br>



## v1.24.2 (20250512)

### Fixed

- Fix `directory not found` error (fixed [#199](https://github.com/ttionya/vaultwarden-backup/issues/199))

<br>



## v1.24.1 (20250503)

### Feature

- Update Dockerfile base image to `rclone/rclone:1.69.2`

<br>



## v1.24.0 (20250316)

### Feature

- Add environment variable `DISPLAY_NAME` to customize the display name (close [#189](https://github.com/ttionya/vaultwarden-backup/issues/189))

<br>



## v1.23.2 (20250312)

### Fixed

- Fix the issue where errors occur due to spaces in `MAIL_SMTP_VARIABLES` in some cases (fixed [#186](https://github.com/ttionya/vaultwarden-backup/issues/186))

<br>



## v1.23.1 (20250220)

### Feature

- Add environment variables `MYSQL_SSL` and `MYSQL_SSL_VERIFY_SERVER_CERT` to resolve the MySQL TLS connection error

<br>



## v1.23.0 (20250218)

### Feature

- Update Dockerfile base image to `rclone/rclone:1.69.1`
- Support MySQL SSL connection (close [#185](https://github.com/ttionya/vaultwarden-backup/pull/185))
- Optimize Rclone connection detection logic (close [#183](https://github.com/ttionya/vaultwarden-backup/issues/183))

### Chore

- Compatible with docker/bake-action@v6

<br>



## v1.22.0 (20250116)

### Feature

- Update Dockerfile base image to `rclone/rclone:1.69.0`
- Support PostgreSQL 17 (close [#178](https://github.com/ttionya/vaultwarden-backup/issues/178))
- Allow partial storage system connection failures during backup verification (close [#175](https://github.com/ttionya/vaultwarden-backup/issues/175))

<br>



## v1.21.3 (20241117)

### Feature

- Update Dockerfile base image to `rclone/rclone:1.68.2`
- Use standardized docker labels

<br>



## v1.21.2 (20240925)

### Feature

- Update Dockerfile base image to `rclone/rclone:1.68.1`

<br>



## v1.21.1 (20240914)

### Feature

- Update Dockerfile base image to `rclone/rclone:1.68.0`

<br>



## v1.21.0 (20240907)

### Feature

- Enhance ping functionality to support customizable curl options. (close [#164](https://github.com/ttionya/vaultwarden-backup/issues/164))

<br>



## v1.20.0 (20240721)

### Feature

- Add support for fine-grained ping messages
- Update Dockerfile base image to `rclone/rclone:1.67.0`
- Support testing

<br>



## v1.19.10 (20240313)

### Feature

- Update Dockerfile base image to `rclone/rclone:1.66.0`

<br>



## v1.19.9 (20240223)

### Feature

- Update Dockerfile base image to `rclone/rclone:1.65.2`

<br>



## v1.19.8 (20240112)

### Fixed

- Fix `restore` command parameter parsing error (fixed [#141](https://github.com/ttionya/vaultwarden-backup/issues/141))

<br>



## v1.19.7 (20240111)

### Feature

- Update Dockerfile base image to `rclone/rclone:1.65.1`

<br>



## v1.19.6 (20231214)

### Feature

- Support PostgreSQL 16 (close [#137](https://github.com/ttionya/vaultwarden-backup/issues/137))

<br>



## v1.19.4 (20231128)

### Feature

- Update Dockerfile base image to `rclone/rclone:1.65.0`

<br>



## v1.19.3 (20231021)

### Feature

- Update Dockerfile base image to `rclone/rclone:1.64.2`

<br>



## v1.19.2 (20230912)

### Feature

- Update Dockerfile base image to `rclone/rclone:1.64.0`

<br>



## v1.19.1 (20230722)

### Feature

- Update Dockerfile base image to `rclone/rclone:1.63.1`

<br>



## v1.19.0 (20230704)

**Reminder**: We are utilizing [`s-nail`](https://www.sdaoden.eu/code-nail.html) to send emails. In case you encounter any errors during the email sending process, please modify the `MAIL_SMTP_VARIABLES` environment variables accordingly.

### Feature

- Using `s-nail` instead of `heirloom-mailx` to send emails
- Update Dockerfile base image to `rclone/rclone:1.63.0`

<br>



## v1.18.0 (20230408)

### Feature

- Add environment variable `BACKUP_FILE_SUFFIX`

<br>



## v1.17.0 (20230318)

### Feature

- Update Dockerfile base image to `rclone/rclone:1.62.2`
- Support manually trigger a backup (close [#94](https://github.com/ttionya/vaultwarden-backup/issues/94))

<br>



## v1.16.0 (20230129)

### Feature

- Support PostgreSQL/MySQL/MariaDB backend (close [#88](https://github.com/ttionya/vaultwarden-backup/issues/88))

<br>



## v1.15.3 (20221225)

### Feature

- Update Dockerfile base image to `rclone/rclone:1.61.1`
- Replace `p7zip` with `7zip` package (close [#86](https://github.com/ttionya/vaultwarden-backup/issues/68))

<br>



## v1.15.2 (20221119)

### Feature

- Update Dockerfile base image to `rclone/rclone:1.60.1`

<br>



## v1.15.1 (20221022)

### Feature

- Update Dockerfile base image to `rclone/rclone:1.60.0`

<br>



## v1.15.0 (20221018)

### Feature

- Execute `supercronic` as PID 1 process

<br>



## v1.14.4 (20220916)

### Feature

- Update Dockerfile base image to `rclone/rclone:1.59.2`

<br>



## v1.14.3 (20220908)

### Fixed

- Fix arm/v6 can't use the latest rclone (fixed [#81](https://github.com/ttionya/vaultwarden-backup/issues/81))

<br>



## v1.14.2 (20220826)

### Feature

- Add hidden environment variable `BACKUP_FILE_DATE`

<br>



## v1.14.1 (20220809)

### Feature

- Update Dockerfile base image to `rclone/rclone:1.59.1`

### Chore

- Skip sync when dependabot push branch

<br>



## v1.14.0 (20220731)

### Feature

- Support backup to multiple remote storage

<br>



## v1.13.0 (20220728)

### Feature

- Support force restore without asking for confirmation

<br>



## v1.12.2 (20220718)

### Feature

- Support `arm/v6` platform by using multistage build (close [#56](https://github.com/ttionya/vaultwarden-backup/issues/56))

<br>



## v1.12.1 (20220711)

### Feature

- Support `arm/v6` platform (close [#56](https://github.com/ttionya/vaultwarden-backup/issues/56))
- Update Dockerfile base image to `rclone/rclone:1.59.0`

### Chore

- Add GitHub Actions dependabot
- Update GitHub Actions

<br>



## v1.12.0 (20220702)

### Feature

- Support start the container as non-root user (close [#45](https://github.com/ttionya/vaultwarden-backup/issues/45), close [#47](https://github.com/ttionya/vaultwarden-backup/issues/47))
- Cron tool switched from BusyBox `crond` to [`supercronic`](https://github.com/aptible/supercronic)

<br>



## v1.11.1 (20220430)

### Feature

- Update Dockerfile base image to `rclone/rclone:1.58.1`

### Chore

- Add dependabot

<br>



## v1.11.0 (20220321)

### Feature

- Update Dockerfile base image to `rclone/rclone:1.58.0`
- support Rclone global flags (close [#49](https://github.com/ttionya/vaultwarden-backup/issues/49))

<br>



## v1.10.0 (20211231)

### Feature

- Encrypt file/dirname for 7z format

### Fixed

- Fix Mail Test error
- Fix the problem that `MAIL_SMTP_VARIABLES` does not work with `.env` files (fixed [#36](https://github.com/ttionya/vaultwarden-backup/issues/36), fixed [#38](https://github.com/ttionya/vaultwarden-backup/issues/38))

<br>



## v1.9.6 (20211106)

### Feature

- Update Dockerfile base image to `rclone/rclone:1.57.0`
- Display the time of running the backup program

<br>



## v1.9.5 (20211010)

### Feature

- Update Dockerfile base image to `rclone/rclone:1.56.2`

<br>



## v1.9.4 (20210925)

### Fixed

- Fix the wrong rsa_key compressed file name for searching when restoring (fixed [#32](https://github.com/ttionya/vaultwarden-backup/issues/32))

<br>



## v1.9.3 (20210922)

### Feature

- Update Dockerfile base image to `rclone/rclone:1.56.1`

### Chore

- On the 10th, 20th and 30th of every month, republish the Docker image to update the alpine packages

<br>



## v1.9.2 (20210731)

### Feature

- Update Dockerfile base image to `rclone/rclone:1.56.0` (close [#31](https://github.com/ttionya/vaultwarden-backup/issues/31))

<br>



## v1.9.1 (20210609)

### Feature

- Increase the number of ping retries and timeout time

<br>



## v1.9.0 (20210608)

### Feature

- Support for pinging, such as healthchecks.io (close [#30](https://github.com/ttionya/vaultwarden-backup/issues/30))

### Chore

- Don't support linux/386 platform anymore because vaultwarden not support it

<br>



## v1.8.1 (20210512)

### Feature

- Update the `docker-compose.yml` file to use the new docker image
- Add Rclone configuration verification (fixed [#29](https://github.com/ttionya/vaultwarden-backup/issues/29))

<br>



## v1.8.0 (20210506)

**Reminder**: If you are still using the `ttionya/bitwardenrs-backup` Docker images, you need to migrate to the new `ttionya/vaultwarden-backup` image.

### Feature

- Rename the Docker image to `vaultwarden-backup`

### Chore

- Build both `bitwardenrs-backup` and `vaultwarden-backup` Docker images

<br>



## before v1.8.0

outdated.
