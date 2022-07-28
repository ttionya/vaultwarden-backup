# Changelog

## v1.13.0

### Feature

- Support force restore without asking for confirmation

<br>



## v1.12.2

### Feature

- Support `arm/v6` platform by using multistage build (close [#56](https://github.com/ttionya/vaultwarden-backup/issues/56))

<br>



## v1.12.1

### Feature

- Support `arm/v6` platform (close [#56](https://github.com/ttionya/vaultwarden-backup/issues/56))

### Chore

- Add GitHub Actions dependabot
- Update GitHub Actions

<br>



## v1.12.0

### Feature

- Support start the container as non-root user (close [#45](https://github.com/ttionya/vaultwarden-backup/issues/45), close [#47](https://github.com/ttionya/vaultwarden-backup/issues/47))
- Cron tool switched from BusyBox `crond` to [`supercronic`](https://github.com/aptible/supercronic)

<br>



## v1.11.1

### Feature

- Update Dockerfile base image to `rclone/rclone:1.58.1`

### Chore

- Add dependabot

<br>



## v1.11.0

### Feature

- Update Dockerfile base image to `rclone/rclone:1.58.0`
- support Rclone global flags (close [#49](https://github.com/ttionya/vaultwarden-backup/issues/49))

<br>



## v1.10.0

### Feature

- Encrypt file/dirname for 7z format

### Fixed

- Fix Mail Test error
- Fix the problem that `MAIL_SMTP_VARIABLES` does not work with `.env` files (fixed [#36](https://github.com/ttionya/vaultwarden-backup/issues/36), fixed [#38](https://github.com/ttionya/vaultwarden-backup/issues/38))

<br>



## v1.9.6

### Feature

- Update Dockerfile base image to `rclone/rclone:1.57.0`
- Display the time of running the backup program

<br>



## v1.9.5

### Feature

- Update Dockerfile base image to `rclone/rclone:1.56.2`

<br>



## v1.9.4

### Fixed

- Fix the wrong rsa_key compressed file name for searching when restoring (fixed [#32](https://github.com/ttionya/vaultwarden-backup/issues/32))

<br>



## v1.9.3

### Feature

- Update Dockerfile base image to `rclone/rclone:1.56.1`

### Chore

- On the 10th, 20th and 30th of every month, republish the Docker image to update the alpine packages

<br>



## v1.9.2

### Feature

- Update Dockerfile base image to `rclone/rclone:1.56.0` (close [#31](https://github.com/ttionya/vaultwarden-backup/issues/31))

<br>



## v1.9.1

### Feature

- Increase the number of ping retries and timeout time

<br>



## v1.9.0

### Feature

- Support for pinging, such as healthchecks.io (close [#30](https://github.com/ttionya/vaultwarden-backup/issues/30))

### Chore

- Don't support linux/386 platform anymore because vaultwarden not support it

<br>



## v1.8.1

### Feature

- Update the `docker-compose.yml` file to use the new docker image
- Add Rclone configuration verification (fixed [#29](https://github.com/ttionya/vaultwarden-backup/issues/29))

<br>



## v1.8.0

**Reminder**: If you are still using the `ttionya/bitwardenrs-backup` Docker images, you need to migrate to the new `ttionya/vaultwarden-backup` image.

### Feature

- Rename the Docker image to `vaultwarden-backup`

### Chore

- Build both `bitwardenrs-backup` and `vaultwarden-backup` Docker images

<br>



## before v1.8.0

outdated.
