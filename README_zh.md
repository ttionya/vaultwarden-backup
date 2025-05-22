# vaultwarden backup

[![Docker Image Version (latest by date)](https://img.shields.io/docker/v/ttionya/vaultwarden-backup?label=Version&logo=docker)](https://hub.docker.com/r/ttionya/vaultwarden-backup/tags) [![Docker Pulls](https://img.shields.io/docker/pulls/ttionya/vaultwarden-backup?label=Docker%20Pulls&logo=docker)](https://hub.docker.com/r/ttionya/vaultwarden-backup) [![GitHub](https://img.shields.io/github/license/ttionya/vaultwarden-backup?label=License&logo=github)](https://github.com/ttionya/vaultwarden-backup/blob/master/LICENSE)

[README](README.md) | 中文文档

备份 [vaultwarden](https://github.com/dani-garcia/vaultwarden) (之前叫 `bitwarden_rs`) 数据并通过 [Rclone](https://rclone.org/) 同步到其他存储系统。

- [Docker Hub](https://hub.docker.com/r/ttionya/vaultwarden-backup)
- [GitHub Packages](https://github.com/ttionya/vaultwarden-backup/pkgs/container/vaultwarden-backup)
- [GitHub](https://github.com/ttionya/vaultwarden-backup)

<br>



## 功能

本工具会备份以下文件或目录。

- `db.sqlite3` (SQLite 数据库)
- `db.dump` (PostgreSQL 数据库)
- `db.sql` (MySQL / MariaDB 数据库)
- `config.json`
- `rsa_key*` (多个文件)
- `attachments` (目录)
- `sends` (目录)

并且支持以下通知备份结果的方式。

- Ping (完成，开始，成功或失败时发送)
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

##### -f / --force-restore

强制还原，没有交互式确认。请谨慎使用！！

<details>
<summary><strong>※ 你有一个名为 <code>backup</code> 的压缩文件</strong></summary>

##### --zip-file \<file>

你需要使用这个选项来指定 `backup` 压缩文件。

请确保压缩文件中的文件名没有被更改。

##### -p / --password

**这是不安全的！！**

如果 `backup` 压缩文件设置了密码，你可以用这个选项指定备份文件的密码。

不建议使用该选项，因为在没有使用该选项且存在密码时，程序会交互式地询问密码。

</details>

<details>
<summary><strong>※ 你有多个独立的备份文件</strong></summary>

##### --db-file \<file>

你需要用这个选项来指定 `db.*` 文件。

##### --config-file \<file>

你需要用这个选项来指定 `config.json` 文件。

##### --rsakey-file \<file>

你需要用这个选项来指定 `rsakey.tar` 文件。

##### --attachments-file \<file>

你需要用这个选项来指定 `attachments.tar` 文件。

##### --sends-file \<file>

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

#### BACKUP_FILE_SUFFIX

每个备份文件都默认添加 `%Y%m%d` 后缀。如果你在一天内多次进行备份，每次备份都会被覆盖之前同名的文件。这个环境变量允许你自定义日期信息以便每次备份生成不同的文件。

你可以使用除了 `/` 外的任何字符，无法使用的原因是 Linux 不能使用 `/` 作为文件名。

这个环境变量合并了 [`BACKUP_FILE_DATE`](#backup_file_date) 和 [`BACKUP_FILE_DATE_SUFFIX`](#backup_file_date_suffix) 的功能，并且优先级更高。现在你可以直接通过它控制备份文件后缀。

在 [这里](https://man7.org/linux/man-pages/man1/date.1.html) 查看时间格式化说明。

默认值：`%Y%m%d`

#### TIMEZONE

设置你的时区名称。

在 [wikipedia](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones) 查看所有时区名称。（PS: 北京时区TIMEZONE设置为Asia/Shanghai）

默认值：`UTC`

#### DISPLAY_NAME

用于在通知和日志中标识 vaultwarden 实例的自定义名称。

这不会影响功能，仅影响通知标题和部分日志输出中的显示。

默认值：`vaultwarden`

#### DATA_DIR

指定存放 vaultwarden 数据的目录。

当使用 `Docker Compose` 时，你一般不需要修改它，但是当你使用自动备份时，你通常需要将它修改为 `/data`。

默认值：`/bitwarden/data`

<strong>※ 通知相关环境变量请查看[通知](#通知)部分。</strong>

<details>
<summary><strong>※ 其他环境变量</strong></summary>

> **你无需修改这些环境变量，除非你知道你在做什么。**

#### BACKUP_FILE_DATE

你应该使用 [`BACKUP_FILE_SUFFIX`](#backup_file_suffix) 环境变量替代。

只有在你确定想修改备份文件的时间前缀（如 20220101）时编辑该环境变量。**错误的配置可能导致备份文件被错误的覆盖。**

规则同 [`BACKUP_FILE_DATE_SUFFIX`](#backup_file_date_suffix)。

Default: `%Y%m%d`

#### BACKUP_FILE_DATE_SUFFIX

你应该使用 [`BACKUP_FILE_SUFFIX`](#backup_file_suffix) 环境变量替代。

每个备份文件都默认添加 `%Y%m%d` 后缀。如果你在一天内多次进行备份，每次备份都会被覆盖之前同名的文件。这个环境变量允许你追加日期信息 (`%Y%m%d${BACKUP_FILE_DATE_SUFFIX}`) 以便每次备份生成不同的文件。

注意：只支持数字、大小写字母、`-`、`_` 和 `%`。

在 [这里](https://man7.org/linux/man-pages/man1/date.1.html) 查看时间格式化说明。

默认值：`''`

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



## 通知

### Ping

我们提供了在备份完成、开始、成功、失败时发送通知的功能。

**搭配 [healthcheck.io](https://healthchecks.io/) 地址或者其他类似的 cron 监控地址是一个不错的选择，这也是我们推荐的。** 对于一些更复杂的通知场景，你可以使用 `_CURL_OPTIONS` 后缀的环境变量来设置 curl 选项。比如你可以添加请求头，改变请求方法等。

对于不同的通知场景，**备份工具提供了 `%{subject}` 和 `%{content}` 占位符用于替换实际的标题和内容**，你可以在以下环境变量中随意使用它们。请注意，标题和内容可能包含空格。对于包含 `_CURL_OPTIONS` 的四个环境变量，将直接替换占位符，保留空格。对于其他 `PING_URL` 环境变量，空格将被替换为 `+`，以符合 URL 规则。

| 环境变量                               | 触发状态        | 测试标识         | 描述                                      |
|------------------------------------|-------------|--------------|-----------------------------------------|
| PING_URL                           | 完成（不论成功或失败） | `completion` | 备份完成后发送请求的地址                            |
| PING_URL_CURL_OPTIONS              |             |  | 与 `PING_URL` 搭配使用的 curl 选项              |
| PING_URL_WHEN_START                | 开始          | `start` | 备份开始时发送请求的地址                            |
| PING_URL_WHEN_START_CURL_OPTIONS   |             |  | 与 `PING_URL_WHEN_START` 搭配使用的 curl 选项   |
| PING_URL_WHEN_SUCCESS              | 成功          | `success` | 备份成功后发送请求的地址                            |
| PING_URL_WHEN_SUCCESS_CURL_OPTIONS |             |  | 与 `PING_URL_WHEN_SUCCESS` 搭配使用的 curl 选项 |
| PING_URL_WHEN_FAILURE              | 失败          | `failure` | 备份失败后发送请求的地址                            |
| PING_URL_WHEN_FAILURE_CURL_OPTIONS |             |  | 与 `PING_URL_WHEN_FAILURE` 搭配使用的 curl 选项 |

<br>



### Ping 发送测试

你可以使用下面的命令测试 Ping 发送功能。

“test identifier”是[上一节](#ping)表格中的测试标识，你可以使用 `completion`、`start`、`success` 或 `failure`，它决定了使用哪一组环境变量。

```shell
docker run --rm -it \
  -e PING_URL='<your ping url>' \
  -e PING_URL_CURL_OPTIONS='<your curl options for PING_URL>' \
  -e PING_URL_WHEN_START='<your ping url>' \
  -e PING_URL_WHEN_START_CURL_OPTIONS='<your curl options for PING_URL_WHEN_START>' \
  -e PING_URL_WHEN_SUCCESS='<your ping url>' \
  -e PING_URL_WHEN_SUCCESS_CURL_OPTIONS='<your curl options for PING_URL_WHEN_SUCCESS>' \
  -e PING_URL_WHEN_FAILURE='<your ping url>' \
  -e PING_URL_WHEN_FAILURE_CURL_OPTIONS='<your curl options for PING_URL_WHEN_FAILURE>' \
  ttionya/vaultwarden-backup:latest ping <test identifier>
```

<br>



### Mail

从 v1.19.0 开始，本工具使用 [`s-nail`](https://www.sdaoden.eu/code-nail.html) 代替 [`heirloom-mailx`](https://www.systutorials.com/docs/linux/man/1-heirloom-mailx/) 发送邮件。

请注意，`heirloom-mailx` 是 `s-nail` 的存根，它们大部分功能是兼容的。因此你可能不需要为这个改变修改任何环境变量。

| 环境变量 | 默认值    | 描述        |
| --- |--------|-----------|
| MAIL_SMTP_ENABLE | `FALSE` | 启用邮件发送功能  |
| MAIL_SMTP_VARIABLES |        | 邮件发送参数    |
| MAIL_TO |        | 接收邮件的地址   |
| MAIL_WHEN_SUCCESS | `TRUE` | 备份成功后发送邮件 |
| MAIL_WHEN_FAILURE | `TRUE` | 备份失败后发送邮件 |

对于 `MAIL_SMTP_VARIABLES`，你需要自行配置邮件发送参数。**我们会根据使用场景设置邮件主题，所以你不应该使用 `-s` 标志。**

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

控制台有警告？查看 [issue #177](https://github.com/ttionya/vaultwarden-backup/issues/117#issuecomment-1691443179) 了解更多。

<br>



### 邮件发送测试

你可以使用下面的命令测试邮件发送功能。我们会增加 `-v` 标志以显示详细信息，你无需在 `MAIL_SMTP_VARIABLES` 中重复设置。

```shell
docker run --rm -it -e MAIL_SMTP_VARIABLES='<your smtp variables>' ttionya/vaultwarden-backup:latest mail <mail send to>

# Or

docker run --rm -it -e MAIL_SMTP_VARIABLES='<your smtp variables>' -e MAIL_TO='<mail send to>' ttionya/vaultwarden-backup:latest mail
```

<br>



## 环境变量注意事项

### 使用 `.env` 文件

如果你喜欢使用 env 文件而不是环境变量，可以将包含环境变量的 env 文件映射到容器中的 `/.env` 文件。

```shell
docker run -d \
  --mount type=bind,source=/path/to/env,target=/.env \
  ttionya/vaultwarden-backup:latest
```

请不要直接使用 `--env-file` 标志，务必通过挂载文件的方式映射环境变量。`--env-file` 标志会错误地处理引号，导致发生意外情况。更多信息请参见 [docker/cli#3630](https://github.com/docker/cli/issues/3630)。

<br>



### Docker Secrets

作为通过环境变量传递敏感信息的替代方法，可以在前面列出的环境变量后面追加 `_FILE`，使初始化脚本从容器中存在的文件加载这些变量的值。特别是这可以用来从存储在 `/run/secrets/<secret_name>` 文件中的 Docker Secrets 中加载密码。

```shell
docker run -d \
  -e ZIP_PASSWORD_FILE=/run/secrets/zip-password \
  ttionya/vaultwarden-backup:latest
```

<br>



### 关于优先级

我们按以下顺序查找环境变量： 

1. 直接读取环境变量的值
2. 读取以 `_FILE` 结尾的环境变量指向的文件的内容
3. 读取 `.env` 文件中以 `_FILE` 结尾的环境变量指向的文件的内容
4. 读取 `.env` 文件中环境变量的值

示例：

```txt
# 对于 1
MY_ENV="example1"

# 对于 2
MY_ENV_FILE="/path/to/example2"

# 对于 3 (.env 文件)
MY_ENV_FILE="/path/to/example3" 

# 对于 4 (.env 文件)
MY_ENV="example4"
```

<br>



## 迁移

**用 Rust 编写的非官方 Bitwarden 服务器，以前称为 `bitwarden_rs`，已经改名为 `vaultwarden`。所以这个备份工具也由 `bitwardenrs-backup` 重命名为 `vaultwarden-backup`。**

旧的镜像仍然可以使用，只是被标记为 **DEPRECATED** 了，请尽快迁移到新的镜像。

**迁移说明**

如果你使用自动备份，你只需要把镜像名改为 `ttionya/vaultwarden-backup`。注意你的卷的名称。

如果你使用 `docker-compose`，你需要将 `bitwardenrs/server` 更新为 `vaultwarden/server`，`ttionya/bitwardenrs-backup` 更新为 `ttionya/vaultwarden-backup`。

我们建议重新下载 [`docker-compose.yml`](./docker-compose.yml) 文件，更新你的环境变量，并注意 `volumes` 部分，你可能需要修改它。

<br>



## 高级

- [以非 root 用户运行](docs/run-as-non-root-user.md)
- [备份到多个远程目标](docs/multiple-remote-destinations.md)
- [手动触发备份](docs/manually-trigger-a-backup.md)
- [使用 PostgreSQL 数据库](docs/using-the-postgresql-backend.md)
- [使用 MySQL(MariaDB) 数据库](docs/using-the-mysql-or-mariadb-backend.md)

<br>



## 更新日志

请查看 [CHANGELOG](CHANGELOG.md) 文件。

<br>



## 感谢

感谢 [JetBrains](https://www.jetbrains.com/) 提供的 OSS 许可证。

<a href="https://jb.gg/OpenSource" target="_blank"><img src="https://resources.jetbrains.com/storage/products/company/brand/logos/jetbrains.svg" alt="JetBrains logo."></a>

<br>



## 许可证

MIT
