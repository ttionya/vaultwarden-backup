# Run as non-root user

By default the container runs the backup script as root user. There are few things you need to set to run the container as non-root user if you wish to do so.

You can use the built-in non-root user and group, named `backuptool`, uid and gid are `1100`.

<br>



## Backup

1. Make sure that the rclone config file in the mounted `vaultwarden-rclone-data` volume is writable by the user.

```shell
# enter the container
docker run --rm -it \
  --mount type=volume,source=vaultwarden-rclone-data,target=/config/ \
  --entrypoint=bash \
  ttionya/vaultwarden-backup:latest

# modify the rclone config file owner in the container
chown -R 1100:1100 /config/

# exit the container
exit
```

2. If you want a full backup of the `rsa_key.*`, you need to allow `backuptool` user to read the `rsa_key.*`.

**With Docker Compose**

```shell
# enter the container
docker run --rm -it \
  --mount type=volume,source=vaultwarden-data,target=/bitwarden/data/ \
  --entrypoint=bash \
  ttionya/vaultwarden-backup:latest

# make files readable for all users
chmod -R +r /bitwarden/data/

# exit the container
exit
```

**With Automatic Backups**

```shell
# enter the container
docker run --rm -it \
  --volumes-from=vaultwarden \
  --entrypoint=bash \
  ttionya/vaultwarden-backup:latest

# make files readable for all users
chmod -R +r /data/

# exit the container
exit
```

3. Start the container with proper parameters.

**With Docker Compose**

```shell
# docker-compose.yml
services:
  backup:
    image: ttionya/vaultwarden-backup:latest
    user: 'backuptool:backuptool'
    ...
```

**With Automatic Backups**

```shell
docker run -d \
  ...
  --user backuptool:backuptool \
  ...
  ttionya/vaultwarden-backup:latest
```

<br>



## Restore

Do the restore normally, nothing special.
