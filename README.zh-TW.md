# vaultwarden backup

[![Docker Image Version (latest by date)](https://img.shields.io/docker/v/ttionya/vaultwarden-backup?label=Version&logo=docker)](https://hub.docker.com/r/ttionya/vaultwarden-backup/tags) [![Docker Pulls](https://img.shields.io/docker/pulls/ttionya/vaultwarden-backup?label=Docker%20Pulls&logo=docker)](https://hub.docker.com/r/ttionya/vaultwarden-backup) [![GitHub](https://img.shields.io/github/license/ttionya/vaultwarden-backup?label=License&logo=github)](https://github.com/ttionya/vaultwarden-backup/blob/master/LICENSE)

[README](README.md) | [简体中文文档](README.zh-CN.md) | 繁體中文文件

備份 [vaultwarden](https://github.com/dani-garcia/vaultwarden) (之前叫 `bitwarden_rs`) 資料並透過 [Rclone](https://rclone.org/) 同步到其他儲存系統。

- [Docker Hub](https://hub.docker.com/r/ttionya/vaultwarden-backup)
- [GitHub Packages](https://github.com/ttionya/vaultwarden-backup/pkgs/container/vaultwarden-backup)
- [GitHub](https://github.com/ttionya/vaultwarden-backup)

<br>



## 功能

本工具會備份以下檔案或目錄。

- `db.sqlite3` (SQLite 資料庫)
- `db.dump` (PostgreSQL 資料庫)
- `db.sql` (MySQL / MariaDB 資料庫)
- `config.json`
- `rsa_key*` (多個檔案)
- `attachments` (目錄)
- `sends` (目錄)

並且支援以下通知備份結果的方式。

- Ping (完成，開始，成功或失敗時傳送)
- Mail (基於 SMTP，成功時和失敗時都會傳送)

<br>



## 使用方法

> **重要：** 我們假設你已經完整閱讀了 `vaultwarden` [文件](https://github.com/dani-garcia/vaultwarden/wiki) 。

### 設定 Rclone (⚠️ 必讀 ⚠️)

> **對於備份，你需要先設定 Rclone，否則備份工具不會運作。**
>
> **對於還原，它不是必要的。**

我們透過 [Rclone](https://rclone.org/) 同步備份檔案到遠端儲存系統。

造訪 [GitHub](https://github.com/rclone/rclone) 了解更多儲存系統使用教學，不同的系統取得 Token 的方式不同。

#### 設定和檢查

你可以透過下面的命令取得 Token。

```shell
docker run --rm -it \
  --mount type=volume,source=vaultwarden-rclone-data,target=/config/ \
  ttionya/vaultwarden-backup:latest \
  rclone config
```

**我們建議將遠端名稱設定為 `BitwardenBackup`，否則你需要指定環境變數 `RCLONE_REMOTE_NAME` 為你設定的遠端名稱。**

完成設定後，可以透過以下命令檢查設定情況。

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



### 備份

#### 使用 Docker Compose (推薦)

如果你是新使用者或正在重新架設 vaultwarden，推薦使用專案中的 `docker-compose.yml`.

下載 `docker-compose.yml`，根據實際情況編輯環境變數後啟動它。

你需要進入 `docker-compose.yml` 檔案所在目錄執行操作。

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

#### 自動備份

如果你有一個正在運作的 vaultwarden，但是不想使用 `docker-compose.yml`，我們同樣為你提供了備份方法。

確保你的 vaultwarden 容器被命名為 `vaultwarden`，否則你需要自行替換 docker run 的 `--volumes-from` 部分。

預設情況下 vaultwarden 的資料資料夾是 `/data`，你需要明確使用環境變數 `DATA_DIR` 指定資料資料夾。

使用預設設定啟動容器（每小時的 05 分自動備份）。

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



### 還原備份

> **重要：** 還原備份會覆寫已存在的檔案。

你需要在還原備份前停止 Docker 容器。

你也需要下載備份檔案到本機電腦。

因為主機的檔案無法在 Docker 容器中直接存取，所以要將需要還原的備份檔案所在目錄對應到 Docker 容器中。

**首先進入待還原的備份檔案所在目錄。**

如果你使用的是本專案提供的 `docker-compose.yml`，你可以執行下面的命令。

```shell
docker run --rm -it \
  --mount type=volume,source=vaultwarden-data,target=/bitwarden/data/ \
  --mount type=bind,source=$(pwd),target=/bitwarden/restore/ \
  ttionya/vaultwarden-backup:latest restore \
  [OPTIONS]
```

如果你使用的是「自動備份」，請確認 vaultwarden 卷的命名，並替換 `--mount` `source` 部分。

同時不要忘記使用環境變數 `DATA_DIR` 指定資料目錄（`-e DATA_DIR="/data"`）。

```shell
docker run --rm -it \
  \ # 如果你是將本機目錄對應到 Docker 容器中，就像 `vw-data` 一樣
  --mount type=bind,source="本機目錄的絕對路徑",target=/data/ \
  \ # 如果你使用 Docker 卷
  --mount type=volume,source="Docker 卷名稱",target=/data/ \
  --mount type=bind,source=$(pwd),target=/bitwarden/restore/ \
  -e DATA_DIR="/data" \
  ttionya/vaultwarden-backup:latest restore \
  [OPTIONS]
```

選項已在下面列出。

#### 選項

##### -f / --force-restore

強制還原，沒有互動式確認。請謹慎使用！！

<details>
<summary><strong>※ 你有一個名為 <code>backup</code> 的壓縮檔案</strong></summary>

##### --zip-file \<file>

你需要使用這個選項來指定 `backup` 壓縮檔案。

請確保壓縮檔案中的檔案名稱沒有被更改。

##### -p / --password

**這是不安全的！！**

如果 `backup` 壓縮檔案設定了密碼，你可以用這個選項指定備份檔案的密碼。

不建議使用該選項，因為在沒有使用該選項且存在密碼時，程式會互動式地詢問密碼。

</details>

<details>
<summary><strong>※ 你有多個獨立的備份檔案</strong></summary>

##### --db-file \<file>

你需要用這個選項來指定 `db.*` 檔案。

##### --config-file \<file>

你需要用這個選項來指定 `config.json` 檔案。

##### --rsakey-file \<file>

你需要用這個選項來指定 `rsakey.tar` 檔案。

##### --attachments-file \<file>

你需要用這個選項來指定 `attachments.tar` 檔案。

##### --sends-file \<file>

你需要用這個選項來指定 `sends.tar` 檔案。

</details>

<br>



## 環境變數

> **注意：** 所有的環境變數都有預設值，你可以在不設定任何環境變數的情況下使用 Docker 映像。

#### RCLONE_REMOTE_NAME

Rclone 遠端名稱，它需要和 rclone config 中的遠端名稱保持一致。

你可以透過以下命令查看目前遠端名稱。

```shell
docker run --rm -it \
  --mount type=volume,source=vaultwarden-rclone-data,target=/config/ \
  ttionya/vaultwarden-backup:latest \
  rclone config show

# [BitwardenBackup] <- 就是它
# ...
```

預設值：`BitwardenBackup`

#### RCLONE_REMOTE_DIR

遠端儲存系統中存放備份檔案的資料夾路徑。

預設值：`/BitwardenBackup/`

#### RCLONE_GLOBAL_FLAG

Rclone 全域參數，詳見 [flags](https://rclone.org/flags/)。

**不要新增會改變輸出的全域參數，比如 `-P`，它會影響刪除過期備份檔案的操作。**

預設值：`''`

#### CRON

`crond` 的規則，它基於 [`supercronic`](https://github.com/aptible/supercronic)。你可以在 [這裡](https://crontab.guru/#5_*_*_*_*) 進行測試。

預設值：`5 * * * *` (每小時的 05 分自動備份)

#### ZIP_ENABLE

將所有備份檔案封裝為壓縮檔案。當設定為 `'FALSE'` 時，會單獨上傳每個備份檔案。

預設值：`TRUE`

#### ZIP_PASSWORD

壓縮檔案的密碼。請注意，封裝備份檔案時始終會使用密碼。

預設值：`WHEREISMYPASSWORD?`

#### ZIP_TYPE

因為 `zip` 格式安全性較低，我們為追求安全的人提供 `7z` 格式的封存。

需要說明的是，vaultwarden 的密碼在傳送到伺服器前就已經加密了。伺服器沒有儲存明文密碼，所以 `zip` 格式已經可以滿足基本的加密需求。

預設值：`zip` (只支援 `zip` 和 `7z` 格式)

#### BACKUP_KEEP_DAYS

在遠端儲存系統中保留最近 X 天的備份檔案。設定為 `0` 會保留所有備份檔案。

預設值：`0`

#### BACKUP_FILE_SUFFIX

每個備份檔案都預設新增 `%Y%m%d` 後綴。如果你在一天內多次進行備份，每次備份都會被覆寫之前同名的檔案。這個環境變數允許你自訂日期資訊以便每次備份產生不同的檔案。

你可以使用除了 `/` 外的任何字元，無法使用的原因是 Linux 不能使用 `/` 作為檔案名稱。

這個環境變數合併了 [`BACKUP_FILE_DATE`](#backup_file_date) 和 [`BACKUP_FILE_DATE_SUFFIX`](#backup_file_date_suffix) 的功能，並且優先順序更高。現在你可以直接透過它控制備份檔案後綴。

在 [這裡](https://man7.org/linux/man-pages/man1/date.1.html) 查看時間格式化說明。

預設值：`%Y%m%d`

#### TIMEZONE

設定你的時區名稱。

在 [wikipedia](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones) 查看所有時區名稱。（PS: 北京時區TIMEZONE設定為Asia/Shanghai）

預設值：`UTC`

#### DISPLAY_NAME

用於在通知和日誌中標識 vaultwarden 實例的自訂名稱。

這不會影響功能，僅影響通知標題和部分日誌輸出中的顯示。

預設值：`vaultwarden`

#### DATA_DIR

指定存放 vaultwarden 資料的目錄。

當使用 `Docker Compose` 時，你一般不需要修改它，但是當你使用自動備份時，你通常需要將它修改為 `/data`。

預設值：`/bitwarden/data`

<strong>※ 通知相關環境變數請查看[通知](#通知)部分。</strong>

<details>
<summary><strong>※ 其他環境變數</strong></summary>

> **你無需修改這些環境變數，除非你知道你在做什麼。**

#### BACKUP_FILE_DATE

你應該使用 [`BACKUP_FILE_SUFFIX`](#backup_file_suffix) 環境變數替代。

只有在你確定想修改備份檔案的時間前綴（如 20220101）時編輯該環境變數。**錯誤的設定可能導致備份檔案被錯誤的覆寫。**

規則同 [`BACKUP_FILE_DATE_SUFFIX`](#backup_file_date_suffix)。

Default: `%Y%m%d`

#### BACKUP_FILE_DATE_SUFFIX

你應該使用 [`BACKUP_FILE_SUFFIX`](#backup_file_suffix) 環境變數替代。

每個備份檔案都預設新增 `%Y%m%d` 後綴。如果你在一天內多次進行備份，每次備份都會被覆寫之前同名的檔案。這個環境變數允許你追加日期資訊 (`%Y%m%d${BACKUP_FILE_DATE_SUFFIX}`) 以便每次備份產生不同的檔案。

注意：只支援數字、大小寫字母、`-`、`_` 和 `%`。

在 [這裡](https://man7.org/linux/man-pages/man1/date.1.html) 查看時間格式化說明。

預設值：`''`

#### DATA_DB

指定 sqlite 資料庫檔案的路徑。

預設值：`${DATA_DIR}/db.sqlite3`

#### DATA_RSAKEY

指定 rsa_key 檔案的路徑。

預設值：`${DATA_DIR}/rsa_key`

#### DATA_ATTACHMENTS

指定 attachments 資料夾路徑。

預設值：`${DATA_DIR}/attachments`

#### DATA_SENDS

指定 sends 資料夾路徑。

預設值：`${DATA_DIR}/sends`

</details>

<br>



## 通知

### Ping

我們提供了在備份完成、開始、成功、失敗時傳送通知的功能。

**搭配 [healthcheck.io](https://healthchecks.io/) 位址或者其他類似的 cron 監控位址是一個不錯的選擇，這也是我們推薦的。** 對於一些更複雜的通知場景，你可以使用 `_CURL_OPTIONS` 後綴的環境變數來設定 curl 選項。比如你可以新增請求標頭，改變請求方法等。

對於不同的通知場景，**備份工具提供了 `%{subject}` 和 `%{content}` 佔位符用於替換實際的標題和內容**，你可以在以下環境變數中隨意使用它們。請注意，標題和內容可能包含空格。對於包含 `_CURL_OPTIONS` 的四個環境變數，將直接替換佔位符，保留空格。對於其他 `PING_URL` 環境變數，空格將被替換為 `+`，以符合 URL 規則。

| 環境變數                               | 觸發狀態        | 測試標識         | 說明                                      |
|------------------------------------|-------------|--------------|-----------------------------------------|
| PING_URL                           | 完成（不論成功或失敗） | `completion` | 備份完成後傳送請求的位址                            |
| PING_URL_CURL_OPTIONS              |             |  | 與 `PING_URL` 搭配使用的 curl 選項              |
| PING_URL_WHEN_START                | 開始          | `start` | 備份開始時傳送請求的位址                            |
| PING_URL_WHEN_START_CURL_OPTIONS   |             |  | 與 `PING_URL_WHEN_START` 搭配使用的 curl 選項   |
| PING_URL_WHEN_SUCCESS              | 成功          | `success` | 備份成功後傳送請求的位址                            |
| PING_URL_WHEN_SUCCESS_CURL_OPTIONS |             |  | 與 `PING_URL_WHEN_SUCCESS` 搭配使用的 curl 選項 |
| PING_URL_WHEN_FAILURE              | 失敗          | `failure` | 備份失敗後傳送請求的位址                            |
| PING_URL_WHEN_FAILURE_CURL_OPTIONS |             |  | 與 `PING_URL_WHEN_FAILURE` 搭配使用的 curl 選項 |

<br>



### Ping 傳送測試

你可以使用下面的命令測試 Ping 傳送功能。

「test identifier」是[上一節](#ping)表格中的測試標識，你可以使用 `completion`、`start`、`success` 或 `failure`，它決定了使用哪一組環境變數。

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

從 v1.19.0 開始，本工具使用 [`s-nail`](https://www.sdaoden.eu/code-nail.html) 代替 [`heirloom-mailx`](https://www.systutorials.com/docs/linux/man/1-heirloom-mailx/) 傳送郵件。

請注意，`heirloom-mailx` 是 `s-nail` 的存根，它們大部分功能是相容的。因此你可能不需要為這個改變修改任何環境變數。

| 環境變數 | 預設值    | 說明                                     |
| --- |--------|----------------------------------------|
| MAIL_SMTP_ENABLE | `FALSE` | 啟用郵件傳送功能                               |
| MAIL_SMTP_VARIABLES |        | 郵件傳送參數                                 |
| MAIL_TO |        | 接收郵件的位址                                |
| MAIL_WHEN_SUCCESS | `TRUE` | 備份成功後傳送郵件                              |
| MAIL_WHEN_FAILURE | `TRUE` | 備份失敗後傳送郵件                              |
| MAIL_FORCE_THREAD | `FALSE` | 尤其適用於郵件用戶端在主題相同的情況下仍無法在對話檢視中將相關郵件分組的情況 |

對於 `MAIL_SMTP_VARIABLES`，你需要自行設定郵件傳送參數。**我們會根據使用場景設定郵件主題，所以你不應該使用 `-s` 標誌。**

```text
# 提供一個能正常使用的例子：

# For Zoho
-S smtp-use-starttls \
-S smtp=smtp://smtp.zoho.com:587 \
-S smtp-auth=login \
-S smtp-auth-user=<my-email-address> \
-S smtp-auth-password=<my-email-password> \
-S from=<my-email-address>
```

主控台有警告？查看 [issue #177](https://github.com/ttionya/vaultwarden-backup/issues/117#issuecomment-1691443179) 了解更多。

對於 `MAIL_FORCE_THREAD`，在郵件用戶端無法正確將郵件聚合到同一會話中時特別有用。它支援三種操作模式：

1. `FALSE`：預設電子郵件傳送行為
2. `TRUE`：自動產生符合 RFC 的 Message-ID 以強制會話關聯
3. `有效 Message-ID 字串`：使用指定的 Message-ID 與現有會話關聯。你可以在原始郵件內容的 Message-ID 欄位中找到它

啟用後，系統會自動新增所需的標頭（`Message-ID`、`References`、`In-Reply-To`），以便郵件用戶端適當地關聯會話。

<br>



### 郵件傳送測試

你可以使用下面的命令測試郵件傳送功能。我們會增加 `-v` 標誌以顯示詳細資訊，你無需在 `MAIL_SMTP_VARIABLES` 中重複設定。

```shell
docker run --rm -it -e MAIL_SMTP_VARIABLES='<your smtp variables>' ttionya/vaultwarden-backup:latest mail <mail send to>

# Or

docker run --rm -it -e MAIL_SMTP_VARIABLES='<your smtp variables>' -e MAIL_TO='<mail send to>' ttionya/vaultwarden-backup:latest mail
```

<br>



## 環境變數注意事項

### 使用 `.env` 檔案

如果你喜歡使用 env 檔案而不是環境變數，可以將包含環境變數的 env 檔案對應到容器中的 `/.env` 檔案。

```shell
docker run -d \
  --mount type=bind,source=/path/to/env,target=/.env \
  ttionya/vaultwarden-backup:latest
```

請不要直接使用 `--env-file` 標誌，務必透過掛載檔案的方式對應環境變數。`--env-file` 標誌會錯誤地處理引號，導致發生意外情況。更多資訊請參見 [docker/cli#3630](https://github.com/docker/cli/issues/3630)。

<br>



### Docker Secrets

作為透過環境變數傳遞敏感資訊的替代方法，可以在前面列出的環境變數後面追加 `_FILE`，使初始化指令碼從容器中存在的檔案載入這些變數的值。特別是這可以用來從儲存在 `/run/secrets/<secret_name>` 檔案中的 Docker Secrets 中載入密碼。

```shell
docker run -d \
  -e ZIP_PASSWORD_FILE=/run/secrets/zip-password \
  ttionya/vaultwarden-backup:latest
```

<br>



### 關於優先順序

我們按以下順序查找環境變數： 

1. 直接讀取環境變數的值
2. 讀取以 `_FILE` 結尾的環境變數指向的檔案的內容
3. 讀取 `.env` 檔案中以 `_FILE` 結尾的環境變數指向的檔案的內容
4. 讀取 `.env` 檔案中環境變數的值

範例：

```txt
# 對於 1
MY_ENV="example1"

# 對於 2
MY_ENV_FILE="/path/to/example2"

# 對於 3 (.env 檔案)
MY_ENV_FILE="/path/to/example3" 

# 對於 4 (.env 檔案)
MY_ENV="example4"
```

<br>



## 遷移

**用 Rust 撰寫的非官方 Bitwarden 伺服器，以前稱為 `bitwarden_rs`，已經改名為 `vaultwarden`。所以這個備份工具也由 `bitwardenrs-backup` 重新命名為 `vaultwarden-backup`。**

舊的映像仍然可以使用，只是被標記為 **DEPRECATED** 了，請盡快遷移到新的映像。

**遷移說明**

如果你使用自動備份，你只需要把映像名稱改為 `ttionya/vaultwarden-backup`。注意你的卷的名稱。

如果你使用 `docker-compose`，你需要將 `bitwardenrs/server` 更新為 `vaultwarden/server`，`ttionya/bitwardenrs-backup` 更新為 `ttionya/vaultwarden-backup`。

我們建議重新下載 [`docker-compose.yml`](./docker-compose.yml) 檔案，更新你的環境變數，並注意 `volumes` 部分，你可能需要修改它。

<br>



## 進階

- [以非 root 使用者執行](docs/run-as-non-root-user.zh-TW.md)
- [備份到多個遠端目標](docs/multiple-remote-destinations.zh-TW.md)
- [手動觸發備份](docs/manually-trigger-a-backup.zh-TW.md)
- [使用 PostgreSQL 資料庫](docs/using-the-postgresql-backend.zh-TW.md)
- [使用 MySQL(MariaDB) 資料庫](docs/using-the-mysql-or-mariadb-backend.zh-TW.md)

<br>



## 更新日誌

請查看 [CHANGELOG](CHANGELOG.md) 檔案。

<br>



## 授權條款

MIT
