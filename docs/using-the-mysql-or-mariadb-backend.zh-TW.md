# 使用 MySQL(MariaDB) 資料庫

現在支援 MySQL(MariaDB) 資料庫。

<br>



## 環境變數

#### DB_TYPE

設定為 `mysql` 以切換到 MySQL(MariaDB) 資料庫。

預設值：`sqlite`

#### MYSQL_HOST

MySQL(MariaDB) 主機，**必填**。

#### MYSQL_PORT

MySQL(MariaDB) 連接埠。

預設值：`3306`

#### MYSQL_DATABASE

MySQL(MariaDB) 資料庫名稱。

預設值：`vaultwarden`

#### MYSQL_USERNAME

MySQL(MariaDB) 使用者名稱。

預設值：`vaultwarden`

#### MYSQL_PASSWORD

MySQL(MariaDB) 密碼，**必填**。

#### MYSQL_SSL

啟用連線的 SSL。

沒有設定預設值；它使用 `mariadb-dump` 提供的預設值，從版本 `10.11` 開始預設為 `TRUE`。

#### MYSQL_SSL_VERIFY_SERVER_CERT

驗證伺服器憑證。

沒有設定預設值；它使用 `mariadb-dump` 提供的預設值，從版本 `11.4` 開始預設為 `TRUE`。

如果你遇到任何與 TLS 相關的連線錯誤，可以嘗試透過設定諸如 `0` 或 `FALSE` 之類來停用它。

#### MYSQL_SSL_CA

TLS 連線的 CA 憑證路徑（選填）。

#### MYSQL_SSL_CERT

TLS 連線的用戶端憑證路徑（選填）。

#### MYSQL_SSL_KEY

TLS 連線的用戶端金鑰路徑（選填）。

<br>



## 備份

指定上述環境變數以切換到 MySQL(MariaDB) 資料庫。

<br>



## 還原

還原時同樣指定上述環境變數以切換到 MySQL(MariaDB) 資料庫。

1. 確保資料庫可存取。

也許你會使用 `docker-compose up -d [服務名]` 命令單獨啟動資料庫。

2. 驗證你使用的 `MYSQL_HOST` 可存取。

如果你的資料庫在 docker-compose 中執行，你需要透過 `docker network ls` 找到對應的網路名稱，並在還原命令中加入 `--network=[name]` 以指定網路名稱。

3. 還原並重新啟動容器。
