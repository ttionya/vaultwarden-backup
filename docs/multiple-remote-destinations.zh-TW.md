# 多個遠端目標

有些使用者希望將備份上傳到多個遠端目標。

你可以透過設定以下環境變數來實現。

<br>



## 使用方法

> **在使用新的環境變數執行前，別忘了加入新的 Rclone 遠端。**
>
> 在 [這裡](https://github.com/ttionya/vaultwarden-backup#configure-rclone-%EF%B8%8F-must-read-%EF%B8%8F) 查看如何設定 Rclone。

要設定額外的遠端目標，請使用環境變數 `RCLONE_REMOTE_NAME_N` 和 `RCLONE_REMOTE_DIR_N`，其中：

- `N` 是序號，從 1 開始，每增加一個目標就連續遞增
- `RCLONE_REMOTE_NAME_N` 和 `RCLONE_REMOTE_DIR_N` 不能為空

注意，如果序號不連續或值為空，指令碼在解析遠端目標的環境變數時會中斷。

<br>



#### 範例

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

以上範例中，兩個遠端目標都可用：`BitwardenBackup:/BitwardenBackup/` 和 `extraRemoteName1:extraRemoteDir1`。

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

以上範例中，全部 5 個遠端目標都可用。

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

以上範例中，只有 `RCLONE_REMOTE_DIR_2` 之前的遠端目標可用：`remoteName:remoteDir` 和 `extraRemoteName1:extraRemoteDir1`。

<br>



## 通知

- 成功：**所有**遠端目標都已成功上傳
- 失敗：**任意**遠端目標上傳失敗
