# 手动触发备份

有时需要手动触发备份操作。

当你使用其他程序来定时调度任务，或想验证环境变量是否正确配置时，这个功能会很有用。

如果你的容器已经运行（容器名为 `vaultwarden_backup`），并且你想执行一次临时备份，可以使用命令 `docker exec vaultwarden_backup bash /app/backup.sh`。

<br>



## 使用方法

以前执行一次立即备份需要覆盖镜像的 entrypoint。现在有了新的方式，你可以直接使用一个无参数的命令来执行备份。

```shell
docker run \
  --rm \
  --name vaultwarden_backup \
  --volumes-from=vaultwarden \
  --mount type=volume,source=vaultwarden-rclone-data,target=/config/ \
  -e ... \
  ttionya/vaultwarden-backup:latest backup
```

你同样需要挂载 rclone 配置文件并设置环境变量。

唯一的区别是环境变量 `CRON` 不会生效，因为它不会启动 CRON 程序，而是在备份完成后退出容器。

<br>



## 重要

**手动触发备份只能验证环境变量是否配置正确，不能验证 CRON 是否正常工作。这是一个 CRON 在 ARM 设备上可能无法正常工作的 [issue](https://github.com/ttionya/vaultwarden-backup/issues/53)。**
