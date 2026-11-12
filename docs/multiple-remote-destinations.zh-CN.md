# 多个远程目标

有些用户希望将备份上传到多个远程目标。

你可以通过设置以下环境变量来实现。

<br>



## 使用方法

> **在使用新的环境变量运行前，别忘了添加新的 Rclone 远程。**
>
> 在 [这里](https://github.com/ttionya/vaultwarden-backup#configure-rclone-%EF%B8%8F-must-read-%EF%B8%8F) 查看如何配置 Rclone。

要设置额外的远程目标，请使用环境变量 `RCLONE_REMOTE_NAME_N` 和 `RCLONE_REMOTE_DIR_N`，其中：

- `N` 是序号，从 1 开始，每增加一个目标就连续递增
- `RCLONE_REMOTE_NAME_N` 和 `RCLONE_REMOTE_DIR_N` 不能为空

注意，如果序号不连续或值为空，脚本在解析远程目标的环境变量时会中断。

<br>



#### 示例

```yml
...
environment:
  # they have default values
  # RCLONE_REMOTE_NAME: BitwardenBackup
  # RCLONE_REMOTE_DIR: /BitwardenBackup/
  RCLONE_REMOTE_NAME_1: extraRemoteName1
  RCLONE_REMOTE_DIR_1: extraRemoteDir1
...
```

以上示例中，两个远程目标都可用：`BitwardenBackup:/BitwardenBackup/` 和 `extraRemoteName1:extraRemoteDir1`。

<br>

```yml
...
environment:
  RCLONE_REMOTE_NAME: remoteName
  RCLONE_REMOTE_DIR: remoteDir
  RCLONE_REMOTE_NAME_1: extraRemoteName1
  RCLONE_REMOTE_DIR_1: extraRemoteDir1
  RCLONE_REMOTE_NAME_2: extraRemoteName2
  RCLONE_REMOTE_DIR_2: extraRemoteDir2
  RCLONE_REMOTE_NAME_3: extraRemoteName3
  RCLONE_REMOTE_DIR_3: extraRemoteDir3
  RCLONE_REMOTE_NAME_4: extraRemoteName4
  RCLONE_REMOTE_DIR_4: extraRemoteDir4
...
```

以上示例中，全部 5 个远程目标都可用。

<br>

```yml
...
environment:
  RCLONE_REMOTE_NAME: remoteName
  RCLONE_REMOTE_DIR: remoteDir
  RCLONE_REMOTE_NAME_1: extraRemoteName1
  RCLONE_REMOTE_DIR_1: extraRemoteDir1
  RCLONE_REMOTE_NAME_2: extraRemoteName2
  # RCLONE_REMOTE_DIR_2: extraRemoteDir2
  RCLONE_REMOTE_NAME_3: extraRemoteName3
  RCLONE_REMOTE_DIR_3: extraRemoteDir3
  RCLONE_REMOTE_NAME_4: extraRemoteName4
  RCLONE_REMOTE_DIR_4: extraRemoteDir4
...
```

以上示例中，只有 `RCLONE_REMOTE_DIR_2` 之前的远程目标可用：`remoteName:remoteDir` 和 `extraRemoteName1:extraRemoteDir1`。

<br>



## 通知

- 成功：**所有**远程目标都已成功上传
- 失败：**任意**远程目标上传失败
