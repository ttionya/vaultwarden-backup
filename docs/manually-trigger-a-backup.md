# Manually trigger a backup

Sometimes, it's necessary to manually trigger backup actions.

This can be useful when other programs are used to consistently schedule tasks or to verify that environment variables are properly configured.

If your container is already running (with the container name `vaultwarden-backup`) and you want to execute an adhoc backup you can do so with the command `docker exec vaultwarden-backup bash /app/backup.sh`. 

<br>



## Usage

Previously, performing an immediate backup required overwriting the entrypoint of the image. However, with the new setup, you can perform a backup directly with a parameterless command.

```shell
docker run \
  --rm \
  --name vaultwarden-backup \
  --volumes-from=vaultwarden \
  --mount type=volume,source=vaultwarden-rclone-data,target=/config/ \
  -e ... \
  ttionya/vaultwarden-backup:latest backup
```

You also need to mount the rclone config file and set the environment variables.

The only difference is that the environment variable `CRON` does not work because it does not start the CRON program, but exits the container after the backup is done.

<br>



## IMPORTANT

**Manually triggering a backup only verifies that the environment variables are configured correctly, not that CRON is working properly. This is the [issue](https://github.com/ttionya/vaultwarden-backup/issues/53) that CRON may not work properly on ARM devices.**

