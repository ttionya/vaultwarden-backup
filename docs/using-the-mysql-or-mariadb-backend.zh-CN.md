# 使用 MySQL(MariaDB) 数据库

现在支持 MySQL(MariaDB) 数据库。

<br>



## 环境变量

#### DB_TYPE

设置为 `mysql` 以切换到 MySQL(MariaDB) 数据库。

默认值：`sqlite`

#### MYSQL_HOST

MySQL(MariaDB) 主机，**必填**。

#### MYSQL_PORT

MySQL(MariaDB) 端口。

默认值：`3306`

#### MYSQL_DATABASE

MySQL(MariaDB) 数据库名称。

默认值：`vaultwarden`

#### MYSQL_USERNAME

MySQL(MariaDB) 用户名。

默认值：`vaultwarden`

#### MYSQL_PASSWORD

MySQL(MariaDB) 密码，**必填**。

#### MYSQL_SSL

启用连接的 SSL。

没有设置默认值；它使用 `mariadb-dump` 提供的默认值，从版本 `10.11` 开始默认为 `TRUE`。

#### MYSQL_SSL_VERIFY_SERVER_CERT

验证服务器证书。

没有设置默认值；它使用 `mariadb-dump` 提供的默认值，从版本 `11.4` 开始默认为 `TRUE`。

如果你遇到任何与 TLS 相关的连接错误，可以尝试通过设置诸如 `0` 或 `FALSE` 之类来禁用它。

#### MYSQL_SSL_CA

TLS 连接的 CA 证书路径（可选）。

#### MYSQL_SSL_CERT

TLS 连接的客户端证书路径（可选）。

#### MYSQL_SSL_KEY

TLS 连接的客户端密钥路径（可选）。

<br>



## 备份

指定上述环境变量以切换到 MySQL(MariaDB) 数据库。

<br>



## 还原

还原时同样指定上述环境变量以切换到 MySQL(MariaDB) 数据库。

1. 确保数据库可访问。

也许你会使用 `docker-compose up -d [服务名]` 命令单独启动数据库。

2. 验证你使用的 `MYSQL_HOST` 可访问。

如果你的数据库在 docker-compose 中运行，你需要通过 `docker network ls` 找到对应的网络名称，并在还原命令中添加 `--network=[name]` 以指定网络名称。

3. 还原并重启容器。
