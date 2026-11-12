# 使用 PostgreSQL 数据库

现在支持 PostgreSQL 数据库。

我们支持 PostgreSQL 18 及更早的版本。

如果 `postgresql*-client` 没有被及时更新，请创建一个 issue 来通知我们。

<br>



## 环境变量

#### DB_TYPE

设置为 `postgresql` 以切换到 PostgreSQL 数据库。

默认值：`sqlite`

#### PG_HOST

PostgreSQL 主机，**必填**。

#### PG_PORT

PostgreSQL 端口。

默认值：`5432`

#### PG_DBNAME

PostgreSQL 数据库名称。

默认值：`vaultwarden`

#### PG_USERNAME

PostgreSQL 用户名。

默认值：`vaultwarden`

#### PG_PASSWORD

PostgreSQL 密码，**必填**。

登录信息将保存在 `~/.pgpass` 文件中。

<br>



## 备份

指定上述环境变量以切换到 PostgreSQL 数据库。

<br>



## 还原

还原时同样指定上述环境变量以切换到 PostgreSQL 数据库。

1. 确保数据库可访问。

也许你会使用 `docker-compose up -d [服务名]` 命令单独启动数据库。

2. 验证你使用的 `PG_HOST` 可访问。

如果你的数据库在 docker-compose 中运行，你需要通过 `docker network ls` 找到对应的网络名称，并在还原命令中添加 `--network=[name]` 以指定网络名称。

3. 还原并重启容器。
