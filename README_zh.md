# vaultwarden backup

[![Docker Image Version (latest by date)](https://img.shields.io/docker/v/ttionya/vaultwarden-backup?label=Version&logo=docker)](https://hub.docker.com/r/ttionya/vaultwarden-backup/tags) [![Docker Pulls](https://img.shields.io/docker/pulls/ttionya/vaultwarden-backup?label=Docker%20Pulls&logo=docker)](https://hub.docker.com/r/ttionya/vaultwarden-backup) [![GitHub](https://img.shields.io/github/license/ttionya/vaultwarden-backup?label=License&logo=github)](https://github.com/ttionya/vaultwarden-backup/blob/master/LICENSE)

[README](README.md) | 中文文档

备份 [vaultwarden](https://github.com/dani-garcia/vaultwarden) (之前叫 `bitwarden_rs`) 数据并通过 [Rclone](https://rclone.org/) 同步到其他存储系统。

- [Docker Hub](https://hub.docker.com/r/ttionya/vaultwarden-backup)
- [GitHub](https://github.com/ttionya/vaultwarden-backup)

<br>



## 重命名

**用 Rust 编写的非官方 Bitwarden 服务器，以前称为 `bitwarden_rs`，现在已经改名为 `vaultwarden`。**

所以这个备份工具迁移到了 [ttionya/vaultwarden-backup](https://github.com/ttionya/vaultwarden-backup) 。

旧的镜像仍然可以使用，只是 **DEPRECATED** 了。建议迁移到新的镜像 [ttionya/vaultwarden-backup](https://hub.docker.com/r/ttionya/vaultwarden-backup) 。

**请在[这里](#迁移)查看如何迁移**。

<br>



## 功能

本工具会备份以下文件或目录。

- `db.sqlite3`
- `config.json`
- `rsa_key*` (多个文件)
- `attachments` (目录)
- `sends` (目录)

并且支持以下通知备份结果的方式。

- Ping (仅成功时发送)
- Mail (基于 SMTP，成功时和失败时都会发送)

<br>



## 使用方法

> **重要：** 我们假设你已经完整阅读了 `vaultwarden` [文档](https://github.com/dani-garcia/vaultwarden/wiki) 。

### 配置 Rclone (⚠️ 必读 ⚠️)

> **对于备份，你需要先配置 Rclone，否则备份工具不会工作。**
> 
> **对于还原，它不是必要的。**

我们通过 [Rclone](https://rclone.org/) 同步备份文件到远程存储系统。

访问 [GitHub](https://github.com/rclone/rclone) 了解更多存储系统使用教程，不同的系统获得 Token 的方式不同。

#### 配置和检查

你可以通过下面的命令获得 Token。

```shell
docker run --rm -it \
  --mount type=volume,source=vaultwarden-rclone-data,target=/config/ \
  ttionya/vaultwarden-backup:latest \
  rclone config
```

**我们建议将远程名称设置为 `BitwardenBackup`，否则你需要指定环境变量 `RCLONE_REMOTE_NAME` 为你设置的远程名称。**

完成设置后，可以通过以下命令检查配置情况。

```shell
docker run --rm -it \
  --mount type=volume,source=vaultwarden-rclone-data,target=/config/ \
  ttionya/vaultwarden-backup:latest \
  rclone config show

# Microsoft Onedrive Example
# [BitwardenBackup]
# type = onedrive
# token = {"access_token":"access token","token_type":"token type","refresh_token":"refresh token","expiry":"expiry time"}
# drive_id = driveid
# drive_type = personal
```

<br>



### 备份

#### 使用 Docker Compose (推荐)

如果你是新用户或正在重新搭建 vaultwarden，推荐使用项目中的 `docker-compose.yml`.

下载 `docker-compose.yml`，根据实际情况编辑环境变量后启动它。

你需要进入 `docker-compose.yml` 文件所在目录执行操作。

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

#### 自动备份

如果你有一个正在运行的 vaultwarden，但是不想使用 `docker-compose.yml`，我们同样为你提供了备份方法。

确保你的 vaultwarden 容器被命名为 `vaultwarden`，否则你需要自行替换 docker run 的 `--volumes-from` 部分。

默认情况下 vaultwarden 的数据文件夹是 `/data`，你需要显式使用环境变量 `DATA_DIR` 指定数据文件夹。

使用默认设置启动容器（每小时的 05 分自动备份）。

```shell
docker run -d \
  --restart=always \
  --name vaultwarden_backup \
  --volumes-from=vaultwarden \
  --mount type=volume,source=vaultwarden-rclone-data,target=/config/ \
  -e DATA_DIR="/data" \
  ttionya/vaultwarden-backup:latest
```

<br>



### 还原备份

> **重要：** 还原备份会覆盖已存在的文件。

你需要在还原备份前停止 Docker 容器。

你也需要下载备份文件到本地计算机。

因为主机的文件无法在 Docker 容器中直接访问，所以要将需要还原的备份文件所在目录映射到 Docker 容器中。

**首先进入待还原的备份文件所在目录。**

如果你使用的是本项目提供的 `docker-compose.yml`，你可以执行下面的命令。

```shell
docker run --rm -it \
  --mount type=volume,source=vaultwarden-data,target=/bitwarden/data/ \
  --mount type=bind,source=$(pwd),target=/bitwarden/restore/ \
  ttionya/vaultwarden-backup:latest restore \
  [OPTIONS]
```

如果你使用的是“自动备份”，请确认 vaultwarden 卷的命名，并替换 `--mount` `source` 部分。

同时不要忘记使用环境变量 `DATA_DIR` 指定数据目录（`-e DATA_DIR="/data"`）。

```shell
docker run --rm -it \
  \ # 如果你将本地目录映射到 Docker 容器中，就像 `vw-data` 一样
  --mount type=bind,source="本地目录的绝对路径",target=/data/ \
  \ # 如果你使用 Docker 卷
  --mount type=volume,source="Docker 卷名称",target=/data/ \
  --mount type=bind,source=$(pwd),target=/bitwarden/restore/ \
  -e DATA_DIR="/data" \
  ttionya/vaultwarden-backup:latest restore \
  [OPTIONS]
```

选项已在下面列出。

#### 选项

<details>
<summary><strong>※ 你有一个名为 <code>backup</code> 的压缩文件</strong></summary>

##### --zip-file

你需要使用这个选项来指定 `backup` 压缩文件。

请确保压缩文件中的文件名没有被更改。

##### -p / --password

**这是不安全的！！**

如果 `backup` 压缩文件设置了密码，你可以用这个选项指定备份文件的密码。

不建议使用该选项，因为在没有使用该选项且存在密码时，程序会交互式地询问密码。

</details>

<details>
<summary><strong>※ 你有多个独立的备份文件</strong></summary>

##### --db-file

你需要用这个选项来指定 `db.sqlite3` 文件。

##### --config-file

你需要用这个选项来指定 `config.json` 文件。

##### --rsakey-file

你需要用这个选项来指定 `rsakey.tar` 文件。

##### --attachments-file

你需要用这个选项来指定 `attachments.tar` 文件。

##### --sends-file

你需要用这个选项来指定 `sends.tar` 文件。

</details>

<br>



## 环境变量

> **注意：** 所有的环境变量都有默认值，你可以在不设置任何环境变量的情况下使用 Docker 镜像。

#### RCLONE_REMOTE_NAME

Rclone 远程名称，它需要和 rclone config 中的远程名称保持一致。

你可以通过以下命令查看当前远程名称。

```shell
docker run --rm -it \
  --mount type=volume,source=vaultwarden-rclone-data,target=/config/ \
  ttionya/vaultwarden-backup:latest \
  rclone config show

# [BitwardenBackup] <- 就是它
# ...
```

默认值：`BitwardenBackup`

#### RCLONE_REMOTE_DIR

远程存储系统中存放备份文件的文件夹路径。

默认值：`/BitwardenBackup/`

#### RCLONE_GLOBAL_FLAG

Rclone 全局参数，详见 [flags](https://rclone.org/flags/)。

**不要添加会改变输出的全局参数，比如 `-P`，它会影响删除过期备份文件的操作。**

默认值：`''`

#### CRON

`crond` 的规则，它基于 [`supercronic`](https://github.com/aptible/supercronic)。你可以在 [这里](https://crontab.guru/#5_*_*_*_*) 进行测试。

默认值：`5 * * * *` (每小时的 05 分自动备份)

#### ZIP_ENABLE

将所有备份文件打包为压缩文件。当设置为 `'FALSE'` 时，会单独上传每个备份文件。

默认值：`TRUE`

#### ZIP_PASSWORD

压缩文件的密码。请注意，打包备份文件时始终会使用密码。

默认值：`WHEREISMYPASSWORD?`

#### ZIP_TYPE

因为 `zip` 格式安全性较低，我们为追求安全的人提供 `7z` 格式的存档。

需要说明的是，vaultwarden 的密码在发送到服务器前就已经加密了。服务器没有保存明文密码，所以 `zip` 格式已经可以满足基本的加密需求。

默认值：`zip` (只支持 `zip` 和 `7z` 格式)

#### BACKUP_KEEP_DAYS

在远程存储系统中保留最近 X 天的备份文件。设置为 `0` 会保留所有备份文件。

默认值：`0`

#### BACKUP_FILE_DATE_SUFFIX

每个备份文件都默认添加 `%Y%m%d` 后缀。如果你在一天内多次进行备份，每次备份都会被覆盖之前同名的文件。这个环境变量允许你追加日期信息 (`%Y%m%d${BACKUP_FILE_DATE_SUFFIX}`) 以便每次备份生成不同的文件。

注意：只支持数字、大小写字母、`-`、`_` 和 `%`。

在 [这里](https://man7.org/linux/man-pages/man1/date.1.html) 查看时间格式化说明。

默认值：`''`

#### TIMEZONE

设置合法的时区名称。

[这里](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones) 可以查看所有合法的时区名称。

默认值：`UTC`

#### PING_URL

使用 [healthcheck.io](https://healthchecks.io/) 地址或者其他类似的 cron 监控，以便在备份**成功**后执行 `GET` 请求。

#### MAIL_SMTP_ENABLE

本工具使用 [heirloom-mailx](https://www.systutorials.com/docs/linux/man/1-heirloom-mailx/) 发送邮件。

默认值：`FALSE`

#### MAIL_SMTP_VARIABLES

因为发送邮件的配置太复杂，请自己配置邮件发送参数。

**我们会根据使用场景设置邮件主题，所以你不应该使用 `-s` 选项。**

在测试时，我们将增加 `-v` 选项来显示详细信息。

```text
# 提供一个能正常使用的例子：

# For Zoho
-S smtp-use-starttls \
-S smtp=smtp://smtp.zoho.com:587 \
-S smtp-auth=login \
-S smtp-auth-user=<my-email-address> \
-S smtp-auth-password=<my-email-password> \
-S from=<my-email-address>
```

[这里](https://www.systutorials.com/sending-email-from-mailx-command-in-linux-using-gmails-smtp/) 能查看更多配置说明。

#### MAIL_TO

设置会收到通知邮件的邮箱。

#### MAIL_WHEN_SUCCESS

备份成功后发送邮件。

默认值：`TRUE`

#### MAIL_WHEN_FAILURE

备份失败时发送邮件。

默认值：`TRUE`

#### DATA_DIR

指定存放 vaultwarden 数据的目录。

当使用 `Docker Compose` 时，你一般不需要修改它，但是当你使用自动备份时，你通常需要将它修改为 `/data`。

默认值：`/bitwarden/data`

<details>
<summary><strong>※ 其他环境变量</strong></summary>

> **你无需修改这些环境变量，除非你知道你在做什么。**

#### DATA_DB

指定 sqlite 数据库文件的路径。

默认值：`${DATA_DIR}/db.sqlite3`

#### DATA_RSAKEY

指定 rsa_key 文件的路径。

默认值：`${DATA_DIR}/rsa_key`

#### DATA_ATTACHMENTS

指定 attachments 文件夹路径。

默认值：`${DATA_DIR}/attachments`

#### DATA_SENDS

指定 sends 文件夹路径。

默认值：`${DATA_DIR}/sends`

</details>

<br>



## Use `.env` file

如果你喜欢使用 env 文件而不是环境变量，可以将包含环境变量的 env 文件映射到容器中的 `/.env` 文件。

```shell
docker run -d \
  --mount type=bind,source=/path/to/env,target=/.env \
  ttionya/vaultwarden-backup:latest
```

<br>



## Docker Secrets

作为通过环境变量传递敏感信息的替代方法，`_FILE` 可以追加到前面列出的环境变量后面，使初始化脚本从容器中存在的文件加载这些变量的值。特别是这可以用来从存储在 `/run/secrets/<secret_name>` 文件中的 Docker Secrets 中加载密码。

```shell
docker run -d \
  -e ZIP_PASSWORD_FILE=/run/secrets/zip-password \
  ttionya/vaultwarden-backup:latest
```

<br>



## 关于优先级

我们会优先使用环境变量，然后是环境变量定义的 `_FILE` 结尾的文件内容，之后是 `.env` 文件中定义的 `_FILE` 结尾的文件内容，最后才是 `.env` 文件的值。

<br>



## 邮件发送测试

你可以使用下面的命令来测试邮件的发送。记得替换你的 SMTP 变量。

```shell
docker run --rm -it -e MAIL_SMTP_VARIABLES='<your smtp variables>' ttionya/vaultwarden-backup:latest mail <mail send to>

# Or

docker run --rm -it -e MAIL_SMTP_VARIABLES='<your smtp variables>' -e MAIL_TO='<mail send to>' ttionya/vaultwarden-backup:latest mail
```

<br>



## 迁移

如果你使用自动备份，你只需要把镜像名改为 `ttionya/vaultwarden-backup`。注意你的卷的名称。

如果你使用 `docker-compose`，你需要将 `bitwardenrs/server` 更新为 `vaultwarden/server`，`ttionya/bitwardenrs-backup` 更新为 `ttionya/vaultwarden-backup`。

我们建议重新下载 `docker-compose.yml` 文件，替换你的环境变量，并注意 `volumes` 一节，你可能需要改变它。

<br>



## 更新日志

请查看 [CHANGELOG](CHANGELOG.md) 文件。

<br>



## 许可证

MIT
