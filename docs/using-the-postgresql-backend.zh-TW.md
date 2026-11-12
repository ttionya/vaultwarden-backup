# 使用 PostgreSQL 資料庫

現在支援 PostgreSQL 資料庫。

我們支援 PostgreSQL 18 及更早的版本。

如果 `postgresql*-client` 沒有被及時更新，請建立一個 issue 來通知我們。

<br>



## 環境變數

#### DB_TYPE

設定為 `postgresql` 以切換到 PostgreSQL 資料庫。

預設值：`sqlite`

#### PG_HOST

PostgreSQL 主機，**必填**。

#### PG_PORT

PostgreSQL 連接埠。

預設值：`5432`

#### PG_DBNAME

PostgreSQL 資料庫名稱。

預設值：`vaultwarden`

#### PG_USERNAME

PostgreSQL 使用者名稱。

預設值：`vaultwarden`

#### PG_PASSWORD

PostgreSQL 密碼，**必填**。

登入資訊將儲存在 `~/.pgpass` 檔案中。

<br>



## 備份

指定上述環境變數以切換到 PostgreSQL 資料庫。

<br>



## 還原

還原時同樣指定上述環境變數以切換到 PostgreSQL 資料庫。

1. 確保資料庫可存取。

也許你會使用 `docker-compose up -d [服務名]` 命令單獨啟動資料庫。

2. 驗證你使用的 `PG_HOST` 可存取。

如果你的資料庫在 docker-compose 中執行，你需要透過 `docker network ls` 找到對應的網路名稱，並在還原命令中加入 `--network=[name]` 以指定網路名稱。

3. 還原並重新啟動容器。
