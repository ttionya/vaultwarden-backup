# 以非 root 用户运行

默认情况下，容器以 root 用户运行备份脚本。如果你希望以非 root 用户运行容器，需要设置一些内容。

你可以使用内置的非 root 用户和用户组，名称为 `backuptool`，UID 和 GID 均为 `1100`。

<br>



## 备份

1. 确保挂载的 `vaultwarden-rclone-data` 卷中的 rclone 配置文件对 `backuptool` 用户可写。

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

2. 如果你想要完整备份 `rsa_key*`，需要允许 `backuptool` 用户读取 `rsa_key*`。

**使用 Docker Compose 时**

```shell
# enter the container
docker run --rm -it \
  --mount type=volume,source=vaultwarden-data,target=/bitwarden/data/ \
  --entrypoint=bash \
  ttionya/vaultwarden-backup:latest

# make files readable for all users in the container
chmod -R +r /bitwarden/data/

# exit the container
exit
```

**使用自动备份时**

```shell
# enter the container
docker run --rm -it \
  --volumes-from=vaultwarden \
  --entrypoint=bash \
  ttionya/vaultwarden-backup:latest

# make files readable for all users in the container
chmod -R +r /data/

# exit the container
exit
```

3. 使用正确的参数启动容器。

**使用 Docker Compose 时**

```shell
# docker-compose.yml
services:
  backup:
    image: ttionya/vaultwarden-backup:latest
    user: 'backuptool:backuptool'
    ...
```

**使用自动备份时**

```shell
docker run -d \
  ...
  --user backuptool:backuptool \
  ...
  ttionya/vaultwarden-backup:latest
```

<br>



## 还原

正常执行还原即可，没有什么特别的。
