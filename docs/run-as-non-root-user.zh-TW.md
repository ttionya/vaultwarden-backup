# 以非 root 使用者執行

預設情況下，容器以 root 使用者執行備份指令碼。如果你希望以非 root 使用者執行容器，需要設定一些內容。

你可以使用內建的非 root 使用者和群組，名稱為 `backuptool`，UID 和 GID 均為 `1100`。

<br>



## 備份

1. 確保掛載的 `vaultwarden-rclone-data` 卷中的 rclone 設定檔對 `backuptool` 使用者可寫。

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

2. 如果你想要完整備份 `rsa_key*`，需要允許 `backuptool` 使用者讀取 `rsa_key*`。

**使用 Docker Compose 時**

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

**使用自動備份時**

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

3. 使用正確的參數啟動容器。

**使用 Docker Compose 時**

```shell
# docker-compose.yml
services:
  backup:
    image: ttionya/vaultwarden-backup:latest
    user: 'backuptool:backuptool'
    ...
```

**使用自動備份時**

```shell
docker run -d \
  ...
  --user backuptool:backuptool \
  ...
  ttionya/vaultwarden-backup:latest
```

<br>



## 還原

正常執行還原即可，沒有什麼特別的。
