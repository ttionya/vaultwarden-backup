# Changelog

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
